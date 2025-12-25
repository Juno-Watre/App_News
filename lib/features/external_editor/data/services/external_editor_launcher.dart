import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:personal_news_brief/features/article/data/models/article.dart';

/// 外部编辑器启动器
/// 支持Joplin、Markor等外部编辑器的深度链接调用
/// 如果深度链接失败，则降级为系统分享面板
class ExternalEditorLauncher {
  /// 启动外部编辑器
  /// 
  /// [article] 要编辑的文章对象
  /// 
  /// 逻辑：
  /// 1. 尝试使用Joplin深度链接 (joplin://)
  /// 2. 如果失败，尝试使用Markor深度链接 (markor://)
  /// 3. 如果都失败，降级为系统分享面板
  static Future<void> launchEditor(Article article) async {
    debugPrint('尝试启动外部编辑器处理文章: ${article.title}');
    
    // 构建文章内容
    final title = article.title;
    final body = _formatArticleForEditor(article);
    
    // 尝试启动Joplin
    if (await _tryLaunchJoplin(title, body)) {
      debugPrint('成功启动Joplin');
      return;
    }
    
    // 尝试启动Markor
    if (await _tryLaunchMarkor(title, body)) {
      debugPrint('成功启动Markor');
      return;
    }
    
    // 降级为系统分享
    debugPrint('外部编辑器启动失败，降级为系统分享');
    await _fallbackToShare(title, body);
  }
  
  /// 尝试启动Joplin
  /// 
  /// 使用深度链接格式：joplin://x-callback-url/newNote?title=xxx&body=xxx
  static Future<bool> _tryLaunchJoplin(String title, String body) async {
    try {
      // 对参数进行URL编码
      final encodedTitle = Uri.encodeComponent(title);
      final encodedBody = Uri.encodeComponent(body);
      
      // 构建Joplin深度链接
      final joplinUrl = 'joplin://x-callback-url/newNote?title=$encodedTitle&body=$encodedBody';
      
      debugPrint('尝试启动Joplin URL: $joplinUrl');
      
      // 检查是否可以启动URL
      final uri = Uri.parse(joplinUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      debugPrint('无法启动Joplin，可能应用未安装');
      return false;
    } catch (e) {
      debugPrint('启动Joplin时出错: $e');
      return false;
    }
  }
  
  /// 尝试启动Markor
  /// 
  /// 使用深度链接格式：markor://?path=xxx&content=xxx
  static Future<bool> _tryLaunchMarkor(String title, String body) async {
    try {
      // 对参数进行URL编码
      final encodedTitle = Uri.encodeComponent(title);
      final encodedContent = Uri.encodeComponent(body);
      
      // 构建Markor深度链接
      final markorUrl = 'markor://?path=$encodedTitle.md&content=$encodedContent';
      
      debugPrint('尝试启动Markor URL: $markorUrl');
      
      // 检查是否可以启动URL
      final uri = Uri.parse(markorUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      debugPrint('无法启动Markor，可能应用未安装');
      return false;
    } catch (e) {
      debugPrint('启动Markor时出错: $e');
      return false;
    }
  }
  
  /// 降级为系统分享面板
  static Future<void> _fallbackToShare(String title, String body) async {
    try {
      // 构建分享内容
      final shareContent = '$title\n\n$body';
      
      // 使用share_plus插件调用系统分享
      await Share.share(
        shareContent,
        subject: title,
      );
      
      debugPrint('系统分享面板已启动');
    } catch (e) {
      debugPrint('系统分享失败: $e');
      // 如果连分享都失败，至少将内容复制到剪贴板
      // 这里可以添加剪贴板操作作为最后的降级方案
    }
  }
  
  /// 格式化文章内容以适应外部编辑器
  /// 
  /// 将文章内容格式化为Markdown格式，包含元数据
  static String _formatArticleForEditor(Article article) {
    final buffer = StringBuffer();
    
    // 添加标题
    buffer.writeln('# ${article.title}');
    buffer.writeln();
    
    // 添加元数据（YAML front matter格式）
    buffer.writeln('---');
    buffer.writeln('title: "${article.title}"');
    buffer.writeln('source: "${article.source}"');
    buffer.writeln('url: "${article.url}"');
    buffer.writeln('published: "${article.publishedAt.toIso8601String()}"');
    buffer.writeln('tags: [news, article]');
    buffer.writeln('---');
    buffer.writeln();
    
    // 添加文章内容
    buffer.writeln(article.content);
    
    // 如果有AI摘要，添加摘要部分
    if (article.summary != null && article.summary!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## AI摘要');
      buffer.writeln();
      buffer.writeln(article.summary);
    }
    
    // 添加原始链接
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('**原始链接**: [${article.title}](${article.url})');
    
    return buffer.toString();
  }
  
  /// 检查Joplin是否已安装
  static Future<bool> isJoplinInstalled() async {
    try {
      final uri = Uri.parse('joplin://');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
  
  /// 检查Markor是否已安装
  static Future<bool> isMarkorInstalled() async {
    try {
      final uri = Uri.parse('markor://');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
  
  /// 获取已安装的外部编辑器列表
  static Future<List<String>> getInstalledEditors() async {
    final installed = <String>[];
    
    if (await isJoplinInstalled()) {
      installed.add('Joplin');
    }
    
    if (await isMarkorInstalled()) {
      installed.add('Markor');
    }
    
    return installed;
  }
}