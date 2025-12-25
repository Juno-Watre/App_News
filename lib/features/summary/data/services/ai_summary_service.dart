import 'package:dio/dio.dart';
import 'package:personal_news_brief/features/article/data/models/article.dart';

abstract class AiSummaryService {
  Future<String> generateSummary(String content);
}

/// OpenAI摘要服务
/// 支持配置API密钥和基础URL
/// 包含错误处理和本地降级方案
class OpenAiService {
  final Dio _dio;
  final String apiKey;
  final String baseUrl;

  OpenAiService({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// 生成文章摘要
  ///
  /// [text] 要摘要的文本内容
  /// [prompt] 自定义提示词，如果为null则使用默认提示词
  ///
  /// 返回摘要文本，如果API调用失败则返回本地生成的简单摘要
  Future<String> generateSummary(String text, {String? prompt}) async {
    try {
      // 使用自定义提示词或默认提示词
      final systemPrompt = prompt ?? '你是一个专业的内容摘要助手，请为用户提供简洁、准确的文章摘要。摘要应该包含文章的主要观点和关键信息，长度控制在100-200字之间。';
      
      // 限制输入文本长度，避免超出API限制
      final truncatedText = _truncateText(text, maxLength: 3000);
      
      final response = await _dio.post('/chat/completions', data: {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt
          },
          {
            'role': 'user',
            'content': '请为以下内容生成摘要：\n\n$truncatedText'
          }
        ],
        'max_tokens': 300,  // 限制输出长度
        'temperature': 0.3,  // 降低随机性，提高摘要一致性
        'top_p': 0.9,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      });

      if (response.statusCode == 200) {
        final summary = response.data['choices'][0]['message']['content'] as String;
        return summary.trim();
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // 网络错误，降级为本地摘要
      debugPrint('OpenAI API网络错误: ${e.message}，使用本地摘要');
      return _generateLocalSummary(text);
    } catch (e) {
      // 其他错误，降级为本地摘要
      debugPrint('OpenAI API错误: $e，使用本地摘要');
      return _generateLocalSummary(text);
    }
  }

  /// 生成本地简单摘要
  /// 作为API失败时的降级方案
  String _generateLocalSummary(String text) {
    // 清理HTML标签
    final cleanText = _removeHtmlTags(text);
    
    // 取前200个字符作为简单摘要
    if (cleanText.length <= 200) {
      return cleanText;
    }
    
    // 尝试在句子边界截断
    final truncated = cleanText.substring(0, 200);
    final lastSentenceEnd = truncated.lastIndexOf(RegExp(r'[.!?。！？]'));
    
    if (lastSentenceEnd > 100) {
      return truncated.substring(0, lastSentenceEnd + 1);
    }
    
    return '$truncated...';
  }

  /// 截断文本到指定长度
  String _truncateText(String text, {int maxLength = 3000}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// 移除HTML标签
  String _removeHtmlTags(String htmlText) {
    // 简单的HTML标签移除，实际项目中可能需要更复杂的处理
    final cleanText = htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '')  // 移除HTML标签
        .replaceAll(RegExp(r'\s+'), ' ')     // 合并多个空白字符
        .trim();
    
    return cleanText;
  }
}

class OpenAiSummaryService implements AiSummaryService {
  final OpenAiService _openAiService;

  OpenAiSummaryService({
    required String apiKey,
    String baseUrl = 'https://api.openai.com/v1',
  }) : _openAiService = OpenAiService(
          apiKey: apiKey,
          baseUrl: baseUrl,
        );

  @override
  Future<String> generateSummary(String content) async {
    return await _openAiService.generateSummary(content);
  }
}

class ClaudeSummaryService implements AiSummaryService {
  final Dio _dio;
  final String apiKey;
  final String baseUrl;

  ClaudeSummaryService({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com/v1',
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'x-api-key': apiKey,
            'Content-Type': 'application/json',
            'anthropic-version': '2023-06-01',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ));

  @override
  Future<String> generateSummary(String content) async {
    try {
      final response = await _dio.post('/messages', data: {
        'model': 'claude-3-sonnet-20240229',
        'max_tokens': 300,
        'messages': [
          {
            'role': 'user',
            'content': '你是一个专业的内容摘要助手，请为用户提供简洁、准确的文章摘要。摘要应该包含文章的主要观点和关键信息，长度控制在100-200字之间。请为以下内容生成摘要：\n\n$content'
          }
        ],
      });

      if (response.statusCode == 200) {
        final summary = response.data['content'][0]['text'] as String;
        return summary.trim();
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('网络错误: ${e.message}');
    } catch (e) {
      throw Exception('生成摘要时出错: $e');
    }
  }
}

class LocalSummaryService implements AiSummaryService {
  // 本地摘要服务，可以使用简单的文本提取算法
  @override
  Future<String> generateSummary(String content) async {
    // 简单的本地摘要算法
    final sentences = _extractSentences(content);
    if (sentences.isEmpty) return '';
    
    // 选择前几个句子作为摘要
    final summaryLength = sentences.length > 3 ? 3 : sentences.length;
    final summary = sentences.take(summaryLength).join(' ');
    
    return summary.length > 200 ? '${summary.substring(0, 200)}...' : summary;
  }

  List<String> _extractSentences(String text) {
    // 简单的句子分割算法
    final sentences = <String>[];
    final regex = RegExp(r'(?<=[.!?])\s+');
    final parts = text.split(regex);
    
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty && trimmed.length > 10) {
        sentences.add(trimmed);
      }
    }
    
    return sentences;
  }
}

// 摘要服务工厂
class SummaryServiceFactory {
  static AiSummaryService createService(String type, Map<String, String> config) {
    switch (type.toLowerCase()) {
      case 'openai':
        return OpenAiSummaryService(apiKey: config['apiKey'] ?? '');
      case 'claude':
        return ClaudeSummaryService(apiKey: config['apiKey'] ?? '');
      case 'local':
      default:
        return const LocalSummaryService();
    }
  }
}