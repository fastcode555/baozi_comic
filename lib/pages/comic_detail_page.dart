import 'dart:ui';

import 'package:baozi_comic/controllers/controllers.dart';
import 'package:baozi_comic/models/models.dart';
import 'package:baozi_comic/widgets/error_widget.dart';
import 'package:baozi_comic/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';
import 'package:get/get.dart';

class ComicDetailPage extends GetView<ComicDetailController> {
  const ComicDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget();
        }

        if (controller.error.isNotEmpty) {
          return CustomErrorWidget(error: controller.error, onRetry: controller.refreshData);
        }

        if (controller.comic == null) {
          return Center(child: text('漫画不存在').mk);
        }

        return CustomScrollView(
          slivers: [
            _buildDynamicSliverAppBar(),
            SliverToBoxAdapter(child: column.children([_buildComicInfo(), _buildActionButtons()])),
            _buildChapterListSliver(),
          ],
        );
      }),
    );
  }

  Widget _buildDynamicSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: const Icon(Icons.arrow_back_ios).iconClick(onTap: Get.back),
      // 动态标题：展开时隐藏，收缩时显示书名
      title: LayoutBuilder(
        builder: (context, constraints) {
          // 当AppBar收缩时显示标题
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: constraints.biggest.height <= kToolbarHeight + 50 ? 1.0 : 0.0,
            child: text(controller.comic?.title).f18.bold.white.mk,
          );
        },
      ),
      actions: [
        Obx(
          () => (controller.isFavorite ? Icons.favorite : Icons.favorite_border).icon
              .color(controller.isFavorite ? Colors.red : Colors.white)
              .iconClick(onTap: controller.toggleFavorite),
        ),
        Icons.share.icon.white.iconClick(onTap: controller.shareComic),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: stack.expand.children([
          image(controller.comic?.coverUrl).cover.mk,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: container.color(Colors.black.withValues(alpha: 0.3)).mk,
          ),
          Center(
            child: container.w160.h210.rounded12
                .shadow([
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10)),
                ])
                .child(image(controller.comic?.coverUrl).rounded12.cover.mk),
          ),
          container
              .gradient(
                LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              )
              .mk,
        ]),
      ),
    );
  }

  Widget _buildComicInfo() {
    final comic = controller.comic!;

    return container.p20.child(
      column.crossStart.children([
        text(comic.title).f26.bold.black87.mk,
        h12,
        column.children([
          if (comic.author != null) _buildInfoRow(Icons.person, '作者', comic.author!),
          if (comic.status != null) _buildInfoRow(Icons.update, '状态', comic.status!),
          if (comic.latestChapter != null) _buildInfoRow(Icons.auto_stories, '最新', comic.latestChapter!),
          if (comic.tags != null && comic.tags!.isNotEmpty)
            _buildInfoRow(Icons.category, '分类', _getCategoryFromTags(comic.tags!)),
        ]),
        h16,
        if (comic.tags != null && comic.tags!.isNotEmpty) ...[
          text('分类标签').f16.w600.black87.mk,
          h8,
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: comic.tags!.map((tag) {
              return container.ph12.pv6
                  .color(Get.theme.primaryColor.withValues(alpha: 0.1))
                  .rounded16
                  .border1
                  .border(Get.theme.primaryColor.withValues(alpha: 0.3))
                  .child(text(tag).f13.w500.color(Get.theme.primaryColor).mk);
            }).toList(),
          ),
          h16,
        ],
        if (comic.description != null && comic.description!.isNotEmpty) ...[
          text('作品简介').f16.w600.black87.mk,
          h8,
          container.p12.grey50.rounded8.borderGrey200.child(text(comic.description).f14.black87.mk),
        ],
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return padding.pb8.child(
      row.children([
        icon.icon.s18.grey600.mk,
        w8,
        text('$label: ').f14.w500.grey600.mk,
        text(value).expanded.f14.black87.mk,
      ]),
    );
  }

  String _getCategoryFromTags(List<String> tags) {
    // 从标签中提取分类信息，优先选择包含"漫"的标签
    for (final tag in tags) {
      if (tag.contains('漫') && !tag.contains('連載') && !tag.contains('完結')) {
        return tag;
      }
    }
    // 如果没有找到包含"漫"的标签，返回第一个非状态标签
    for (final tag in tags) {
      if (!tag.contains('連載') && !tag.contains('完結') && !tag.contains('休載')) {
        return tag;
      }
    }
    return tags.isNotEmpty ? tags.first : '未分类';
  }

  Widget _buildActionButtons() {
    return container.ph16.pv8.child(
      row.spacing12.children([
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: controller.hasChapters ? controller.startReading : null,
            icon: const Icon(Icons.play_arrow),
            label: Obx(() {
              if (controller.lastReadChapter != null) {
                return text('继续阅读').mk;
              }
              return text('开始阅读').mk;
            }),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.toggleFavorite,
            icon: Obx(
              () => (controller.isFavorite ? Icons.favorite : Icons.favorite_border).icon
                  .color(controller.isFavorite ? Colors.red : null)
                  .mk,
            ),
            label: Obx(() => text(controller.isFavorite ? '已收藏' : '收藏').mk),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ]),
    );
  }

  /// 使用SliverList构建章节列表（优化性能）
  Widget _buildChapterListSliver() {
    return Obx(() {
      if (!controller.hasChapters) {
        return SliverToBoxAdapter(child: padding.p32.child(Center(child: text('暂无章节').f16.grey.mk)));
      }

      return SliverMainAxisGroup(
        slivers: [
          // 章节列表标题
          SliverToBoxAdapter(
            child: padding.p16.child(
              row.spaceBetween.children([
                text('章节列表 (${controller.chapters.length})').f18.bold.mk,
                textButton('排序').click(onTap: () {}),
              ]),
            ),
          ),
          // 章节列表内容
          SliverList(
            delegate: SliverChildListDelegate.fixed(
              controller.chapters.asMap().entries.map((entry) {
                final index = entry.key;
                final chapter = entry.value;
                final isLastRead = controller.lastReadChapter?.lastChapterId == chapter.id;

                return _buildChapterItem(chapter, index, isLastRead);
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  /// 构建单个章节项
  Widget _buildChapterItem(Chapter chapter, int index, bool isLastRead) {
    return ListTile(
      leading: container.s40
          .color(isLastRead ? Get.theme.primaryColor : Colors.grey[200])
          .rounded20
          .child(Center(child: text('${index + 1}').bold.color(isLastRead ? Colors.white : Colors.grey[600]).mk)),
      title: text(
        chapter.title,
      ).fontWeight(isLastRead ? FontWeight.bold : null).color(isLastRead ? Get.theme.primaryColor : null).mk,
      subtitle: isLastRead ? text('上次阅读').mk : null,
      trailing: isLastRead ? Icons.bookmark.icon.color(Get.theme.primaryColor).mk : null,
      onTap: () => controller.readChapter(chapter),
    );
  }
}
