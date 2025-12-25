import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_news_brief/core/database/isar_service.dart';
import 'package:personal_news_brief/features/article/data/models/article.dart';
import 'package:personal_news_brief/features/rss/data/services/rss_parser_service.dart';

// RSS解析服务提供者
final rssParserServiceProvider = Provider<RssParserService>((ref) {
  return RssParserService();
});

// 文章列表状态
class ArticleListState {
  final List<Article> articles;
  final bool isLoading;
  final String? error;

  ArticleListState({
    required this.articles,
    this.isLoading = false,
    this.error,
  });

  ArticleListState copyWith({
    List<Article>? articles,
    bool? isLoading,
    String? error,
  }) {
    return ArticleListState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 文章列表提供者
class ArticleListNotifier extends StateNotifier<ArticleListState> {
  final RssParserService _rssParserService;

  ArticleListNotifier(this._rssParserService)
      : super(ArticleListState(articles: []));

  Future<void> loadArticles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final articles = await IsarService.getAllArticles();
      state = state.copyWith(articles: articles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUnreadArticles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final articles = await IsarService.getUnreadArticles();
      state = state.copyWith(articles: articles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadStarredArticles() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final articles = await IsarService.getStarredArticles();
      state = state.copyWith(articles: articles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchAndSaveArticles(String rssUrl) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newArticles = await _rssParserService.parseFeed(rssUrl);
      
      // 保存文章到数据库
      for (final article in newArticles) {
        // 检查文章是否已存在
        final existingArticle = await IsarService.getArticleByUrl(article.url);
        if (existingArticle == null) {
          await IsarService.saveArticle(article);
        }
      }
      
      // 重新加载文章列表
      await loadArticles();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> searchArticles(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final articles = await IsarService.searchArticles(query);
      state = state.copyWith(articles: articles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String url) async {
    try {
      await IsarService.markAsRead(url);
      
      // 更新本地状态
      final updatedArticles = state.articles.map((article) {
        if (article.url == url) {
          return article.copyWith(isRead: true);
        }
        return article;
      }).toList();
      
      state = state.copyWith(articles: updatedArticles);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleStar(String url) async {
    try {
      await IsarService.toggleStar(url);
      
      // 更新本地状态
      final updatedArticles = state.articles.map((article) {
        if (article.url == url) {
          return article.copyWith(isStar: !article.isStar);
        }
        return article;
      }).toList();
      
      state = state.copyWith(articles: updatedArticles);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshArticles() async {
    await loadArticles();
  }
}

final articleListProvider = StateNotifierProvider<ArticleListNotifier, ArticleListState>((ref) {
  final rssParserService = ref.watch(rssParserServiceProvider);
  return ArticleListNotifier(rssParserService);
});

// 单个文章提供者
final articleProvider = FutureProvider.family<Article?, String>((ref, url) async {
  return await IsarService.getArticleByUrl(url);
});

// 当前选中的文章提供者
final selectedArticleProvider = StateProvider<Article?>((ref) {
  return null;
});

// RSS订阅源提供者
class RssSource {
  final String id;
  final String name;
  final String url;
  final String? category;

  RssSource({
    required this.id,
    required this.name,
    required this.url,
    this.category,
  });
}

class RssSourcesState {
  final List<RssSource> sources;
  final bool isLoading;
  final String? error;

  RssSourcesState({
    required this.sources,
    this.isLoading = false,
    this.error,
  });

  RssSourcesState copyWith({
    List<RssSource>? sources,
    bool? isLoading,
    String? error,
  }) {
    return RssSourcesState(
      sources: sources ?? this.sources,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RssSourcesNotifier extends StateNotifier<RssSourcesState> {
  RssSourcesNotifier() : super(RssSourcesState(sources: []));

  void addSource(RssSource source) {
    final updatedSources = [...state.sources, source];
    state = state.copyWith(sources: updatedSources);
  }

  void removeSource(String id) {
    final updatedSources = state.sources.where((source) => source.id != id).toList();
    state = state.copyWith(sources: updatedSources);
  }

  void updateSource(RssSource updatedSource) {
    final updatedSources = state.sources.map((source) {
      return source.id == updatedSource.id ? updatedSource : source;
    }).toList();
    state = state.copyWith(sources: updatedSources);
  }
}

final rssSourcesProvider = StateNotifierProvider<RssSourcesNotifier, RssSourcesState>((ref) {
  return RssSourcesNotifier();
});