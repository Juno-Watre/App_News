import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_news_brief/features/article/presentation/providers/article_provider.dart';
import 'package:personal_news_brief/features/article/presentation/pages/article_list_page.dart';
import 'package:personal_news_brief/features/rss/presentation/pages/rss_sources_page.dart';
import 'package:personal_news_brief/core/platform/platform_service.dart';
import 'package:personal_news_brief/features/external_editor/data/services/external_editor_launcher.dart';
import 'package:flutter_html/flutter_html.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // 加载文章
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(articleListProvider.notifier).loadArticles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal News Brief'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: '文章'),
            Tab(icon: Icon(Icons.rss_feed), text: '订阅源'),
            Tab(icon: Icon(Icons.star), text: '收藏'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ArticleSearchDelegate(ref),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(articleListProvider.notifier).refreshArticles();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ArticleListPage(),
          const RssSourcesPage(),
          const StarredArticlesPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddRssDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRssDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加RSS订阅源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '订阅源名称',
                hintText: '例如：技术博客',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'RSS URL',
                hintText: '例如：https://example.com/rss.xml',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final url = urlController.text.trim();
              final name = nameController.text.trim();
              
              if (url.isNotEmpty && name.isNotEmpty) {
                Navigator.of(context).pop();
                
                // 添加订阅源
                final source = RssSource(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  url: url,
                );
                ref.read(rssSourcesProvider.notifier).addSource(source);
                
                // 获取并保存文章
                await ref.read(articleListProvider.notifier).fetchAndSaveArticles(url);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('RSS订阅源添加成功')),
                  );
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class StarredArticlesPage extends ConsumerWidget {
  const StarredArticlesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ArticleListPage(isStarredOnly: true);
  }
}

class ArticleSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  ArticleSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('请输入搜索关键词'));
    }

    // 执行搜索
    ref.read(articleListProvider.notifier).searchArticles(query);

    return const SearchResultPage();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}

class SearchResultPage extends ConsumerWidget {
  const SearchResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleListState = ref.watch(articleListProvider);

    if (articleListState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (articleListState.error != null) {
      return Center(
        child: Text('搜索出错: ${articleListState.error}'),
      );
    }

    if (articleListState.articles.isEmpty) {
      return const Center(child: Text('没有找到相关文章'));
    }

    return ListView.builder(
      itemCount: articleListState.articles.length,
      itemBuilder: (context, index) {
        final article = articleListState.articles[index];
        return ArticleTile(article: article);
      },
    );
  }
}

class ArticleTile extends StatelessWidget {
  final Article article;

