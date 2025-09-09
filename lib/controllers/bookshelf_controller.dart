import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import '../services/services.dart';

enum BookshelfTab { favorites, history }

class BookshelfController extends GetxController with GetSingleTickerProviderStateMixin {
  late final StorageService _storageService;

  // 响应式数据
  final _favorites = <Comic>[].obs;
  final _readingHistory = <ReadingHistory>[].obs;
  final _currentTab = BookshelfTab.favorites.obs;
  final _isLoading = false.obs;
  final _error = ''.obs;

  // TabController
  late TabController tabController;

  // Getters
  List<Comic> get favorites => _favorites;
  List<ReadingHistory> get readingHistory => _readingHistory;
  BookshelfTab get currentTab => _currentTab.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get hasFavorites => _favorites.isNotEmpty;
  bool get hasHistory => _readingHistory.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    
    // 初始化TabController
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_onTabChanged);
    
    loadData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  /// Tab变化监听
  void _onTabChanged() {
    final newTab = tabController.index == 0 ? BookshelfTab.favorites : BookshelfTab.history;
    _currentTab.value = newTab;
  }

  /// 加载数据
  Future<void> loadData() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await Future.wait([
        loadFavorites(),
        loadReadingHistory(),
      ]);
    } catch (e) {
      _error.value = '加载数据失败: $e';
      print('BookshelfController loadData error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 加载收藏列表
  Future<void> loadFavorites() async {
    try {
      final favorites = await _storageService.getFavorites();
      _favorites.value = favorites;
    } catch (e) {
      print('Failed to load favorites: $e');
      throw e;
    }
  }

  /// 加载阅读历史
  Future<void> loadReadingHistory() async {
    try {
      final history = await _storageService.getReadingHistory();
      _readingHistory.value = history;
    } catch (e) {
      print('Failed to load reading history: $e');
      throw e;
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await loadData();
  }

  /// 切换到收藏Tab
  void switchToFavorites() {
    tabController.animateTo(0);
  }

  /// 切换到历史Tab
  void switchToHistory() {
    tabController.animateTo(1);
  }

  /// 从收藏移除漫画
  Future<void> removeFromFavorites(Comic comic) async {
    try {
      await _storageService.removeFromFavorites(comic.id);
      _favorites.removeWhere((c) => c.id == comic.id);
      Get.snackbar('提示', '已从收藏中移除');
    } catch (e) {
      Get.snackbar('错误', '移除失败: $e');
      print('Failed to remove from favorites: $e');
    }
  }

  /// 从历史记录移除
  Future<void> removeFromHistory(ReadingHistory history) async {
    try {
      await _storageService.removeFromHistory(history.comicId);
      _readingHistory.removeWhere((h) => h.comicId == history.comicId);
      Get.snackbar('提示', '已从历史记录中移除');
    } catch (e) {
      Get.snackbar('错误', '移除失败: $e');
      print('Failed to remove from history: $e');
    }
  }

  /// 清空收藏
  Future<void> clearFavorites() async {
    if (_favorites.isEmpty) return;

    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('确认清空'),
          content: const Text('确定要清空所有收藏吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _storageService.clearFavorites();
        _favorites.clear();
        Get.snackbar('提示', '收藏已清空');
      }
    } catch (e) {
      Get.snackbar('错误', '清空失败: $e');
      print('Failed to clear favorites: $e');
    }
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    if (_readingHistory.isEmpty) return;

    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('确认清空'),
          content: const Text('确定要清空所有历史记录吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _storageService.clearHistory();
        _readingHistory.clear();
        Get.snackbar('提示', '历史记录已清空');
      }
    } catch (e) {
      Get.snackbar('错误', '清空失败: $e');
      print('Failed to clear history: $e');
    }
  }

  /// 导航到漫画详情
  void goToComicDetail(Comic comic) {
    Get.toNamed('/comic/${comic.id}', arguments: comic);
  }

  /// 从历史记录继续阅读
  void continueReading(ReadingHistory history) {
    if (history.lastChapterId != null) {
      Get.toNamed('/reader/${history.comicId}/${history.lastChapterId}');
    } else {
      // 如果没有章节信息，先跳转到详情页
      Get.toNamed('/comic/${history.comicId}');
    }
  }

  /// 搜索收藏
  List<Comic> searchFavorites(String query) {
    if (query.trim().isEmpty) return _favorites;
    
    final lowercaseQuery = query.toLowerCase();
    return _favorites.where((comic) {
      return comic.title.toLowerCase().contains(lowercaseQuery) ||
             (comic.author?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// 搜索历史记录
  List<ReadingHistory> searchHistory(String query) {
    if (query.trim().isEmpty) return _readingHistory;
    
    final lowercaseQuery = query.toLowerCase();
    return _readingHistory.where((history) {
      return history.comicTitle.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// 清除错误信息
  void clearError() {
    _error.value = '';
  }

  /// 显示更多操作
  void showMoreActions() {
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
                '更多操作',
                style: Get.textTheme.titleLarge,
              ),
            ),
            if (_currentTab.value == BookshelfTab.favorites)
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('清空收藏'),
                onTap: () {
                  Get.back();
                  clearFavorites();
                },
              ),
            if (_currentTab.value == BookshelfTab.history)
              ListTile(
                leading: const Icon(Icons.history_toggle_off),
                title: const Text('清空历史记录'),
                onTap: () {
                  Get.back();
                  clearHistory();
                },
              ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('刷新'),
              onTap: () {
                Get.back();
                refreshData();
              },
            ),
          ],
        ),
      ),
    );
  }
}
