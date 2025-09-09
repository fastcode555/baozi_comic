import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../controllers/controllers.dart';
import '../models/models.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

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
          return CustomErrorWidget(
            error: controller.error,
            onRetry: controller.refreshData,
          );
        }

        if (controller.comic == null) {
          return const Center(
            child: Text('漫画不存在'),
          );
        }

        return CustomScrollView(
          slivers: [
            _buildDynamicSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildComicInfo(),
                  _buildActionButtons(),
                ],
              ),
            ),
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
      leading: IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back_ios)),
      // 动态标题：展开时隐藏，收缩时显示书名
      title: LayoutBuilder(
        builder: (context, constraints) {
          // 当AppBar收缩时显示标题
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: constraints.biggest.height <= kToolbarHeight + 50 ? 1.0 : 0.0,
            child: Text(
              controller.comic?.title ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      actions: [
        Obx(() => IconButton(
          icon: Icon(
            controller.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: controller.isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: controller.toggleFavorite,
        )),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: controller.shareComic,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 高斯模糊背景
            CachedNetworkImage(
              imageUrl: controller.comic?.coverUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
              ),
            ),
            // 高斯模糊滤镜
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
            // 小图片在中央
            Center(
              child: Container(
                width: 160,
                height: 210, // 285:375的比例
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: controller.comic?.coverUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            // 渐变遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComicInfo() {
    final comic = controller.comic!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            comic.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // 作者、状态和最新章节信息
          Column(
            children: [
              if (comic.author != null)
                _buildInfoRow(Icons.person, '作者', comic.author!),
              if (comic.status != null)
                _buildInfoRow(Icons.update, '状态', comic.status!),
              if (comic.latestChapter != null)
                _buildInfoRow(Icons.auto_stories, '最新', comic.latestChapter!),
              // 显示分类信息（从标签中提取）
              if (comic.tags != null && comic.tags!.isNotEmpty)
                _buildInfoRow(Icons.category, '分类', _getCategoryFromTags(comic.tags!)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 标签
          if (comic.tags != null && comic.tags!.isNotEmpty) ...[
            const Text(
              '分类标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: comic.tags!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Get.theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Get.theme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      color: Get.theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // 简介
          if (comic.description != null && comic.description!.isNotEmpty) ...[
            const Text(
              '作品简介',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                comic.description!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: controller.hasChapters ? controller.startReading : null,
              icon: const Icon(Icons.play_arrow),
              label: Obx(() {
                if (controller.lastReadChapter != null) {
                  return const Text('继续阅读');
                }
                return const Text('开始阅读');
              }),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: controller.toggleFavorite,
              icon: Obx(() => Icon(
                controller.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: controller.isFavorite ? Colors.red : null,
              )),
              label: Obx(() => Text(
                controller.isFavorite ? '已收藏' : '收藏',
              )),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 使用SliverList构建章节列表（优化性能）
  Widget _buildChapterListSliver() {
    return Obx(() {
      if (!controller.hasChapters) {
        return SliverToBoxAdapter(
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                '暂无章节',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: [
          // 章节列表标题
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '章节列表 (${controller.chapters.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // 这里可以实现排序功能
                    },
                    child: const Text('排序'),
                  ),
                ],
              ),
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
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLastRead
              ? Get.theme.primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: isLastRead ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        chapter.title,
        style: TextStyle(
          color: isLastRead ? Get.theme.primaryColor : null,
          fontWeight: isLastRead ? FontWeight.bold : null,
        ),
      ),
      subtitle: isLastRead ? const Text('上次阅读') : null,
      trailing: isLastRead
          ? Icon(
              Icons.bookmark,
              color: Get.theme.primaryColor,
            )
          : null,
      onTap: () => controller.readChapter(chapter),
    );
  }
}
