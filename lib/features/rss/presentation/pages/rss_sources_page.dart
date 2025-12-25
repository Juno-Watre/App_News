import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_news_brief/features/article/presentation/providers/article_provider.dart';

class RssSourcesPage extends ConsumerWidget {
  const RssSourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rssSourcesState = ref.watch(rssSourcesProvider);

    return Scaffold(
      body: rssSourcesState.sources.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rss_feed,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '还没有RSS订阅源',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右下角的 + 添加RSS订阅源',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: rssSourcesState.sources.length,
              itemBuilder: (context, index) {
                final source = rssSourcesState.sources[index];
                return RssSourceTile(
                  source: source,
                  onRefresh: () async {
                    await ref.read(articleListProvider.notifier).fetchAndSaveArticles(source.url);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('订阅源刷新成功')),
                      );
                    }
                  },
                  onDelete: () {
                    ref.read(rssSourcesProvider.notifier).removeSource(source.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('订阅源删除成功')),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class RssSourceTile extends StatelessWidget {
  final RssSource source;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const RssSourceTile({
    super.key,
    required this.source,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(source.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.url,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (source.category != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  source.category!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') {
              onRefresh();
            } else if (value == 'delete') {
              _showDeleteConfirmation(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('刷新'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _showSourceDetails(context);
        },
      ),
    );
  }

  void _showSourceDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(source.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL: ${source.url}'),
            if (source.category != null) ...[
              const SizedBox(height: 8),
              Text('分类: ${source.category}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除订阅源 "${source.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}