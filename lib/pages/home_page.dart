import 'package:baozi_comic/controllers/controllers.dart';
import 'package:baozi_comic/models/comic.dart';
import 'package:baozi_comic/widgets/error_widget.dart';
import 'package:baozi_comic/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        statusBarColor: Colors.black.withValues(alpha: 0.1),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber,
          elevation: 0,
          leading: gapEmpty,
          title: text('包子漫画').f18.bold.black.mk,
          centerTitle: true,
          actions: [
            Icons.search.icon.black.iconClick(onTap: controller.goToSearch),
            w16,
          ],
        ),
        body: Obx(() {
          if (controller.isLoading) {
            return const LoadingWidget();
          }

          if (controller.error.isNotEmpty) {
            return CustomErrorWidget(error: controller.error, onRetry: controller.refreshData);
          }

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: column.crossStart.children([
                _buildSearchBar(),
                _buildCategorySection(),
                _buildComicsSection(title: '热门漫画', comics: controller.hotComics, showRanking: true),
                _buildComicsSection(title: '推荐国漫', comics: controller.recommendedChineseComics),
                _buildComicsSection(title: '推荐韩漫', comics: controller.recommendedKoreanComics),
                _buildComicsSection(title: '推荐日漫', comics: controller.recommendedJapaneseComics),
                _buildComicsSection(title: '热血漫画', comics: controller.actionComics),
                _buildComicsSection(title: '最新上架', comics: controller.newComics),
                _buildComicsSection(title: '最近更新', comics: controller.recentlyUpdatedComics),
                h20,
              ]),
            ),
          );
        }),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return container.m16.child(
      GestureDetector(
        onTap: controller.goToSearch,
        child: container.ph16.pv12.grey100.rounded26.borderGrey300.child(
          row.spacing8.children([Icons.search.icon.grey.mk, text('搜索漫画名、作者名').grey.mk]),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Obx(() {
      if (controller.categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return container.ph16.child(
        column.crossStart.children([
          row.spaceBetween.children([text('分类').f18.bold.mk, textButton('更多').click(onTap: controller.goToCategories)]),
          sizedBox.h80.child(
            listview.horizontal.dataBuilder(controller.categories, (_, __, category) {
              return GestureDetector(
                onTap: () => controller.loadComicsByCategory(category.id),
                child: container.w60.mr12.child(
                  column.spacing4.children([
                    container.s40
                        .color(Get.theme.primaryColor.withOpacity(0.1))
                        .rounded20
                        .child(Icons.category.icon.s20.color(Get.theme.primaryColor).mk),
                    text(category.name).center.ellipsis.maxLine1.f12.mk,
                  ]),
                ),
              );
            }),
          ),
        ]),
      );
    });
  }

  /// 通用的漫画区块构建方法
  Widget _buildComicsSection({required String title, required List<Comic> comics, bool showRanking = false}) {
    return Obx(() {
      if (comics.isEmpty) {
        return const SizedBox.shrink();
      }

      return container.mt24.ph16.child(
        column.crossStart.spacing12.children([
          row.spaceBetween.children([text(title).f18.bold.mk, textButton('更多').click(onTap: () {})]),
          sizedBox.h240.child(
            listview.horizontal.dataBuilder(comics, (_, __, comic) {
              return GestureDetector(
                onTap: () => controller.goToComicDetail(comic),
                child: container.w140.mr12.child(
                  column.crossStart.children([
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: stack.children([
                        image(comic.coverUrl).w140.h185.cover.mk,
                        if (showRanking && comic.ranking != null && comic.ranking! <= 10)
                          positioned.l8.t8.child(
                            container.ph6.pv2
                                .color(comic.ranking! <= 3 ? Colors.red : Colors.orange)
                                .rounded10
                                .child(text('${comic.ranking}').f12.bold.white.mk),
                          ),
                      ]),
                    ),
                    h4,
                    text(comic.title).ellipsis.maxLine1.f13.w500.mk,
                    if (comic.lastUpdate != null) text(comic.lastUpdate).ellipsis.maxLine1.f11.grey600.mk,
                  ]),
                ),
              );
            }),
          ),
        ]),
      );
    });
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            // 首页，不需要处理
            break;
          case 1:
            controller.goToCategories();
          case 2:
            controller.goToSearch();
          case 3:
            controller.goToBookshelf();
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: '分类'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: '书架'),
      ],
    );
  }
}
