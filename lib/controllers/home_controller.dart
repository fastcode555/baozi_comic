import 'package:get/get.dart';
import '../models/models.dart';
import '../services/services.dart';

class HomeController extends GetxController {
  // 响应式数据 - 7个分类区块
  final _hotComics = <Comic>[].obs;                       // 热门漫画
  final _recommendedChineseComics = <Comic>[].obs;        // 推荐国漫  
  final _recommendedKoreanComics = <Comic>[].obs;         // 推荐韩漫
  final _recommendedJapaneseComics = <Comic>[].obs;       // 推荐日漫
  final _actionComics = <Comic>[].obs;                    // 热血漫画
  final _newComics = <Comic>[].obs;                       // 最新上架
  final _recentlyUpdatedComics = <Comic>[].obs;           // 最近更新
  
  final _categories = <Category>[].obs;
  final _isLoading = false.obs;
  final _error = ''.obs;

  // Getters
  List<Comic> get hotComics => _hotComics;
  List<Comic> get recommendedChineseComics => _recommendedChineseComics;
  List<Comic> get recommendedKoreanComics => _recommendedKoreanComics;
  List<Comic> get recommendedJapaneseComics => _recommendedJapaneseComics;
  List<Comic> get actionComics => _actionComics;
  List<Comic> get newComics => _newComics;
  List<Comic> get recentlyUpdatedComics => _recentlyUpdatedComics;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// 加载首页数据
  Future<void> loadData() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      // 并发加载所有分类数据
      final results = await Future.wait([
        ComicService.getHotComics(),                        // 0: 热门漫画
        ComicService.getRecommendedChineseComics(),         // 1: 推荐国漫
        ComicService.getRecommendedKoreanComics(),          // 2: 推荐韩漫
        ComicService.getRecommendedJapaneseComics(),        // 3: 推荐日漫
        ComicService.getActionComics(),                     // 4: 热血漫画
        ComicService.getNewComics(),                        // 5: 最新上架
        ComicService.getRecentlyUpdatedComics(),            // 6: 最近更新
        ComicService.getCategories(),                       // 7: 分类列表
      ]);

      // 处理热门漫画
      final hotComicsResult = results[0] as ApiResponse<List<Comic>>;
      if (hotComicsResult.success && hotComicsResult.data != null) {
        _hotComics.value = hotComicsResult.data!;
      }

      // 处理推荐国漫
      final chineseComicsResult = results[1] as ApiResponse<List<Comic>>;
      if (chineseComicsResult.success && chineseComicsResult.data != null) {
        _recommendedChineseComics.value = chineseComicsResult.data!;
      }

      // 处理推荐韩漫
      final koreanComicsResult = results[2] as ApiResponse<List<Comic>>;
      if (koreanComicsResult.success && koreanComicsResult.data != null) {
        _recommendedKoreanComics.value = koreanComicsResult.data!;
      }

      // 处理推荐日漫
      final japaneseComicsResult = results[3] as ApiResponse<List<Comic>>;
      if (japaneseComicsResult.success && japaneseComicsResult.data != null) {
        _recommendedJapaneseComics.value = japaneseComicsResult.data!;
      }

      // 处理热血漫画
      final actionComicsResult = results[4] as ApiResponse<List<Comic>>;
      if (actionComicsResult.success && actionComicsResult.data != null) {
        _actionComics.value = actionComicsResult.data!;
      }

      // 处理最新上架
      final newComicsResult = results[5] as ApiResponse<List<Comic>>;
      if (newComicsResult.success && newComicsResult.data != null) {
        _newComics.value = newComicsResult.data!;
      }

      // 处理最近更新
      final recentlyUpdatedResult = results[6] as ApiResponse<List<Comic>>;
      if (recentlyUpdatedResult.success && recentlyUpdatedResult.data != null) {
        _recentlyUpdatedComics.value = recentlyUpdatedResult.data!;
      }

      // 处理分类
      final categoriesResult = results[7] as ApiResponse<List<Category>>;
      if (categoriesResult.success && categoriesResult.data != null) {
        _categories.value = categoriesResult.data!;
      }

      // 检查是否有任何错误
      final hasError = results.any((result) => !result.success);
      if (hasError) {
        final errors = results
            .where((result) => !result.success)
            .map((result) => result.message ?? '未知错误')
            .join('; ');
        _error.value = errors;
      }
    } catch (e) {
      _error.value = '加载数据失败: $e';
      print('HomeController loadData error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await loadData();
  }

  /// 根据分类加载漫画
  Future<void> loadComicsByCategory(String categoryId) async {
    try {
      _isLoading.value = true;
      final result = await ComicService.getComicsByCategory(categoryId);
      
      if (result.success && result.data != null) {
        // 导航到分类页面，传递数据
        Get.toNamed('/category', arguments: {
          'categoryId': categoryId,
          'comics': result.data,
        });
      } else {
        Get.snackbar('错误', result.message ?? '加载分类漫画失败');
      }
    } catch (e) {
      Get.snackbar('错误', '加载分类漫画失败: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 导航到漫画详情
  void goToComicDetail(Comic comic) {
    Get.toNamed('/comic/${comic.id}', arguments: comic);
  }

  /// 导航到搜索页面
  void goToSearch() {
    Get.toNamed('/search');
  }

  /// 导航到分类页面
  void goToCategories() {
    Get.toNamed('/categories');
  }

  /// 导航到书架页面
  void goToBookshelf() {
    Get.toNamed('/bookshelf');
  }

  /// 清除错误信息
  void clearError() {
    _error.value = '';
  }
}
