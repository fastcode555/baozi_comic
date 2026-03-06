import '../models/models.dart';
import 'http_service.dart';
import 'parser_service.dart';
import '../utils/debug_helper.dart';

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
      // 尝试多个可能的域名
      final urls = [
        'https://www.twmanga.com/comic/chapter/${comicId}/0_${chapterId}.html',
        'https://www.baozimh.com/comic/chapter/${comicId}/0_${chapterId}.html',
        'https://tw.baozimh.com/comic/chapter/${comicId}/0_${chapterId}.html',
      ];
      
      String? htmlContent;
      String? successUrl;
      
      // 尝试每个URL直到成功
      for (final url in urls) {
        try {
          htmlContent = await HttpService.get(url);
          successUrl = url;
          print('成功从 $url 获取章节内容');
          break;
        } catch (e) {
          print('从 $url 获取失败: $e');
          continue;
        }
      }
      
      if (htmlContent == null) {
        return ApiResponse.error('无法从任何源获取章节内容');
      }
      
      final imageUrls = ParserService.parseChapterImages(htmlContent);
      
      if (imageUrls.isEmpty) {
        print('警告: 未能解析到图片URL，HTML内容长度: ${htmlContent.length}');
        print('使用的URL: $successUrl');
        
        // 启用调试模式时输出详细信息
        DebugHelper.analyzeChapterHtml(htmlContent, chapterId);
        
        // 可选：保存HTML到文件以便检查
        // await DebugHelper.saveHtmlToFile(htmlContent, 'chapter_${chapterId}');
        
        // 返回错误信息，包含调试信息
        return ApiResponse.error('未能解析到图片。这可能是因为网站结构已更改。请检查网络连接或稍后重试。');
      }
      
      print('成功解析 ${imageUrls.length} 张图片');
      return ApiResponse.success(imageUrls);
    } catch (e) {
      print('获取章节图片失败: $e');
      return ApiResponse.error('获取章节图片失败: $e');
    }
  }

  /// 获取章节详细信息（包含分页）
  static Future<ApiResponse<Chapter>> getChapterDetail(String comicId, String chapterId) async {
    try {
      // 尝试多个可能的域名
      final urls = [
        'https://www.twmanga.com/comic/chapter/${comicId}/0_${chapterId}.html',
        'https://www.baozimh.com/comic/chapter/${comicId}/0_${chapterId}.html',
        'https://tw.baozimh.com/comic/chapter/${comicId}/0_${chapterId}.html',
      ];
      
      String? htmlContent;
      
      // 尝试每个URL直到成功
      for (final url in urls) {
        try {
          htmlContent = await HttpService.get(url);
          print('成功从 $url 获取章节详情');
          break;
        } catch (e) {
          print('从 $url 获取失败: $e');
          continue;
        }
      }
      
      if (htmlContent == null) {
        return ApiResponse.error('无法从任何源获取章节详情');
      }
      
      final chapter = ParserService.parseChapterDetail(htmlContent, chapterId, comicId);
      
      if (chapter.imageUrls == null || chapter.imageUrls!.isEmpty) {
        print('警告: 章节详情中未包含图片URL');
      } else {
        print('章节详情包含 ${chapter.imageUrls!.length} 张图片');
      }
      
      return ApiResponse.success(chapter);
    } catch (e) {
      print('获取章节详情失败: $e');
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