  const ArticleTile({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        article.title,
        style: TextStyle(
          fontWeight: article.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.source,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(article.publishedAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Icon(
        article.isStar ? Icons.star : Icons.star_border,
        color: article.isStar ? Colors.amber : null,
      ),
      onTap: () {
        // 导航到文章详情页
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ArticleDetailPage(article: article),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

class ArticleDetailPage extends ConsumerStatefulWidget {
  final Article article;

  const ArticleDetailPage({
    super.key,
    required this.article,
  });

  @override
  ConsumerState<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends ConsumerState<ArticleDetailPage> {
  bool _isGeneratingSummary = false;
  bool _isCreatingNote = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.source),
        actions: [
          IconButton(
            icon: Icon(
              widget.article.isStar ? Icons.star : Icons.star_border,
              color: widget.article.isStar ? Colors.amber : null,
            ),
            onPressed: () {
              ref.read(articleListProvider.notifier).toggleStar(widget.article.url);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(widget.article.publishedAt),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 使用flutter_html渲染HTML内容
                    Html(
                      data: widget.article.content,
                      style: {
                        "body": Style(
                          fontSize: FontSize(16.0),
                          lineHeight: const LineHeight(1.5),
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        "p": Style(
                          margin: Margins.only(bottom: 16.0),
                        ),
                        "h1": Style(
                          fontSize: FontSize(24.0),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(bottom: 16.0),
                        ),
                        "h2": Style(
                          fontSize: FontSize(20.0),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(bottom: 12.0),
                        ),
                        "h3": Style(
                          fontSize: FontSize(18.0),
                          fontWeight: FontWeight.bold,
                          margin: Margins.only(bottom: 8.0),
                        ),
                        "a": Style(
                          color: Theme.of(context).colorScheme.primary,
                          textDecoration: TextDecoration.underline,
                        ),
                        "code": Style(
                          backgroundColor: Colors.grey.shade200,
                          padding: HtmlPaddings.symmetric(horizontal: 4.0),
                          fontFamily: 'monospace',
                        ),
                        "pre": Style(
                          backgroundColor: Colors.grey.shade100,
                          padding: HtmlPaddings.all(12.0),
                          fontFamily: 'monospace',
                          whiteSpace: WhiteSpace.pre,
                        ),
                        "blockquote": Style(
                          border: Border(left: BorderSide(
                            color: Colors.grey.shade400,
                            width: 4.0,
                          )),
                          padding: HtmlPaddings.only(left: 16.0),
                          margin: Margins.symmetric(vertical: 8.0),
                        ),
                        "img": Style(
                          width: Width.maxContent(),
                          height: Height.auto(),
                        ),
                      },
                      onLinkTap: (url, _, __) async {
                        if (url != null) {
                          await PlatformService.openUrl(url);
                        }
                      },
                    ),
                    
                    // AI摘要部分
                    if (widget.article.summary != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'AI摘要',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          widget.article.summary!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 功能按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await PlatformService.openUrl(widget.article.url);
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('在浏览器中打开'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await PlatformService.shareText(
                      widget.article.title,
                      '${widget.article.title}\n\n${widget.article.url}',
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('分享'),
                ),
                if (widget.article.summary == null)
                  ElevatedButton.icon(
                    onPressed: _isGeneratingSummary ? null : _generateSummary,
                    icon: _isGeneratingSummary
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.summarize),
                    label: Text(_isGeneratingSummary ? '生成中...' : '生成摘要'),
                  ),
                ElevatedButton.icon(
                  onPressed: _isCreatingNote ? null : _createNote,
                  icon: _isCreatingNote
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(widget.article.noteExternalId != null
                          ? Icons.note_alt
                          : Icons.note_add),
                  label: Text(_isCreatingNote
                      ? '创建中...'
                      : widget.article.noteExternalId != null
                          ? '更新笔记'
                          : '创建笔记'),
                ),
              ],
            ),
          ],
        ),
      ),
      // 添加FloatingActionButton调用外部编辑器
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await ExternalEditorLauncher.launchEditor(widget.article);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('启动外部编辑器失败: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('外部编辑'),
        tooltip: '在外部编辑器中打开',
      ),
    );
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      // 这里应该使用AI摘要服务
      // 为了演示，我们使用一个简单的模拟摘要
      await Future.delayed(const Duration(seconds: 2));
      
      final mockSummary = '这是一篇关于${widget.article.source}的文章，主要讨论了${widget.article.title.split(' ').take(3).join(' ')}等内容。文章提供了详细的分析和见解，值得深入阅读。';
      
      // 更新文章摘要
      await ref.read(isarServiceProvider).updateSummary(widget.article.url, mockSummary);
      
      // 刷新文章列表状态
      await ref.read(articleListProvider.notifier).refreshArticles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('摘要生成成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成摘要失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
        });
      }
    }
  }

  Future<void> _createNote() async {
    setState(() {
      _isCreatingNote = true;
    });

    try {
      // 这里应该使用笔记服务
      // 为了演示，我们使用一个简单的模拟笔记创建
      await Future.delayed(const Duration(seconds: 1));
      
      final mockNoteId = 'note_${DateTime.now().millisecondsSinceEpoch}';
      
      // 更新文章的外部笔记ID
      await ref.read(isarServiceProvider).updateNoteExternalId(widget.article.url, mockNoteId);
      
      // 刷新文章列表状态
      await ref.read(articleListProvider.notifier).refreshArticles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('笔记创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建笔记失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingNote = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}