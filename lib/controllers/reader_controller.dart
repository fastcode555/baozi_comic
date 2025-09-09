import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import '../services/services.dart';

class ReaderController extends GetxController {
  late final StorageService _storageService;

  // 响应式数据
  final _comic = Rxn<Comic>();
  final _currentChapter = Rxn<Chapter>();
  final _chapters = <Chapter>[].obs;
  final _imageUrls = <String>[].obs;
  final _currentPageIndex = 0.obs;
  final _isLoading = false.obs;
  final _isLoadingImages = false.obs;
  final _error = ''.obs;
  final _showAppBar = true.obs;
  final _isFullscreen = false.obs;

  // 页面控制器
  final pageController = PageController();
  final scrollController = ScrollController();
  
  // UI自动隐藏控制
  Timer? _hideUITimer;
  bool _isScrolling = false;
  
  // 自动加载下一章控制
  bool _isLoadingNextChapter = false;
  
  // 章节映射和动态标题
  final Map<int, Chapter> _imageIndexToChapter = {}; // 图片索引到章节的映射
  final _currentDisplayChapter = Rxn<Chapter>(); // 当前显示的章节

  // 阅读模式
  final _readingMode = 'vertical'.obs; // horizontal, vertical

  // 参数
  late String comicId;
  late String chapterId;

  // Getters
  Comic? get comic => _comic.value;
  Chapter? get currentChapter => _currentChapter.value;
  List<Chapter> get chapters => _chapters;
  List<String> get imageUrls => _imageUrls;
  int get currentPageIndex => _currentPageIndex.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingImages => _isLoadingImages.value;
  String get error => _error.value;
  bool get showAppBar => _showAppBar.value;
  bool get isFullscreen => _isFullscreen.value;
  String get readingMode => _readingMode.value;
  bool get isLoadingNextChapter => _isLoadingNextChapter;
  Chapter? get currentDisplayChapter => _currentDisplayChapter.value;
  bool get hasImages => _imageUrls.isNotEmpty;
  bool get isFirstPage => _currentPageIndex.value == 0;
  bool get isLastPage => _currentPageIndex.value == _imageUrls.length - 1;
  int get totalPages => _imageUrls.length;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    
    // 获取路由参数
    comicId = Get.parameters['comicId'] ?? '';
    chapterId = Get.parameters['chapterId'] ?? '';

