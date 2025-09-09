import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/controllers.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../models/models.dart';
import '../widgets/comic_card.dart';

class BookshelfPage extends GetView<BookshelfController> {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back_ios_new_rounded)),
        title: const Text('我的书架'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: controller.showMoreActions,
          ),
        ],
        bottom: TabBar(
          controller: controller.tabController,
          tabs: const [
            Tab(text: '收藏'),
            Tab(text: '历史'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget();
        }

        if (controller.error.isNotEmpty) {
          return CustomErrorWidget(
            error: controller.error,
            onRetry: controller.refreshData,
          );
        }

        return TabBarView(
          controller: controller.tabController,
          children: [
            _buildFavoritesTab(),
            _buildHistoryTab(),
          ],
        );
      }),
    );
  }

  Widget _buildFavoritesTab() {
    return Obx(() {
      if (!controller.hasFavorites) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '暂无收藏',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '快去收藏喜欢的漫画吧！',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadFavorites,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: controller.favorites.length,
          itemBuilder: (context, index) {
            final comic = controller.favorites[index];
            return GestureDetector(
              onLongPress: () => _showComicActions(comic, isFavorite: true),
              child: ComicCard(
                comic: comic,
                onTap: () => controller.goToComicDetail(comic),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildHistoryTab() {
    return Obx(() {
      if (!controller.hasHistory) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '暂无阅读历史',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '开始阅读漫画吧！',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadReadingHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.readingHistory.length,
          itemBuilder: (context, index) {
            final history = controller.readingHistory[index];
            return GestureDetector(
              onLongPress: () => _showHistoryActions(history),
              child: _buildHistoryCard(history),
            );
          },
        ),
      );
    });
  }

  Widget _buildHistoryCard(ReadingHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 封面
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: history.comicCoverUrl ?? '',
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.comicTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (history.lastChapterTitle != null)
                    Text(
                      '阅读至: ${history.lastChapterTitle}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(history.lastReadTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // 继续阅读按钮
            TextButton(
              onPressed: () => controller.continueReading(history),
              child: const Text('继续'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComicActions(Comic comic, {bool isFavorite = false}) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                comic.title,
                style: Get.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('查看详情'),
              onTap: () {
                Get.back();
                controller.goToComicDetail(comic);
              },
            ),
            if (isFavorite)
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('取消收藏'),
                onTap: () {
                  Get.back();
                  controller.removeFromFavorites(comic);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showHistoryActions(ReadingHistory history) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                history.comicTitle,
                style: Get.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('继续阅读'),
              onTap: () {
                Get.back();
                controller.continueReading(history);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('查看详情'),
              onTap: () {
                Get.back();
                Get.toNamed('/comic/${history.comicId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除记录'),
              onTap: () {
                Get.back();
                controller.removeFromHistory(history);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
