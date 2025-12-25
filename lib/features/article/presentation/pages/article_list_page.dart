import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_news_brief/features/article/data/models/article.dart';
import 'package:personal_news_brief/features/article/presentation/providers/article_provider.dart';
import 'package:personal_news_brief/features/home/presentation/pages/home_page.dart';

class ArticleListPage extends ConsumerStatefulWidget {
  final bool isStarredOnly;
  final bool isUnreadOnly;

  const ArticleListPage({
    super.key,
    this.isStarredOnly = false,
    this.isUnreadOnly = false,
  });

  @override
  ConsumerState<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends ConsumerState<ArticleListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    
    // 添加滚动监听器，实现上拉加载
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreArticles();
      }
    });
    
    // 根据页面类型加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArticles();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadArticles() {
    if (widget.isStarredOnly) {
      ref.read(articleListProvider.notifier).loadStarredArticles();
    } else if (widget.isUnreadOnly) {
      ref.read(articleListProvider.notifier).loadUnreadArticles();
    } else {
      ref.read(articleListProvider.notifier).loadArticles();
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // 模拟加载更多数据
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshArticles() async {
    await ref.read(articleListProvider.notifier).refreshArticles();
  }

  @override
  Widget build(BuildContext context) {
    final articleListState = ref.watch(articleListProvider);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 下拉刷新
        SliverRefreshControl(
          onRefresh: _refreshArticles,
        ),
        
        // 文章列表或空状态
        if (articleListState.isLoading && articleListState.articles.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (articleListState.error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('加载出错: ${articleListState.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadArticles,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          )
        else if (articleListState.articles.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isStarredOnly ? Icons.star_border : Icons.article_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isStarredOnly
                        ? '还没有收藏的文章'
                        : widget.isUnreadOnly
                            ? '没有未读的文章'
                            : '还没有文章',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (!widget.isStarredOnly && !widget.isUnreadOnly) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '点击右下角的 + 添加RSS订阅源',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= articleListState.articles.length) {
                  return null;
                }
                
                final article = articleListState.articles[index];
                return ArticleTile(article: article);
              },
              childCount: articleListState.articles.length,
            ),
        
        // 上拉加载指示器
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

/// 自定义下拉刷新控件
class SliverRefreshControl extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const SliverRefreshControl({
    super.key,
    required this.onRefresh,
  });

  @override
  State<SliverRefreshControl> createState() => _SliverRefreshControlState();
}

class _SliverRefreshControlState extends State<SliverRefreshControl> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  Future<void> refresh() async {
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: widget.onRefresh,
      child: const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}