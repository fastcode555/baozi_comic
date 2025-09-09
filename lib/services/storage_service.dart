import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _historyKey = 'reading_history';
  static const String _searchHistoryKey = 'search_history';
  static const String _settingsKey = 'app_settings';

  late SharedPreferences _prefs;

  /// 初始化存储服务
  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  /// 收藏相关
  Future<void> addToFavorites(Comic comic) async {
    final favorites = await getFavorites();
    favorites.removeWhere((c) => c.id == comic.id);
    favorites.insert(0, comic);
    
    final jsonList = favorites.map((c) => c.toJson()).toList();
    await _prefs.setString(_favoritesKey, jsonEncode(jsonList));
  }

  Future<void> removeFromFavorites(String comicId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((c) => c.id == comicId);
    
    final jsonList = favorites.map((c) => c.toJson()).toList();
    await _prefs.setString(_favoritesKey, jsonEncode(jsonList));
  }

  Future<List<Comic>> getFavorites() async {
    final jsonString = _prefs.getString(_favoritesKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Comic.fromJson(json)).toList();
    } catch (e) {
      print('Error loading favorites: $e');
      return [];
    }
  }

  Future<bool> isFavorite(String comicId) async {
    final favorites = await getFavorites();
    return favorites.any((c) => c.id == comicId);
  }

  /// 阅读历史相关
  Future<void> addToHistory(ReadingHistory history) async {
    final historyList = await getReadingHistory();
    historyList.removeWhere((h) => h.comicId == history.comicId);
    historyList.insert(0, history);
    
    // 限制历史记录数量
    if (historyList.length > 100) {
      historyList.removeRange(100, historyList.length);
    }
    
    final jsonList = historyList.map((h) => h.toJson()).toList();
    await _prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<void> removeFromHistory(String comicId) async {
    final historyList = await getReadingHistory();
    historyList.removeWhere((h) => h.comicId == comicId);
    
    final jsonList = historyList.map((h) => h.toJson()).toList();
    await _prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  Future<List<ReadingHistory>> getReadingHistory() async {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => ReadingHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error loading reading history: $e');
      return [];
    }
  }

  Future<ReadingHistory?> getLastReadChapter(String comicId) async {
    final historyList = await getReadingHistory();
    try {
      return historyList.firstWhere((h) => h.comicId == comicId);
    } catch (e) {
      return null;
    }
  }

  /// 搜索历史相关
  Future<void> addSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final searchHistory = await getSearchHistory();
    searchHistory.remove(query);
    searchHistory.insert(0, query);
    
    // 限制搜索历史数量
    if (searchHistory.length > 20) {
      searchHistory.removeRange(20, searchHistory.length);
    }
    
    await _prefs.setStringList(_searchHistoryKey, searchHistory);
  }

  Future<void> removeSearchHistory(String query) async {
    final searchHistory = await getSearchHistory();
    searchHistory.remove(query);
    await _prefs.setStringList(_searchHistoryKey, searchHistory);
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
  }

  Future<List<String>> getSearchHistory() async {
    return _prefs.getStringList(_searchHistoryKey) ?? [];
  }

  /// 应用设置相关
  Future<void> setSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    final settings = await getSettings();
    return settings[key] as T? ?? defaultValue;
  }

  Future<Map<String, dynamic>> getSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) return {};
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading settings: $e');
      return {};
    }
  }

  /// 清理相关
  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  Future<void> clearFavorites() async {
    await _prefs.remove(_favoritesKey);
  }
}