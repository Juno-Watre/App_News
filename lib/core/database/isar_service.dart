import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_news_brief/features/article/data/models/article.dart';

class IsarService {
  static late Isar _isar;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ArticleSchema],
      directory: dir.path,
      inspector: true, // 在调试模式下启用Isar Inspector
    );
    _initialized = true;
  }

  static Isar get instance {
    if (!_initialized) {
      throw Exception('IsarService must be initialized before use');
    }
    return _isar;
  }

  // 文章操作
  static Future<void> saveArticles(List<Article> articles) async {
    await _isar.writeTxn(() async {
      await _isar.articles.putAll(articles);
    });
  }

  static Future<void> saveArticle(Article article) async {
    await _isar.writeTxn(() async {
      await _isar.articles.put(article);
    });
  }

  static Future<List<Article>> getAllArticles() async {
    return await _isar.articles.where().sortByPublishedAtDesc().findAll();
  }

  static Future<List<Article>> getUnreadArticles() async {
    return await _isar.articles.filter().isReadEqualTo(false).sortByPublishedAtDesc().findAll();
  }

  static Future<List<Article>> getStarredArticles() async {
    return await _isar.articles.filter().isStarEqualTo(true).sortByPublishedAtDesc().findAll();
  }

  static Future<Article?> getArticleByUrl(String url) async {
    return await _isar.articles.filter().urlEqualTo(url).findFirst();
  }

  static Future<void> updateArticle(Article article) async {
    await _isar.writeTxn(() async {
      await _isar.articles.put(article);
    });
  }

  static Future<void> markAsRead(String url) async {
    await _isar.writeTxn(() async {
      final article = await _isar.articles.filter().urlEqualTo(url).findFirst();
      if (article != null) {
        await _isar.articles.put(article.copyWith(isRead: true));
      }
    });
  }

  static Future<void> toggleStar(String url) async {
    await _isar.writeTxn(() async {
      final article = await _isar.articles.filter().urlEqualTo(url).findFirst();
      if (article != null) {
        await _isar.articles.put(article.copyWith(isStar: !article.isStar));
      }
    });
  }

  static Future<void> updateSummary(String url, String summary) async {
    await _isar.writeTxn(() async {
      final article = await _isar.articles.filter().urlEqualTo(url).findFirst();
      if (article != null) {
        await _isar.articles.put(article.copyWith(summary: summary));
      }
    });
  }

  static Future<void> updateNoteExternalId(String url, String noteExternalId) async {
    await _isar.writeTxn(() async {
      final article = await _isar.articles.filter().urlEqualTo(url).findFirst();
      if (article != null) {
        await _isar.articles.put(article.copyWith(noteExternalId: noteExternalId));
      }
    });
  }

  static Future<void> deleteArticle(String url) async {
    await _isar.writeTxn(() async {
      final article = await _isar.articles.filter().urlEqualTo(url).findFirst();
      if (article != null) {
        await _isar.articles.delete(article.id);
      }
    });
  }

  static Future<void> deleteAllArticles() async {
    await _isar.writeTxn(() async {
      await _isar.articles.clear();
    });
  }

  // 全文搜索
  static Future<List<Article>> searchArticles(String query) async {
    if (query.isEmpty) return [];
    
    return await _isar.articles
        .filter()
        .titleContains(query, caseSensitive: false)
        .or()
        .contentContains(query, caseSensitive: false)
        .or()
        .summaryContains(query, caseSensitive: false)
        .sortByPublishedAtDesc()
        .findAll();
  }

  static Future<void> close() async {
    await _isar.close();
    _initialized = false;
  }
}