    // 获取传递的参数
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      _comic.value = args['comic'] as Comic?;
      _currentChapter.value = args['chapter'] as Chapter?;
      _chapters.value = args['chapters'] as List<Chapter>? ?? [];
    }

    if (comicId.isNotEmpty && chapterId.isNotEmpty) {
      loadChapterImages();
    }

    // 加载阅读偏好
    _loadReadingPreferences();
    
    // 设置滚动监听器
    _setupScrollListener();
  }

  @override
  void onClose() {
    pageController.dispose();
    scrollController.dispose();
    _hideUITimer?.cancel();
    super.onClose();
  }

  /// 加载章节图片
  Future<void> loadChapterImages() async {
    _isLoadingImages.value = true;
    _error.value = '';

    try {
      // 使用新的getChapterDetail方法获取完整的章节信息
      final result = await ComicService.getChapterDetail(comicId, chapterId);
      
      if (result.success && result.data != null) {
        final chapter = result.data!;
        _currentChapter.value = chapter;
        _currentDisplayChapter.value = chapter; // 初始化当前显示的章节
        
        // 设置图片URL并建立映射
        if (chapter.imageUrls != null && chapter.imageUrls!.isNotEmpty) {
          _imageUrls.value = chapter.imageUrls!;
          
          // 建立图片索引到章节的映射
          _imageIndexToChapter.clear();
          for (int i = 0; i < chapter.imageUrls!.length; i++) {
            _imageIndexToChapter[i] = chapter;
          }
        } else {
          _error.value = '该章节暂无图片';
        }
        
        // 保存阅读历史
        await _saveReadingHistory();
      } else {
        _error.value = result.message ?? '加载章节图片失败';
      }
    } catch (e) {
      _error.value = '加载章节图片失败: $e';
      print('ReaderController loadChapterImages error: $e');
    } finally {
      _isLoadingImages.value = false;
    }
  }

  /// 保存阅读历史
  Future<void> _saveReadingHistory() async {
    if (_comic.value == null || _currentChapter.value == null) return;

    try {
      final history = ReadingHistory(
        comicId: _comic.value!.id,
        comicTitle: _comic.value!.title,
        comicCoverUrl: _comic.value!.coverUrl,
        lastChapterId: _currentChapter.value!.id,
        lastChapterTitle: _currentChapter.value!.title,
        lastReadPage: _currentPageIndex.value,
        lastReadTime: DateTime.now(),
      );

        await _storageService.addToHistory(history);
    } catch (e) {
      print('Failed to save reading history: $e');
    }
  }

  /// 加载阅读偏好
  Future<void> _loadReadingPreferences() async {
    try {
      final mode = await _storageService.getSetting<String>('reading_mode', defaultValue: 'vertical');
      _readingMode.value = mode ?? 'vertical';
    } catch (e) {
      print('Failed to load reading preferences: $e');
    }
  }

  /// 页面变化处理
  void onPageChanged(int index) {
    _currentPageIndex.value = index;
    
    // 定期保存阅读进度
    if (index % 5 == 0) {
      _saveReadingHistory();
    }
  }

  /// 上一页
  void previousPage() {
    if (!isFirstPage) {
      if (_readingMode.value == 'horizontal') {
        pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollToPreviousImage();
      }
    }
  }

  /// 下一页
  void nextPage() {
    if (!isLastPage) {
      if (_readingMode.value == 'horizontal') {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollToNextImage();
      }
    }
  }

  /// 跳转到指定页面
  void goToPage(int index) {
    if (index >= 0 && index < _imageUrls.length) {
      if (_readingMode.value == 'horizontal') {
        pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // 垂直模式下的跳转逻辑
        _scrollToImage(index);
      }
    }
  }

  /// 上一章节（章节列表现在是按正序排列1,2,3...，所以上一章是index-1）
  Future<void> previousChapter() async {
    final currentIndex = _chapters.indexWhere((c) => c.id == chapterId);
    if (currentIndex > 0) {
      final previousChapter = _chapters[currentIndex - 1];
      await _loadChapter(previousChapter);
    } else {
      Get.snackbar('提示', '已经是第一章了');
    }
  }

  /// 下一章节（章节列表现在是按正序排列1,2,3...，所以下一章是index+1）
  Future<void> nextChapter() async {
    final currentIndex = _chapters.indexWhere((c) => c.id == chapterId);
    if (currentIndex < _chapters.length - 1) {
      final nextChapter = _chapters[currentIndex + 1];
      await _loadChapter(nextChapter);
    } else {
      Get.snackbar('提示', '已经是最后一章了');
    }
  }

  /// 加载章节
  Future<void> _loadChapter(Chapter chapter) async {
    _currentChapter.value = chapter;
    chapterId = chapter.id;
    _currentPageIndex.value = 0;
    
    // 重置页面控制器
    if (pageController.hasClients) {
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    await loadChapterImages();
  }

  /// 切换阅读模式
  Future<void> toggleReadingMode() async {
    final newMode = _readingMode.value == 'horizontal' ? 'vertical' : 'horizontal';
    _readingMode.value = newMode;
    
    try {
      await _storageService.setSetting('reading_mode', newMode);
    } catch (e) {
      print('Failed to save reading mode: $e');
    }
  }

  /// 切换全屏模式
  void toggleFullscreen() {
    _isFullscreen.value = !_isFullscreen.value;
    _showAppBar.value = !_isFullscreen.value;
  }

  /// 切换AppBar显示
  void toggleAppBar() {
    _showAppBar.value = !_showAppBar.value;
    _resetHideUITimer();
  }

  /// 设置滚动监听器
  void _setupScrollListener() {
    scrollController.addListener(_onScroll);
  }

  /// 滚动监听
  void _onScroll() {
    if (!_isScrolling) {
      _isScrolling = true;
      _hideUI();
    }
    _resetScrollingState();
    
    // 更新当前显示的章节
    _updateCurrentDisplayChapter();
    
    // 检查是否需要预加载下一章
    _checkAndPreloadNextChapter();
  }
  
  /// 根据滚动位置更新当前显示的章节
  void _updateCurrentDisplayChapter() {
    // 只在垂直阅读模式下更新
    if (_readingMode.value != 'vertical') return;
    
    try {
      // 计算当前可见区域的中心位置对应的图片索引
      final position = scrollController.position;
      final viewportCenter = position.pixels + (Get.height / 2);
      
      // 估算每张图片的平均高度来计算当前图片索引
      final totalHeight = position.maxScrollExtent + Get.height;
      final averageImageHeight = totalHeight / _imageUrls.length;
      final estimatedIndex = (viewportCenter / averageImageHeight).round();
      
      // 确保索引在有效范围内
      final currentImageIndex = estimatedIndex.clamp(0, _imageUrls.length - 1);
      
      // 根据图片索引找到对应的章节
      final chapter = _imageIndexToChapter[currentImageIndex];
      if (chapter != null && chapter != _currentDisplayChapter.value) {
        _currentDisplayChapter.value = chapter;
        print('切换显示章节: ${chapter.title}');
      }
    } catch (e) {
      print('更新显示章节失败: $e');
    }
  }
  
  /// 检查并预加载下一章
  void _checkAndPreloadNextChapter() {
    // 只在垂直阅读模式下进行预加载
    if (_readingMode.value != 'vertical' || _isLoadingNextChapter) {
      return;
    }
    
    // 检查当前滚动位置是否接近底部
    final position = scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final currentExtent = position.pixels;
    
    // 计算剩余可滚动距离，如果小于屏幕高度的1.5倍，开始预加载
    final remainingDistance = maxExtent - currentExtent;
    final screenHeight = Get.height;
    
    if (remainingDistance < screenHeight * 1.5) {
      _autoLoadNextChapter();
    }
  }
  
  /// 自动加载下一章并追加到当前列表
  Future<void> _autoLoadNextChapter() async {
    if (_isLoadingNextChapter) return;
    
    // 检查是否有下一章
    final currentIndex = _chapters.indexWhere((c) => c.id == chapterId);
    if (currentIndex >= _chapters.length - 1) {
      // 已经是最后一章（最旧的章节）
      return;
    }
    
    _isLoadingNextChapter = true;
    
    try {
      final nextChapter = _chapters[currentIndex + 1];
      print('开始预加载下一章: ${nextChapter.title}');
      
      // 获取下一章的详细信息
      final chapterResult = await ComicService.getChapterDetail(comicId, nextChapter.id);
      if (chapterResult.success && chapterResult.data != null) {
        final nextChapterData = chapterResult.data!;
        
        // 将下一章的图片追加到当前列表
        if (nextChapterData.images != null && nextChapterData.images!.isNotEmpty) {
          // 为下一章图片添加特殊标记，便于识别章节分界
          // 使用负数index来标记章节开始
          final nextChapterImages = nextChapterData.images!.asMap().entries.map((entry) {
            final originalImg = entry.value;
            final newIndex = entry.key;
            
            return ComicImage(
              url: originalImg.url,
              width: originalImg.width,
              height: originalImg.height,
              // 使用特殊标记：-1000 - chapterIndex 来标识新章节
              index: newIndex == 0 ? -1000 - currentIndex : _imageUrls.length + newIndex,
            );
          }).toList();
          
          // 记录当前图片数量，用于建立新的映射
          final currentImageCount = _imageUrls.length;
          
          // 追加图片到当前列表
          _imageUrls.addAll(nextChapterData.imageUrls ?? []);
          
          // 为新追加的图片建立章节映射
          for (int i = currentImageCount; i < _imageUrls.length; i++) {
            _imageIndexToChapter[i] = nextChapter;
          }
          
          // 如果当前章节有images，也追加下一章的images
          if (_currentChapter.value?.images != null) {
            final currentImages = List<ComicImage>.from(_currentChapter.value!.images!);
            currentImages.addAll(nextChapterImages);
            
            // 更新当前章节数据
            _currentChapter.value = Chapter(
              id: _currentChapter.value!.id,
              title: _currentChapter.value!.title,
              comicId: _currentChapter.value!.comicId,
              chapterNumber: _currentChapter.value!.chapterNumber,
              imageUrls: _imageUrls,
              images: currentImages,
              currentPage: _currentChapter.value!.currentPage,
              totalPages: _currentChapter.value!.totalPages,
            );
          }
          
          print('成功预加载下一章，追加了 ${nextChapterImages.length} 张图片');
          
          // 保存阅读历史，更新到新章节
          await _saveReadingHistory();
        }
      }
    } catch (e) {
      print('预加载下一章失败: $e');
    } finally {
      _isLoadingNextChapter = false;
    }
  }

  /// 重置滚动状态
  void _resetScrollingState() {
    _hideUITimer?.cancel();
    _hideUITimer = Timer(const Duration(milliseconds: 150), () {
      _isScrolling = false;
    });
  }

  /// 隐藏UI
  void _hideUI() {
    if (_showAppBar.value) {
      _showAppBar.value = false;
    }
  }

  /// 显示UI（长按触发）
  void showUITemporarily() {
    _showAppBar.value = true;
    _resetHideUITimer();
  }

  /// 重置UI隐藏计时器
  void _resetHideUITimer() {
    _hideUITimer?.cancel();
    _hideUITimer = Timer(const Duration(seconds: 3), () {
      if (_showAppBar.value) {
        _showAppBar.value = false;
      }
    });
  }
  
  /// 根据图片索引获取对应的章节
  Chapter? getChapterByImageIndex(int imageIndex) {
    return _imageIndexToChapter[imageIndex];
  }
  
  /// 更新当前显示的章节
  void updateDisplayChapter(Chapter chapter) {
    _currentDisplayChapter.value = chapter;
  }

  /// 显示章节列表
  void showChapterList() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '章节列表',
                style: Get.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  final isCurrentChapter = chapter.id == chapterId;
                  
                  return ListTile(
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        color: isCurrentChapter ? Get.theme.primaryColor : null,
                        fontWeight: isCurrentChapter ? FontWeight.bold : null,
                      ),
                    ),
                    onTap: () {
                      Get.back();
                      _loadChapter(chapter);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示阅读设置
  void showReadingSettings() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '阅读设置',
                style: Get.textTheme.titleLarge,
              ),
            ),
            ListTile(
              title: const Text('阅读模式'),
              subtitle: Text(_readingMode.value == 'horizontal' ? '水平翻页' : '垂直滚动'),
              trailing: Switch(
                value: _readingMode.value == 'vertical',
                onChanged: (value) => toggleReadingMode(),
              ),
            ),
            ListTile(
              title: const Text('全屏模式'),
              trailing: Switch(
                value: _isFullscreen.value,
                onChanged: (value) => toggleFullscreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 垂直模式下滚动到上一张图片
  void _scrollToPreviousImage() {
    // 实现垂直滚动的上一张图片逻辑
  }

  /// 垂直模式下滚动到下一张图片
  void _scrollToNextImage() {
    // 实现垂直滚动的下一张图片逻辑
  }

  /// 垂直模式下滚动到指定图片
  void _scrollToImage(int index) {
    // 实现垂直滚动到指定图片的逻辑
  }

  /// 清除错误信息
  void clearError() {
    _error.value = '';
  }

  /// 返回上一页
  void goBack() {
    Get.back();
  }
}
