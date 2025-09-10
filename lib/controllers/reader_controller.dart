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
  
  // 历史记录更新控制
  String? _lastUpdatedChapterId;

  // 阅读模式
  final _readingMode = 'vertical'.obs; // horizontal, vertical

  // 参数
  late String comicId;
  late String chapterId;
  late int _currentChapterNumber; // 当前章节的数字部分

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

    // 初始化章节URL和数字
    _initializeChapterInfo();

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

  /// 初始化章节信息
  void _initializeChapterInfo() {
    // 从chapterId中提取数字部分
    _currentChapterNumber = int.tryParse(chapterId) ?? 0;
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
        // 如果章节不存在，可能是最后一章，显示提示
        if (result.message?.contains('404') == true || result.message?.contains('不存在') == true) {
          Get.snackbar('提示', '已经是最后一章了');
          return;
        }
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
    if (_comic.value == null) return;

    try {
      // 优先使用当前显示的章节，如果没有则使用当前章节
      final chapter = _currentDisplayChapter.value ?? _currentChapter.value;
      if (chapter == null) return;

      // 计算当前章节内的页面索引
      int chapterPageIndex = _currentPageIndex.value;
      
      // 如果是垂直阅读模式且有多章节，需要计算在当前章节内的页面索引
      if (_readingMode.value == 'vertical' && _imageIndexToChapter.isNotEmpty) {
        // 找到当前章节在图片列表中的起始位置
        for (int i = 0; i < _imageUrls.length; i++) {
          if (_imageIndexToChapter[i]?.id == chapter.id) {
            chapterPageIndex = _currentPageIndex.value - i;
            break;
          }
        }
        
        // 确保页面索引不为负数
        chapterPageIndex = chapterPageIndex.clamp(0, (chapter.images?.length ?? chapter.imageUrls?.length ?? 1) - 1);
      }

      final history = ReadingHistory(
        comicId: _comic.value!.id,
        comicTitle: _comic.value!.title,
        comicCoverUrl: _comic.value!.coverUrl,
        lastChapterId: chapter.id,
        lastChapterTitle: chapter.title,
        lastReadPage: chapterPageIndex,
        lastReadTime: DateTime.now(),
      );

      await _storageService.addToHistory(history);
      print('历史记录已保存: ${chapter.title} - 第${chapterPageIndex + 1}页');
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

  /// 上一章节（通过修改URL数字实现）
  Future<void> previousChapter() async {
    final previousChapterNumber = _currentChapterNumber - 1;
    if (previousChapterNumber > 0) {
      await _loadChapterByNumber(previousChapterNumber);
    } else {
      Get.snackbar('提示', '已经是第一章了');
    }
  }

  /// 下一章节（通过修改URL数字实现）
  Future<void> nextChapter() async {
    final nextChapterNumber = _currentChapterNumber + 1;
    await _loadChapterByNumber(nextChapterNumber);
  }

  /// 通过章节数字加载章节
  Future<void> _loadChapterByNumber(int chapterNumber) async {
    _currentChapterNumber = chapterNumber;
    chapterId = chapterNumber.toString();
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

  /// 加载章节（保持向后兼容）
  Future<void> _loadChapter(Chapter chapter) async {
    _currentChapter.value = chapter;
    chapterId = chapter.id;
    _currentPageIndex.value = 0;
    
    // 更新章节数字
    _currentChapterNumber = int.tryParse(chapterId) ?? 0;
    
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
      
      // 使用更精确的方法计算当前图片索引
      int currentImageIndex = _findCurrentImageIndex(viewportCenter);
      
      // 调试信息
      print('滚动检测: 图片索引=$currentImageIndex, 总图片数=${_imageUrls.length}, 章节映射数量=${_imageIndexToChapter.length}');
      
      // 根据图片索引找到对应的章节
      final chapter = _imageIndexToChapter[currentImageIndex];
      print('找到章节: ${chapter?.title ?? "null"}');
      
      if (chapter != null && chapter != _currentDisplayChapter.value) {
        _currentDisplayChapter.value = chapter;
        print('切换显示章节: ${chapter.title}');
        
        // 当章节发生变化时，更新历史记录
        _updateHistoryOnChapterChange(chapter, currentImageIndex);
      }
    } catch (e) {
      print('更新显示章节失败: $e');
    }
  }
  
  /// 查找当前可见的图片索引（更精确的方法）
  int _findCurrentImageIndex(double viewportCenter) {
    // 如果图片索引到章节的映射为空，使用简单估算
    if (_imageIndexToChapter.isEmpty) {
      final totalHeight = scrollController.position.maxScrollExtent + Get.height;
      final averageImageHeight = totalHeight / _imageUrls.length;
      return (viewportCenter / averageImageHeight).round().clamp(0, _imageUrls.length - 1);
    }
    
    // 使用章节边界来更精确地定位
    int bestIndex = 0;
    double minDistance = double.infinity;
    
    // 遍历所有图片索引，找到最接近视口中心的图片
    for (int i = 0; i < _imageUrls.length; i++) {
      // 估算图片i的位置
      final imagePosition = _estimateImagePosition(i);
      final distance = (imagePosition - viewportCenter).abs();
      
      if (distance < minDistance) {
        minDistance = distance;
        bestIndex = i;
      }
    }
    
    return bestIndex.clamp(0, _imageUrls.length - 1);
  }
  
  /// 估算图片在滚动视图中的位置
  double _estimateImagePosition(int imageIndex) {
    if (imageIndex >= _imageUrls.length) return 0;
    
    // 使用平均高度估算位置
    final totalHeight = scrollController.position.maxScrollExtent + Get.height;
    final averageImageHeight = totalHeight / _imageUrls.length;
    
    return imageIndex * averageImageHeight;
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
    
    // 计算剩余可滚动距离，如果小于屏幕高度的2倍，开始预加载
    final remainingDistance = maxExtent - currentExtent;
    final screenHeight = Get.height;
    
    print('滚动检查: 剩余距离=${remainingDistance.toStringAsFixed(0)}, 屏幕高度=${screenHeight.toStringAsFixed(0)}, 触发距离=${(screenHeight * 2.0).toStringAsFixed(0)}');
    
    if (remainingDistance < screenHeight * 2.0) {
      print('触发自动加载下一章');
      _autoLoadNextChapter();
    }
  }
  
  /// 自动加载下一章并追加到当前列表
  Future<void> _autoLoadNextChapter() async {
    if (_isLoadingNextChapter) {
      print('正在加载下一章，跳过重复调用');
      return;
    }
    
    _isLoadingNextChapter = true;
    
    try {
      final nextChapterNumber = _currentChapterNumber + 1;
      print('开始预加载下一章: 第${nextChapterNumber}章');
      
      // 获取下一章的详细信息
      final chapterResult = await ComicService.getChapterDetail(comicId, nextChapterNumber.toString());
      if (chapterResult.success && chapterResult.data != null) {
        final nextChapterData = chapterResult.data!;
        
        // 将下一章的图片追加到当前列表
        if (nextChapterData.imageUrls != null && nextChapterData.imageUrls!.isNotEmpty) {
          // 记录当前图片数量
          final currentImageCount = _imageUrls.length;
          
          // 追加图片到当前列表
          _imageUrls.addAll(nextChapterData.imageUrls!);
          
          // 为新追加的图片建立章节映射
          for (int i = currentImageCount; i < _imageUrls.length; i++) {
            _imageIndexToChapter[i] = nextChapterData;
          }
          
          // 强制更新UI
          _imageUrls.refresh();
          
          print('成功预加载下一章，追加了 ${nextChapterData.imageUrls!.length} 张图片，总图片数: ${_imageUrls.length}');
          print('章节映射更新: 从索引$currentImageCount到${_imageUrls.length-1}映射到章节${nextChapterData.title}');
        }
      } else {
        // 如果下一章不存在，说明已经是最后一章了
        print('下一章不存在，已经是最后一章了');
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
              child: _chapters.isNotEmpty 
                ? _buildChapterListFromData()
                : _buildChapterListFromNumbers(),
            ),
          ],
        ),
      ),
    );
  }

  /// 从章节数据构建列表
  Widget _buildChapterListFromData() {
    return ListView.builder(
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
    );
  }

  /// 从数字构建章节列表（用于历史记录进入的情况）
  Widget _buildChapterListFromNumbers() {
    // 显示当前章节前后各10章
    final startChapter = (_currentChapterNumber - 10).clamp(1, _currentChapterNumber);
    final endChapter = _currentChapterNumber + 10;
    final chapterNumbers = List.generate(
      endChapter - startChapter + 1,
      (index) => startChapter + index,
    );

    return ListView.builder(
      itemCount: chapterNumbers.length,
      itemBuilder: (context, index) {
        final chapterNumber = chapterNumbers[index];
        final isCurrentChapter = chapterNumber == _currentChapterNumber;
        
        return ListTile(
          title: Text(
            '第${chapterNumber}章',
            style: TextStyle(
              color: isCurrentChapter ? Get.theme.primaryColor : null,
              fontWeight: isCurrentChapter ? FontWeight.bold : null,
            ),
          ),
          onTap: () {
            Get.back();
            _loadChapterByNumber(chapterNumber);
          },
        );
      },
    );
  }

  /// 显示阅读设置
  void showReadingSettings() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.5,
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
            ListTile(
              title: const Text('测试自动加载下一章'),
              subtitle: const Text('手动触发自动加载功能'),
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                Get.back();
                _autoLoadNextChapter();
              },
            ),
            ListTile(
              title: const Text('调试信息'),
              subtitle: Text('当前章节: ${_currentChapterNumber}, 图片数量: ${_imageUrls.length}'),
              trailing: const Icon(Icons.info),
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

  /// 当章节变化时更新历史记录
  Future<void> _updateHistoryOnChapterChange(Chapter chapter, int currentImageIndex) async {
    if (_comic.value == null) return;

    // 如果章节没有变化，跳过更新
    if (_lastUpdatedChapterId == chapter.id) {
      print('章节未变化，跳过历史记录更新: ${chapter.title}');
      return;
    }

    try {
      print('开始更新历史记录: 章节=${chapter.title}, 图片索引=$currentImageIndex');
      
      // 计算当前章节内的页面索引
      int chapterPageIndex = 0;
      
      // 找到当前章节在图片列表中的起始位置
      for (int i = 0; i < _imageUrls.length; i++) {
        if (_imageIndexToChapter[i]?.id == chapter.id) {
          chapterPageIndex = currentImageIndex - i;
          print('找到章节起始位置: 索引$i, 章节内页面索引=$chapterPageIndex');
          break;
        }
      }
      
      // 确保页面索引不为负数
      chapterPageIndex = chapterPageIndex.clamp(0, (chapter.images?.length ?? chapter.imageUrls?.length ?? 1) - 1);
      
      final history = ReadingHistory(
        comicId: _comic.value!.id,
        comicTitle: _comic.value!.title,
        comicCoverUrl: _comic.value!.coverUrl,
        lastChapterId: chapter.id,
        lastChapterTitle: chapter.title,
        lastReadPage: chapterPageIndex,
        lastReadTime: DateTime.now(),
      );

      await _storageService.addToHistory(history);
      _lastUpdatedChapterId = chapter.id; // 更新最后保存的章节ID
      print('历史记录已更新: ${chapter.title} - 第${chapterPageIndex + 1}页');
    } catch (e) {
      print('更新历史记录失败: $e');
    }
  }

  /// 返回上一页
  void goBack() {
    Get.back();
  }
}
