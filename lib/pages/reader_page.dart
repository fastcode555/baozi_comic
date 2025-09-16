import 'package:baozi_comic/controllers/controllers.dart';
import 'package:baozi_comic/widgets/error_widget.dart';
import 'package:baozi_comic/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

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
                  leading: const Icon(Icons.arrow_back_ios_outlined).iconClick(onTap: Get.back),
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
          return Center(child: text('暂无图片').mk);
        }

        return stack.children([_buildImageViewer(), if (controller.showAppBar) _buildBottomBar()]);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      leading: Icons.arrow_back_ios_outlined.icon.white.iconClick(onTap: Get.back),
      title: Obx(() {
        // 使用当前显示的章节，如果没有则回退到当前章节
        final chapter = controller.currentDisplayChapter ?? controller.currentChapter;
        final hasChapterPages = chapter?.totalPages != null && chapter!.totalPages! > 1;

        return column.crossStart.children([
          text(chapter?.title).ellipsis.maxLine1.f16.white.mk,
          row.children([
            text('图片 ${controller.currentPageIndex + 1}/${controller.totalPages}').f12.white.mk,
            if (hasChapterPages) ...[
              text(' • ').f12.white.mk,
              text('第${chapter.currentPage ?? 1}/${chapter.totalPages}页').f12.mk,
            ],
          ]),
        ]);
      }),
      actions: [
        Icons.list.icon.white.iconClick(onTap: controller.showChapterList),
        Icons.settings.icon.white.iconClick(onTap: controller.showReadingSettings),
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
        return Center(child: text('暂无图片').mk);
      }

      return GestureDetector(
        onLongPress: controller.showUITemporarily,
        child: listview.controller(controller.scrollController).builder(
          imageUrls.length + (controller.isLoadingNextChapter ? 1 : 0),
          (context, index) {
            if (index == imageUrls.length && controller.isLoadingNextChapter) {
              return _buildLoadingIndicator();
            }
            return _buildSimpleImage(imageUrls[index], index);
          },
        ),
      );
    });
  }

  /// 简单图片显示（用于ListView，不使用PhotoView）
  Widget _buildSimpleImage(String imageUrl, int index) {
    return Builder(
      key: ValueKey(imageUrl),
      builder: (context) => GestureDetector(
        onTap: () => _showImageDetailByUrl(imageUrl, index, context),
        child: container.wFull.maxHeight(800).minHeight(200).black.child(image(imageUrl).contain.mk),
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
    return container.wFull.p32.black.child(
      column.spacing16.children([
        const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        text('正在加载下一章节...').center.f14.grey400.mk,
      ]),
    );
  }

  Widget _buildImagePage(String imageUrl) {
    return PhotoView(
      key: ValueKey(imageUrl),
      imageProvider: CachedNetworkImageProvider(imageUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3.0,
      initialScale: PhotoViewComputedScale.contained,
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) =>
          Center(child: column.center.spacing8.children([Icons.broken_image.icon.s64.grey.mk, text('图片加载失败').grey.mk])),
    );
  }

  Widget _buildBottomBar() {
    return positioned.l0.r0.b0.child(
      container
          .color(Colors.black.withOpacity(0.7))
          .child(
            padding.ph16.pv8.child(
              row.children([
                Icons.keyboard_arrow_left.icon.white.iconClick(
                  onTap: controller.isFirstPage ? null : controller.previousPage,
                ),
                textButton().child(text('上一章').white.mk).click(onTap: controller.previousChapter),
                spacer,
                Obx(() => text('${controller.currentPageIndex + 1}/${controller.totalPages}').white.mk),
                spacer,
                textButton().child(text('下一章').white.mk).click(onTap: controller.nextChapter),
                Icons.keyboard_arrow_right.icon.white.iconClick(
                  onTap: controller.isLastPage ? null : controller.nextPage,
                ),
              ]),
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
        title: text('${imageIndex + 1} / $totalImages').white.mk,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [Icons.share.icon.white.iconClick(onTap: () {})],
      ),
      body: Center(
        child: PhotoView(
          key: ValueKey(imageUrl),
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (context, error, stackTrace) => Center(
            child: column.center.spacing8.children([Icons.broken_image.icon.s64.grey.mk, text('图片加载失败').grey.mk]),
          ),
        ),
      ),
    );
  }
}
