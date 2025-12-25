import 'package:dio/dio.dart';
import 'package:personal_news_brief/features/article/data/models/article.dart';

abstract class NoteService {
  Future<String> createNote(Article article);
  Future<String> updateNote(String noteId, Article article);
  Future<void> deleteNote(String noteId);
  Future<String?> findNoteByUrl(String url);
}

class JoplinNoteService implements NoteService {
  final Dio _dio;
  final String token;
  final String baseUrl;

  JoplinNoteService({
    required this.token,
    this.baseUrl = 'http://localhost:41184',
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  @override
  Future<String> createNote(Article article) async {
    try {
      // 创建笔记
      final noteData = {
        'title': article.title,
        'body': _formatNoteBody(article),
        'source_url': article.url,
        'is_todo': 0,
        'latitude': null,
        'longitude': null,
        'altitude': null,
        'author': '',
        'source': '',
        'source_application': 'PersonalNewsBrief',
        'application_data': '',
        'order': 0,
        'user_created_time': article.publishedAt.millisecondsSinceEpoch,
        'user_updated_time': DateTime.now().millisecondsSinceEpoch,
        'encryption_cipher_text': null,
        'encryption_applied': 0,
        'markup_language': 1, // Markdown
        'is_shared': 0,
        'share_id': null,
        'conflict_original_id': null,
        'master_key_id': null,
        'type_': 1, // Note
      };

      final response = await _dio.post('/notes', data: noteData);
      
      if (response.statusCode == 200) {
        final noteId = response.data['id'] as String;
        return noteId;
      } else {
        throw Exception('创建笔记失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('网络错误: ${e.message}');
    } catch (e) {
      throw Exception('创建笔记时出错: $e');
    }
  }

  @override
  Future<String> updateNote(String noteId, Article article) async {
    try {
      // 更新笔记
      final noteData = {
        'title': article.title,
        'body': _formatNoteBody(article),
        'source_url': article.url,
        'user_updated_time': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await _dio.put('/notes/$noteId', data: noteData);
      
      if (response.statusCode == 200) {
        return noteId;
      } else {
        throw Exception('更新笔记失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('网络错误: ${e.message}');
    } catch (e) {
      throw Exception('更新笔记时出错: $e');
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      final response = await _dio.delete('/notes/$noteId');
      
      if (response.statusCode != 200) {
        throw Exception('删除笔记失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('网络错误: ${e.message}');
    } catch (e) {
      throw Exception('删除笔记时出错: $e');
    }
  }

  @override
  Future<String?> findNoteByUrl(String url) async {
    try {
      // 搜索笔记
      final response = await _dio.get('/notes', queryParameters: {
        'query': 'source_url:"$url"',
        'fields': 'id,title,source_url',
        'limit': 10,
      });
      
      if (response.statusCode == 200) {
        final notes = response.data['items'] as List;
        if (notes.isNotEmpty) {
          return notes.first['id'] as String;
        }
      }
      
      return null;
    } on DioException catch (e) {
      throw Exception('网络错误: ${e.message}');
    } catch (e) {
      throw Exception('查找笔记时出错: $e');
    }
  }

  String _formatNoteBody(Article article) {
    final buffer = StringBuffer();
    
    // 添加标题
    buffer.writeln('# ${article.title}');
    buffer.writeln();
    
    // 添加元信息
    buffer.writeln('**来源:** ${article.source}');
    buffer.writeln('**发布时间:** ${_formatDate(article.publishedAt)}');
    buffer.writeln('**链接:** ${article.url}');
    buffer.writeln();
    
    // 添加分隔线
    buffer.writeln('---');
    buffer.writeln();
    
    // 添加内容
    buffer.writeln(article.content);
    
    // 如果有AI摘要，添加摘要
    if (article.summary != null && article.summary!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## AI摘要');
      buffer.writeln();
      buffer.writeln(article.summary);
    }
    
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class ObsidianNoteService implements NoteService {
  final String vaultPath;
  final String notesFolder;

  ObsidianNoteService({
    required this.vaultPath,
    this.notesFolder = 'PersonalNewsBrief',
  });

  @override
  Future<String> createNote(Article article) async {
    // 对于Obsidian，我们需要创建本地文件
    // 这里简化实现，实际应用中可能需要使用文件系统操作
    final fileName = _sanitizeFileName('${article.title}.md');
    final filePath = '$vaultPath/$notesFolder/$fileName';
    
    // 创建笔记内容
    final noteContent = _formatNoteBody(article);
    
    // 在实际应用中，这里应该使用文件系统API创建文件
    // 返回文件路径作为ID
    return filePath;
  }

  @override
  Future<String> updateNote(String noteId, Article article) async {
    // 更新笔记内容
    final noteContent = _formatNoteBody(article);
    
    // 在实际应用中，这里应该使用文件系统API更新文件
    return noteId;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    // 在实际应用中，这里应该使用文件系统API删除文件
  }

  @override
  Future<String?> findNoteByUrl(String url) async {
    // 在实际应用中，这里应该搜索文件内容
    return null;
  }

  String _sanitizeFileName(String fileName) {
    // 简单的文件名清理，移除或替换非法字符
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formatNoteBody(Article article) {
    final buffer = StringBuffer();
    
    // 添加标题
    buffer.writeln('# ${article.title}');
    buffer.writeln();
    
    // 添加元信息（YAML front matter for Obsidian）
    buffer.writeln('---');
    buffer.writeln('source: "${article.source}"');
    buffer.writeln('published: "${article.publishedAt.toIso8601String()}"');
    buffer.writeln('url: "${article.url}"');
    buffer.writeln('tags: [news, article]');
    buffer.writeln('---');
    buffer.writeln();
    
    // 添加内容
    buffer.writeln(article.content);
    
    // 如果有AI摘要，添加摘要
    if (article.summary != null && article.summary!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## AI摘要');
      buffer.writeln();
      buffer.writeln(article.summary);
    }
    
    return buffer.toString();
  }
}

// 笔记服务工厂
class NoteServiceFactory {
  static NoteService createService(String type, Map<String, String> config) {
    switch (type.toLowerCase()) {
      case 'joplin':
        return JoplinNoteService(
          token: config['token'] ?? '',
          baseUrl: config['baseUrl'] ?? 'http://localhost:41184',
        );
      case 'obsidian':
        return ObsidianNoteService(
          vaultPath: config['vaultPath'] ?? '',
          notesFolder: config['notesFolder'] ?? 'PersonalNewsBrief',
        );
      default:
        throw UnsupportedError('不支持的笔记服务类型: $type');
    }
  }
}