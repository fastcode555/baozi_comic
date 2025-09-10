import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

import '../controllers/controllers.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';

class ReaderPage extends GetView<ReaderController> {
  const ReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(
          () => controller.showAppBar
              ? _buildAppBar()
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back_ios_outlined)),
                ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoadingImages) {
          return const LoadingWidget(message: '正在加载章节图片...');
        }

        if (controller.error.isNotEmpty) {
          return CustomErrorWidget(error: controller.error, onRetry: controller.loadChapterImages);
        }

        if (!controller.hasImages) {
          return const Center(child: Text('暂无图片'));
        }

        return Stack(children: [_buildImageViewer(), if (controller.showAppBar) _buildBottomBar()]);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      leading: IconButton(
        onPressed: Get.back,
        icon: Icon(Icons.arrow_back_ios_outlined, color: Colors.white),
      ),
      title: Obx(() {
        // 使用当前显示的章节，如果没有则回退到当前章节
        final chapter = controller.currentDisplayChapter ?? controller.currentChapter;
        final hasChapterPages = chapter?.totalPages != null && chapter!.totalPages! > 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter?.title ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Text(
                  '图片 ${controller.currentPageIndex + 1}/${controller.totalPages}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                if (hasChapterPages) ...[
                  const Text(' • ', style: TextStyle(fontSize: 12, color: Colors.white)),
                  Text('第${chapter.currentPage ?? 1}/${chapter.totalPages}页', style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.list, color: Colors.white),
          onPressed: controller.showChapterList,
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: controller.showReadingSettings,
        ),
      ],
    );
  }

  Widget _buildImageViewer() {
    return Obx(() {
      if (controller.readingMode == 'horizontal') {
        return _buildHorizontalViewer();
      } else {
        return _buildVerticalViewer();
      }
    });
  }

  Widget _buildHorizontalViewer() {
    return Obx(() {
      final images = controller.currentChapter?.images;
      if (images == null || images.isEmpty) {
        // 回退到原有的URL列表显示
        return _buildHorizontalViewerLegacy();
      }

      return GestureDetector(
        onTap: controller.toggleAppBar,
        child: PageView.builder(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return _buildImagePage(image.url);
          },
        ),
      );
    });
  }

  /// 原有的水平阅读器（用于向后兼容）
  Widget _buildHorizontalViewerLegacy() {
    return GestureDetector(
      onTap: controller.toggleAppBar,
      child: PageView.builder(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        itemCount: controller.imageUrls.length,
        itemBuilder: (context, index) {
          return _buildImagePage(controller.imageUrls[index]);
        },
      ),
    );
  }

  Widget _buildVerticalViewer() {
    return Obx(() {
      // 直接使用图片URL数组，这样能正确显示自动加载的图片
      final imageUrls = controller.imageUrls;
      if (imageUrls.isEmpty) {
        return const Center(child: Text('暂无图片'));
      }

      return GestureDetector(
        onLongPress: controller.showUITemporarily,
        child: ListView.builder(
          controller: controller.scrollController,
          itemCount: imageUrls.length + (controller.isLoadingNextChapter ? 1 : 0), // 只在加载时+1
          itemBuilder: (context, index) {
            // 最后一个item显示加载状态
            if (index == imageUrls.length && controller.isLoadingNextChapter) {
              return _buildLoadingIndicator();
            }
            
            // 直接使用URL构建图片
            return _buildSimpleImage(imageUrls[index], index);
          },
        ),
      );
    });
  }



  /// 简单图片显示（用于ListView，不使用PhotoView）
  Widget _buildSimpleImage(String imageUrl, int index) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showImageDetailByUrl(imageUrl, index, context),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 800),
          color: Colors.black,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              height: 300,
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 8),
                    Text('加载中... ${index + 1}', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('图片加载失败 ${index + 1}', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // 可以触发重新加载
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  /// 通过URL显示图片详情
  void _showImageDetailByUrl(String imageUrl, int index, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ImageDetailPage(imageUrl: imageUrl, imageIndex: index, totalImages: controller.imageUrls.length),
      ),
    );
  }
  
  
  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: Colors.black,
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            '正在加载下一章节...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePage(String imageUrl) {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(imageUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3.0,
      initialScale: PhotoViewComputedScale.contained,
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('图片加载失败', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
          child: Row(
            children: [
              // 上一页按钮
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
                onPressed: controller.isFirstPage ? null : controller.previousPage,
              ),

              // 上一章按钮
              TextButton(
                onPressed: controller.previousChapter,
                child: const Text('上一章', style: TextStyle(color: Colors.white)),
              ),

              const Spacer(),

              // 页码指示器
              Obx(
                () => Text(
                  '${controller.currentPageIndex + 1}/${controller.totalPages}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              const Spacer(),

              // 下一章按钮
              TextButton(
                onPressed: controller.nextChapter,
                child: const Text('下一章', style: TextStyle(color: Colors.white)),
              ),

              // 下一页按钮
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white),
                onPressed: controller.isLastPage ? null : controller.nextPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图片详情页面（用于放大查看单张图片）
class _ImageDetailPage extends StatelessWidget {
  final String imageUrl;
  final int imageIndex;
  final int totalImages;

  const _ImageDetailPage({required this.imageUrl, required this.imageIndex, required this.totalImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        title: Text('${imageIndex + 1} / $totalImages', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // 分享功能
            },
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
