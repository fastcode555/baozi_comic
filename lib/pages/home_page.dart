import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/controllers.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:  SystemUiOverlayStyle(
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
          leading: const SizedBox(),
          title: const Text(
            '包子漫画',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: controller.goToSearch,
            ),
            const SizedBox(width: 16),
          ],
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

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 搜索栏
                  _buildSearchBar(),

                  // 分类导航
                  _buildCategorySection(),

                  // 1. 热门漫画
                  _buildComicsSection(
                    title: '热门漫画',
                    comics: controller.hotComics,
                    showRanking: true,
                  ),

                  // 2. 推荐国漫
                  _buildComicsSection(
                    title: '推荐国漫',
                    comics: controller.recommendedChineseComics,
                  ),

                  // 3. 推荐韩漫
                  _buildComicsSection(
                    title: '推荐韩漫',
                    comics: controller.recommendedKoreanComics,
                  ),

                  // 4. 推荐日漫
                  _buildComicsSection(
                    title: '推荐日漫',
                    comics: controller.recommendedJapaneseComics,
                  ),

                  // 5. 热血漫画
                  _buildComicsSection(
                    title: '热血漫画',
                    comics: controller.actionComics,
                  ),

                  // 6. 最新上架
                  _buildComicsSection(
                    title: '最新上架',
                    comics: controller.newComics,
                  ),

                  // 7. 最近更新
                  _buildComicsSection(
                    title: '最近更新',
                    comics: controller.recentlyUpdatedComics,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: controller.goToSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                '搜索漫画名、作者名',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Obx(() {
      if (controller.categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '分类',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: controller.goToCategories,
                  child: const Text('更多'),
                ),
              ],
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.categories.length,
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  return GestureDetector(
                    onTap: () => controller.loadComicsByCategory(category.id),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Get.theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.category,
                              color: Get.theme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 通用的漫画区块构建方法
  Widget _buildComicsSection({
    required String title,
    required List<dynamic> comics,
    bool showRanking = false,
  }) {
    return Obx(() {
      if (comics.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: 导航到对应分类的更多页面
                  },
                  child: const Text('更多'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240, // 增加高度以容纳285x375的图片比例
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: comics.length,
                itemBuilder: (context, index) {
                  final comic = comics[index];
                  return GestureDetector(
                    onTap: () => controller.goToComicDetail(comic),
                    child: Container(
                      width: 140, // 调整宽度以适配285x375比例
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: comic.coverUrl ?? '',
                                  width: 140,
                                  height: 184, // 约285:375的比例
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
                                if (showRanking && comic.ranking != null && comic.ranking! <= 10)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: comic.ranking! <= 3 ? Colors.red : Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${comic.ranking}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comic.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (comic.lastUpdate != null)
                            Text(
                              comic.lastUpdate!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // 首页，不需要处理
            break;
          case 1:
            controller.goToCategories();
            break;
          case 2:
            controller.goToSearch();
            break;
          case 3:
            controller.goToBookshelf();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: '分类',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: '搜索',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: '书架',
        ),
      ],
    );
  }
}
