import 'package:baozi_comic/controllers/controllers.dart';
import 'package:baozi_comic/models/models.dart';
import 'package:baozi_comic/widgets/comic_card.dart';
import 'package:baozi_comic/widgets/error_widget.dart';
import 'package:baozi_comic/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';
import 'package:get/get.dart';

class BookshelfPage extends GetView<BookshelfController> {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back_ios_new_rounded).iconClick(onTap: Get.back),
        title: text('我的书架').mk,
        actions: [const Icon(Icons.more_vert).iconClick(onTap: controller.showMoreActions)],
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
          return CustomErrorWidget(error: controller.error, onRetry: controller.refreshData);
        }

        return TabBarView(controller: controller.tabController, children: [_buildFavoritesTab(), _buildHistoryTab()]);
      }),
    );
  }

  Widget _buildFavoritesTab() {
    return Obx(() {
      if (!controller.hasFavorites) {
        return Center(
          child: column.center.children([
            Icons.favorite_border.icon.s64.grey.mk,
            h16,
            text('暂无收藏').f16.grey.mk,
            h8,
            text('快去收藏喜欢的漫画吧！').f14.grey.mk,
          ]),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadFavorites,
        child: gridview.p16.childWidth200.spacing12.ratio70.dataBuilder(controller.favorites, (_, __, comic) {
          return GestureDetector(
            onLongPress: () => _showComicActions(comic, isFavorite: true),
            child: ComicCard(comic: comic, onTap: () => controller.goToComicDetail(comic)),
          );
        }),
      );
    });
  }

  Widget _buildHistoryTab() {
    return Obx(() {
      if (!controller.hasHistory) {
        return Center(
          child: column.center.children([
            Icons.history.icon.s64.grey.mk,
            h16,
            text('暂无阅读历史').f16.grey.mk,
            h8,
            text('开始阅读漫画吧！').f14.grey.mk,
          ]),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadReadingHistory,
        child: listview.p16.dataBuilder(controller.readingHistory, (context, index, history) {
          return GestureDetector(onLongPress: () => _showHistoryActions(history), child: _buildHistoryCard(history));
        }),
      );
    });
  }

  Widget _buildHistoryCard(ReadingHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: padding.p12.child(
        row.children([
          image(history.comicCoverUrl).rounded6.w60.h80.cover.mk,
          w12,
          column.expanded.crossStart.spacing4.children([
            text(history.comicTitle).ellipsis.maxLine2.f16.bold.mk,
            if (history.lastChapterTitle != null)
              text('阅读至: ${history.lastChapterTitle}').ellipsis.maxLine1.f14.grey.mk,
            text(_formatDateTime(history.lastReadTime)).f12.grey.mk,
          ]),
          textButton('继续').click(onTap: () => controller.continueReading(history)),
        ]),
      ),
    );
  }

  void _showComicActions(Comic comic, {bool isFavorite = false}) {
    Get.bottomSheet(
      container.white.roundedT16.child(
        column.min.children([
          container.p16.child(text(comic.title).ellipsis.maxLine2.mk),
          ListTile(
            leading: const Icon(Icons.info),
            title: text('查看详情').mk,
            onTap: () {
              Get.back();
              controller.goToComicDetail(comic);
            },
          ),
          if (isFavorite)
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: text('取消收藏').mk,
              onTap: () {
                Get.back();
                controller.removeFromFavorites(comic);
              },
            ),
        ]),
      ),
    );
  }

  void _showHistoryActions(ReadingHistory history) {
    Get.bottomSheet(
      container.white.roundedT16.child(
        column.min.children([
          container.p16.child(text(history.comicTitle).ellipsis.maxLine2.mk),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: text('继续阅读').mk,
            onTap: () {
              Get.back();
              controller.continueReading(history);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: text('查看详情').mk,
            onTap: () {
              Get.back();
              Get.toNamed('/comic/${history.comicId}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: text('删除记录').mk,
            onTap: () {
              Get.back();
              controller.removeFromHistory(history);
            },
          ),
        ]),
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
