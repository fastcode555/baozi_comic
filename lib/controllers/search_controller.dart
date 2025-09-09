import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import '../services/services.dart';

class SearchController extends GetxController {
  late final StorageService _storageService;

  // 响应式数据
  final _searchResults = <Comic>[].obs;
  final _searchHistory = <String>[].obs;
  final _suggestions = <String>[].obs;
  final _categories = <Category>[].obs;
  final _isLoading = false.obs;
  final _error = ''.obs;
  
  // 搜索控制器
  final searchTextController = TextEditingController();
  final focusNode = FocusNode();
  
  // Getters
  List<Comic> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;
  List<String> get suggestions => _suggestions;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get hasResults => _searchResults.isNotEmpty;
  bool get hasHistory => _searchHistory.isNotEmpty;
  bool get hasSuggestions => _suggestions.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _storageService = Get.find<StorageService>();
    _loadSearchHistory();
    _loadCategories();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  /// 加载搜索历史
  Future<void> _loadSearchHistory() async {
    try {
      final history = await _storageService.getSearchHistory();
      _searchHistory.assignAll(history);
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  /// 加载分类
  Future<void> _loadCategories() async {
    try {
      _isLoading.value = true;
      _error.value = '';
      
      final response = await ComicService.getCategories();
      if (response.success) {
        _categories.assignAll(response.data!);
      } else {
        _error.value = response.message ?? '加载分类失败';
      }
    } catch (e) {
      _error.value = e.toString();
      print('Error loading categories: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 搜索漫画
  Future<void> searchComics(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      _isLoading.value = true;
      _error.value = '';
      
      // 添加到搜索历史
      await _storageService.addSearchHistory(query);
      await _loadSearchHistory();
      
      // 执行搜索
      final response = await ComicService.searchComics(query);
      if (response.success) {
        _searchResults.assignAll(response.data!.comics);
      } else {
        _error.value = response.message ?? '搜索失败';
      }
      
      // 清空建议
      _suggestions.clear();
      
    } catch (e) {
      _error.value = e.toString();
      print('Error searching comics: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 获取搜索建议
  Future<void> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _suggestions.clear();
      return;
    }
    
    try {
      final response = await ComicService.getSearchSuggestions(query);
      if (response.success) {
        _suggestions.assignAll(response.data!);
      }
    } catch (e) {
      print('Error getting suggestions: $e');
    }
  }

  /// 按分类搜索
  Future<void> searchByCategory(String categoryId) async {
    try {
      _isLoading.value = true;
      _error.value = '';
      
      final response = await ComicService.getComicsByCategory(categoryId);
      if (response.success) {
        _searchResults.assignAll(response.data!);
      } else {
        _error.value = response.message ?? '按分类搜索失败';
      }
      
    } catch (e) {
      _error.value = e.toString();
      print('Error searching by category: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 移除搜索历史项
  Future<void> removeSearchHistoryItem(String query) async {
    try {
      await _storageService.removeSearchHistory(query);
      _searchHistory.remove(query);
    } catch (e) {
      print('Error removing search history item: $e');
    }
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    try {
      await _storageService.clearSearchHistory();
      _searchHistory.clear();
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  /// 清空搜索结果
  void clearSearchResults() {
    _searchResults.clear();
    _suggestions.clear();
    searchTextController.clear();
  }

  /// 选择建议
  void selectSuggestion(String suggestion) {
    searchTextController.text = suggestion;
    searchComics(suggestion);
  }

  /// 选择历史记录
  void selectHistory(String query) {
    searchTextController.text = query;
    searchComics(query);
  }

  /// 重试搜索
  void retry() {
    final query = searchTextController.text;
    if (query.isNotEmpty) {
      searchComics(query);
    }
  }
}