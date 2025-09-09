import '../models/models.dart';
import 'http_service.dart';
import 'parser_service.dart';

class ComicService {
  
  /// 获取首页HTML内容（用于解析所有分类）
  static Future<String> _getHomepageContent() async {
    return await HttpService.get(HttpService.baseUrl);
  }

  /// 获取热门漫画
  static Future<ApiResponse<List<Comic>>> getHotComics() async {
    try {
      final htmlContent = await _getHomepageContent();
      final comics = ParserService.parseHotComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取热门漫画失败: $e');
    }
  }

  /// 获取推荐国漫
  static Future<ApiResponse<List<Comic>>> getRecommendedChineseComics() async {
    try {
      final htmlContent = await _getHomepageContent();
      final comics = ParserService.parseRecommendedChineseComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取推荐国漫失败: $e');
    }
  }

  /// 获取推荐韩漫
  static Future<ApiResponse<List<Comic>>> getRecommendedKoreanComics() async {
    try {
      final htmlContent = await _getHomepageContent();
      final comics = ParserService.parseRecommendedKoreanComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取推荐韩漫失败: $e');
    }
  }

  /// 获取推荐日漫
  static Future<ApiResponse<List<Comic>>> getRecommendedJapaneseComics() async {
    try {
      final htmlContent = await _getHomepageContent();
      final comics = ParserService.parseRecommendedJapaneseComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取推荐日漫失败: $e');
    }
  }

  /// 获取热血漫画
  static Future<ApiResponse<List<Comic>>> getActionComics() async {
    try {
      final htmlContent = await _getHomepageContent();
      final comics = ParserService.parseActionComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取热血漫画失败: $e');
    }
  }

  /// 获取最新上架漫画（从首页解析）
  static Future<ApiResponse<List<Comic>>> getNewComics() async {
    try {
      final htmlContent = await _getHomepageContent();
      final comics = ParserService.parseNewComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取最新上架漫画失败: $e');
    }
  }

  /// 获取最近更新漫画
  static Future<ApiResponse<List<Comic>>> getRecentlyUpdatedComics() async {
    try {
      final htmlContent = await _getHomepageContent();
      final comics = ParserService.parseRecentlyUpdatedComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取最近更新漫画失败: $e');
    }
  }

  /// 搜索漫画
  static Future<ApiResponse<SearchResult>> searchComics(String query) async {
    try {
      final url = HttpService.buildUrl('/search?q=${Uri.encodeComponent(query)}');
      final htmlContent = await HttpService.get(url);
      final searchResult = ParserService.parseSearchResults(htmlContent, query);
      return ApiResponse.success(searchResult);
    } catch (e) {
      return ApiResponse.error('搜索漫画失败: $e');
    }
  }

  /// 获取漫画详情
  static Future<ApiResponse<Comic>> getComicDetail(String comicId) async {
    try {
      final url = HttpService.buildUrl('/comic/$comicId');
      final htmlContent = await HttpService.get(url);
      final comic = ParserService.parseComicDetail(htmlContent, comicId);
      return ApiResponse.success(comic);
    } catch (e) {
      return ApiResponse.error('获取漫画详情失败: $e');
    }
  }

  /// 获取章节列表
  static Future<ApiResponse<List<Chapter>>> getChapterList(String comicId) async {
    try {
      final url = HttpService.buildUrl('/comic/$comicId');
      final htmlContent = await HttpService.get(url);
      final chapters = ParserService.parseChapterList(htmlContent, comicId);
      return ApiResponse.success(chapters);
    } catch (e) {
      return ApiResponse.error('获取章节列表失败: $e');
    }
  }

  /// 获取章节图片
  static Future<ApiResponse<List<String>>> getChapterImages(String comicId, String chapterId) async {
    try {
      // 构建正确的章节URL，基于分析的URL模式
      // 例如：https://www.twmanga.com/comic/chapter/silingfashiwojishitianzai-mantudezhuyuanzhuheiniaoshe_rjogsq/0_210.html
      final url = 'https://www.twmanga.com/comic/chapter/${comicId}/0_${chapterId}.html';
      final htmlContent = await HttpService.get(url);
      final imageUrls = ParserService.parseChapterImages(htmlContent);
      return ApiResponse.success(imageUrls);
    } catch (e) {
      return ApiResponse.error('获取章节图片失败: $e');
    }
  }

  /// 获取章节详细信息（包含分页）
  static Future<ApiResponse<Chapter>> getChapterDetail(String comicId, String chapterId) async {
    try {
      // 构建正确的章节URL
      final url = 'https://www.twmanga.com/comic/chapter/${comicId}/0_${chapterId}.html';
      final htmlContent = await HttpService.get(url);
      final chapter = ParserService.parseChapterDetail(htmlContent, chapterId, comicId);
      return ApiResponse.success(chapter);
    } catch (e) {
      return ApiResponse.error('获取章节详情失败: $e');
    }
  }

  /// 获取分类列表
  static Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final url = HttpService.buildUrl('/classify');
      final htmlContent = await HttpService.get(url);
      final categories = ParserService.parseCategories(htmlContent);
      return ApiResponse.success(categories);
    } catch (e) {
      return ApiResponse.error('获取分类失败: $e');
    }
  }

  /// 根据分类获取漫画
  static Future<ApiResponse<List<Comic>>> getComicsByCategory(String categoryId, {int page = 1}) async {
    try {
      final url = HttpService.buildUrl('/classify?type=$categoryId&page=$page');
      final htmlContent = await HttpService.get(url);
      final comics = ParserService.parseHotComics(htmlContent); // 使用相同的解析方法
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取分类漫画失败: $e');
    }
  }

  /// 获取最新上架漫画
  static Future<ApiResponse<List<Comic>>> getLatestComics({int page = 1}) async {
    try {
      final url = HttpService.buildUrl('/list/new?page=$page');
      final htmlContent = await HttpService.get(url);
      final comics = ParserService.parseHotComics(htmlContent);
      return ApiResponse.success(comics);
    } catch (e) {
      return ApiResponse.error('获取最新漫画失败: $e');
    }
  }

  /// 获取搜索建议
  static Future<ApiResponse<List<String>>> getSearchSuggestions(String query) async {
    try {
      final url = 'https://tw.baozimh.com/squery/autocomplete?q=${Uri.encodeComponent(query)}';
      final jsonContent = await HttpService.get(url);
      final suggestions = ParserService.parseSearchSuggestions(jsonContent);
      return ApiResponse.success(suggestions);
    } catch (e) {
      return ApiResponse.error('获取搜索建议失败: $e');
    }
  }
}
