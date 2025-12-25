import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import 'package:isar/isar.dart';
import 'package:personal_news_brief/features/article/data/models/article.dart';

class RssParserService {
  final Dio _dio;
  
  RssParserService({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<Article>> parseFeed(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'PersonalNewsBrief/1.0 (RSS Reader)',
            'Accept': 'application/rss+xml, application/xml, text/xml',
          },
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch RSS feed');
      }

      final document = XmlDocument.parse(response.data);
      final rootElement = document.rootElement;

      // 检测RSS格式
      if (rootElement.localName == 'rss') {
        return _parseRss20(document, url);
      } else if (rootElement.localName == 'feed') {
        return _parseAtom(document, url);
      } else {
        throw FormatException('Unsupported feed format: ${rootElement.localName}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on XmlException catch (e) {
      throw Exception('XML parsing error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  List<Article> _parseRss20(XmlDocument document, String feedUrl) {
    final articles = <Article>[];
    final channel = document.findAllElements('channel').first;
    final items = channel.findAllElements('item');
    final sourceName = _extractSourceName(channel, feedUrl);

    for (final item in items) {
      try {
        final article = _parseRssItem(item, sourceName);
        if (article != null) {
          articles.add(article);
        }
      } catch (e) {
        // 跳过解析失败的单个条目，继续处理其他条目
        continue;
      }
    }

    return articles;
  }

  List<Article> _parseAtom(XmlDocument document, String feedUrl) {
    final articles = <Article>[];
    final feed = document.rootElement;
    final entries = feed.findAllElements('entry');
    final sourceName = _extractSourceName(feed, feedUrl);

    for (final entry in entries) {
      try {
        final article = _parseAtomEntry(entry, sourceName);
        if (article != null) {
          articles.add(article);
        }
      } catch (e) {
        // 跳过解析失败的单个条目，继续处理其他条目
        continue;
      }
    }

    return articles;
  }

  Article? _parseRssItem(XmlElement item, String source) {
    final title = _getElementText(item, 'title');
    final link = _getElementText(item, 'link');
    final description = _getElementText(item, 'description');
    final contentEncoded = _getElementText(item, 'content:encoded');
    final pubDateStr = _getElementText(item, 'pubDate') ?? _getElementText(item, 'dc:date');

    if (title.isEmpty || link.isEmpty) {
      return null; // 标题和链接是必需的
    }

    // 优先使用content:encoded，其次使用description
    final content = contentEncoded.isNotEmpty ? contentEncoded : description;

    DateTime publishedAt;
    try {
      publishedAt = pubDateStr.isNotEmpty ? _parseDateTime(pubDateStr) : DateTime.now();
    } catch (e) {
      publishedAt = DateTime.now();
    }

    return Article(
      id: Isar.autoIncrement,
      title: title.trim(),
      content: content.trim(),
      url: link.trim(),
      source: source,
      publishedAt: publishedAt,
    );
  }

  Article? _parseAtomEntry(XmlElement entry, String source) {
    final title = _getElementText(entry, 'title');
    final linkElement = entry.findElements('link').firstWhere(
      (el) => el.getAttribute('rel') == 'alternate' || el.getAttribute('rel') == null,
      orElse: () => entry.findElements('link').first,
    );
    final link = linkElement.getAttribute('href') ?? '';
    final content = _getElementText(entry, 'content') ?? _getElementText(entry, 'summary') ?? '';
    final publishedStr = _getElementText(entry, 'published') ?? _getElementText(entry, 'updated');

    if (title.isEmpty || link.isEmpty) {
      return null; // 标题和链接是必需的
    }

    DateTime publishedAt;
    try {
      publishedAt = publishedStr.isNotEmpty ? _parseDateTime(publishedStr) : DateTime.now();
    } catch (e) {
      publishedAt = DateTime.now();
    }

    return Article(
      id: Isar.autoIncrement,
      title: title.trim(),
      content: content.trim(),
      url: link.trim(),
      source: source,
      publishedAt: publishedAt,
    );
  }

  String _extractSourceName(XmlElement element, String feedUrl) {
    // 尝试从RSS/Atom元素中提取源名称
    final title = _getElementText(element, 'title');
    if (title.isNotEmpty) {
      return title;
    }

    // 如果没有标题，尝试从URL中提取域名
    try {
      final uri = Uri.parse(feedUrl);
      return uri.host;
    } catch (e) {
      return 'Unknown Source';
    }
  }

  String _getElementText(XmlElement parent, String tagName) {
    final element = parent.findElements(tagName).firstOrNull;
    return element?.innerText ?? '';
  }

  DateTime _parseDateTime(String dateTimeStr) {
    // 尝试多种常见的日期时间格式
    final formats = [
      'EEE, dd MMM yyyy HH:mm:ss Z', // RFC 822
      'EEE, dd MMM yyyy HH:mm:ss zzz', // RFC 822 with timezone name
      'yyyy-MM-ddTHH:mm:ssZ', // ISO 8601
      'yyyy-MM-ddTHH:mm:sszzz', // ISO 8601 with timezone
      'yyyy-MM-ddTHH:mm:ss', // ISO 8601 without timezone
      'yyyy-MM-dd HH:mm:ss', // Custom format
    ];

    for (final format in formats) {
      try {
        return DateTime.parse(dateTimeStr);
      } catch (e) {
        continue;
      }
    }

    // 如果所有格式都失败，尝试使用HTTP日期解析
    try {
      return HttpDate.parse(dateTimeStr);
    } catch (e) {
      // 最后尝试直接解析
      return DateTime.parse(dateTimeStr);
    }
  }
}