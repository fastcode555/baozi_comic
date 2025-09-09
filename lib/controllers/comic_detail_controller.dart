import 'package:get/get.dart';
import '../models/models.dart';
import '../services/services.dart';

class ComicDetailController extends GetxController {
  late final StorageService _storageService;

  // 响应式数据
  final _comic = Rxn<Comic>();
  final _chapters = <Chapter>[].obs;
  final _isFavorite = false.obs;
  final _isLoading = false.obs;
  final _error = ''.obs;
  final _lastReadChapter = Rxn<ReadingHistory>();

  // 参数
  late String comicId;

  // Getters
  Comic? get comic => _comic.value;
  List<Chapter> get chapters => _chapters;
  bool get isFavorite => _isFavorite.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  ReadingHistory? get lastReadChapter => _lastReadChapter.value;
  bool get hasChapters => _chapters.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    
    // 获取传递的参数
    final args = Get.arguments;
    if (args is Comic) {
      _comic.value = args;
      comicId = args.id;
    } else {
      comicId = Get.parameters['id'] ?? '';
    }

    if (comicId.isNotEmpty) {
      loadComicDetail();
    }
  }

  /// 加载漫画详情
  Future<void> loadComicDetail() async {
    _isLoading.value = true;
    _error.value = '';

    try {
      // 并发加载数据
      final results = await Future.wait([
        ComicService.getComicDetail(comicId),
        ComicService.getChapterList(comicId),
        _loadFavoriteStatus(),
        _loadLastReadChapter(),
      ]);

      // 处理漫画详情
      final comicResult = results[0] as ApiResponse<Comic>;
      if (comicResult.success && comicResult.data != null) {
        _comic.value = comicResult.data!;
      } else if (comicResult.message != null) {
        _error.value = comicResult.message!;
      }

      // 处理章节列表
      final chaptersResult = results[1] as ApiResponse<List<Chapter>>;
      if (chaptersResult.success && chaptersResult.data != null) {
        _chapters.value = chaptersResult.data!;
      }

    } catch (e) {
      _error.value = '加载漫画详情失败: $e';
      print('ComicDetailController loadComicDetail error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 加载收藏状态
  Future<void> _loadFavoriteStatus() async {
    try {
      _isFavorite.value = await _storageService.isFavorite(comicId);
    } catch (e) {
      print('Failed to load favorite status: $e');
    }
  }

  /// 加载最后阅读章节
  Future<void> _loadLastReadChapter() async {
    try {
      _lastReadChapter.value = await _storageService.getLastReadChapter(comicId);
    } catch (e) {
      print('Failed to load last read chapter: $e');
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite() async {
    if (_comic.value == null) return;

    try {
      if (_isFavorite.value) {
        await _storageService.removeFromFavorites(comicId);
        _isFavorite.value = false;
        Get.snackbar('提示', '已取消收藏');
      } else {
        await _storageService.addToFavorites(_comic.value!);
        _isFavorite.value = true;
        Get.snackbar('提示', '已添加到收藏');
      }
    } catch (e) {
      Get.snackbar('错误', '操作失败: $e');
      print('Failed to toggle favorite: $e');
    }
  }

  /// 开始阅读
  void startReading() {
    if (_chapters.isEmpty) return;

    Chapter chapterToRead;
    
    // 如果有阅读历史，继续阅读
    if (_lastReadChapter.value != null) {
      final lastChapterId = _lastReadChapter.value!.lastChapterId;
      try {
        chapterToRead = _chapters.firstWhere((c) => c.id == lastChapterId);
      } catch (e) {
        // 如果找不到上次阅读的章节，从第一章开始
        chapterToRead = _chapters.first;
      }
    } else {
      // 从第一章开始阅读
      chapterToRead = _chapters.first;
    }

    goToReader(chapterToRead);
  }

  /// 继续阅读
  void continueReading() {
    startReading();
  }

  /// 阅读指定章节
  void readChapter(Chapter chapter) {
    goToReader(chapter);
  }

  /// 导航到阅读器
  void goToReader(Chapter chapter) {
    Get.toNamed('/reader/${chapter.comicId}/${chapter.id}', arguments: {
      'comic': _comic.value,
      'chapter': chapter,
      'chapters': _chapters,
    });
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await loadComicDetail();
  }

  /// 分享漫画
  void shareComic() {
    if (_comic.value == null) return;
    
    final shareText = '推荐一部漫画：${_comic.value!.title}\n'
        '${_comic.value!.description ?? ''}\n'
        '快来包子漫画看吧！';
    
    // 这里可以使用 share_plus 插件实现分享
    Get.snackbar('分享', shareText);
  }

  /// 清除错误信息
  void clearError() {
    _error.value = '';
  }

  /// 获取章节索引
  int getChapterIndex(Chapter chapter) {
    return _chapters.indexOf(chapter);
  }

  /// 获取上一章节（章节列表现在是按正序排列1,2,3...，所以上一章是index-1）
  Chapter? getPreviousChapter(Chapter currentChapter) {
    final index = getChapterIndex(currentChapter);
    if (index > 0) {
      return _chapters[index - 1];
    }
    return null;
  }

  /// 获取下一章节（章节列表现在是按正序排列1,2,3...，所以下一章是index+1）
  Chapter? getNextChapter(Chapter currentChapter) {
    final index = getChapterIndex(currentChapter);
    if (index < _chapters.length - 1) {
      return _chapters[index + 1];
    }
    return null;
  }
}
