import 'package:html/parser.dart' as html_parser;
import '../models/models.dart';

class ParserService {
  
  /// 解析首页热门漫画（第一个section）
  static List<Comic> parseHotComics(String htmlContent) {
    return _parseComicsSection(htmlContent, 0); // 第一个section
  }

  /// 解析推荐国漫
  static List<Comic> parseRecommendedChineseComics(String htmlContent) {
    return _parseComicsSection(htmlContent, 1); // 第二个section
  }

  /// 解析推荐韩漫
  static List<Comic> parseRecommendedKoreanComics(String htmlContent) {
    return _parseComicsSection(htmlContent, 2); // 第三个section
  }

  /// 解析推荐日漫
  static List<Comic> parseRecommendedJapaneseComics(String htmlContent) {
    return _parseComicsSection(htmlContent, 3); // 第四个section
  }

  /// 解析热血漫画
  static List<Comic> parseActionComics(String htmlContent) {
    return _parseComicsSection(htmlContent, 4); // 第五个section
  }

  /// 解析最新上架
  static List<Comic> parseNewComics(String htmlContent) {
    return _parseComicsSection(htmlContent, 5); // 第六个section
  }

  /// 解析最近更新
  static List<Comic> parseRecentlyUpdatedComics(String htmlContent) {
    return _parseComicsSection(htmlContent, 6); // 第七个section
  }

  /// 通用方法：解析指定分类区块的漫画
  static List<Comic> _parseComicsSection(String htmlContent, int sectionIndex) {
    final document = html_parser.parse(htmlContent);
    final sections = document.querySelectorAll('.index-recommend-items, .recent');
    
    if (sectionIndex >= sections.length) {
      print('Section index $sectionIndex out of range');
      return [];
    }
    
    final section = sections[sectionIndex];
    final comicCards = section.querySelectorAll('.comics-card');
    
    return comicCards.map((card) {
      try {
        // 获取漫画链接
        final linkElement = card.querySelector('a[href*="/comic/"]');
        final href = linkElement?.attributes['href'] ?? '';
        final id = _extractComicId(href);
        
        // 获取标题
        final titleElement = card.querySelector('.comics-card__title h3');
        final title = titleElement?.text.trim() ?? '';
        
        // 获取封面图片，使用285x375尺寸
        final imgElement = card.querySelector('amp-img');
        var coverUrl = imgElement?.attributes['src'] ?? '';
        
        // 替换图片尺寸为285x375
        if (coverUrl.contains('?w=') && coverUrl.contains('&h=')) {
          coverUrl = coverUrl.replaceAll(RegExp(r'\?w=\d+&h=\d+'), '?w=285&h=375');
        } else if (coverUrl.isNotEmpty && !coverUrl.contains('?')) {
          coverUrl += '?w=285&h=375';
        }
        
        // 获取"更新至xx"信息
        final updateElement = card.querySelector('.comics-card__info small');
        final lastUpdate = updateElement?.text.trim() ?? '';
        
        // 获取标签
        final tagElements = card.querySelectorAll('.tab');
        final tags = tagElements.map((e) => e.text.trim()).toList();
        
        // 获取排名（仅对热门漫画有效）
        final badgeElement = card.querySelector('.comics-card__badge');
        final rankingText = badgeElement?.text.trim();
        final ranking = rankingText != null ? int.tryParse(rankingText) : null;
        
        return Comic(
          id: id,
          title: title,
          coverUrl: _buildImageUrl(coverUrl),
          lastUpdate: lastUpdate.isNotEmpty ? lastUpdate : null,
          tags: tags,
          ranking: ranking,
        );
      } catch (e) {
        print('Error parsing comic card in section $sectionIndex: $e');
        return null;
      }
    }).where((comic) => comic != null && comic.id.isNotEmpty).cast<Comic>().toList();
  }

  /// 解析搜索结果
  static SearchResult parseSearchResults(String htmlContent, String query) {
    final document = html_parser.parse(htmlContent);
    final comicCards = document.querySelectorAll('.comics-card');
    
    final comics = comicCards.map((card) {
      try {
        final linkElement = card.querySelector('a[href*="/comic/"]');
        final href = linkElement?.attributes['href'] ?? '';
        final id = _extractComicId(href);
        
        final titleElement = card.querySelector('.comics-card__title h3');
        final title = titleElement?.text.trim() ?? '';
        
        // 获取封面图片，使用285x375尺寸
        final imgElement = card.querySelector('amp-img');
        var coverUrl = imgElement?.attributes['src'] ?? '';
        
        // 替换图片尺寸为285x375
        if (coverUrl.contains('?w=') && coverUrl.contains('&h=')) {
          coverUrl = coverUrl.replaceAll(RegExp(r'\?w=\d+&h=\d+'), '?w=285&h=375');
        } else if (coverUrl.isNotEmpty && !coverUrl.contains('?')) {
          coverUrl += '?w=285&h=375';
        }
        
        // 获取"更新至xx"信息或最新章节信息
        final updateElement = card.querySelector('.comics-card__info small');
        final updateInfo = updateElement?.text.trim() ?? '';
        
        final tagElements = card.querySelectorAll('.tab');
        final tags = tagElements.map((e) => e.text.trim()).toList();
        
        return Comic(
          id: id,
          title: title,
          coverUrl: _buildImageUrl(coverUrl),
          latestChapter: updateInfo.isNotEmpty ? updateInfo : null,
          lastUpdate: updateInfo.isNotEmpty ? updateInfo : null,  // 同时设置lastUpdate字段
          tags: tags,
        );
      } catch (e) {
        print('Error parsing search result: $e');
        return null;
      }
    }).where((comic) => comic != null && comic.id.isNotEmpty).cast<Comic>().toList();
    
    return SearchResult(
      comics: comics,
      query: query,
      totalCount: comics.length,
      currentPage: 1,
      totalPages: 1,
    );
  }

  /// 解析漫画详情页
  static Comic parseComicDetail(String htmlContent, String comicId) {
    final document = html_parser.parse(htmlContent);
    
    // 解析标题 - 从实际HTML结构获取
    final title = document.querySelector('.comics-detail__title')?.text.trim() ?? 
                  _getMetaContent(document, 'og:novel:book_name') ?? 
                  document.querySelector('title')?.text.replaceFirst('🍱', '').replaceFirst(' - 包子漫畫', '').trim() ?? '';
    
    // 解析作者 - 从实际HTML结构获取
    final author = document.querySelector('.comics-detail__author')?.text.trim() ?? 
                   _getMetaContent(document, 'og:novel:author');
    
    // 解析简介 - 从实际HTML结构获取
    final description = document.querySelector('.comics-detail__desc')?.text.trim() ?? 
                        _getMetaContent(document, 'og:description');
    
    // 解析标签列表（包含状态和分类）
    final tagElements = document.querySelectorAll('.tag-list .tag');
    final tags = tagElements.map((e) => e.text.trim()).where((tag) => tag.isNotEmpty).toList();
    
    // 从标签中提取状态（通常是第一个标签，如"連載中"）
    String? status;
    String? category;
    
    for (final tag in tags) {
      if (tag.contains('連載') || tag.contains('完結') || tag.contains('休載')) {
        status = tag;
      } else if (tag.contains('漫') || tag == '其它' || tag == '其他') {
        category = tag;
      }
    }
    
    // 备用：从meta标签获取状态和分类
    status ??= _getMetaContent(document, 'og:novel:status');
    category ??= _getMetaContent(document, 'og:novel:category');
    
    // 解析最新章节信息
    String? latestChapter;
    final supportingText = document.querySelector('.supporting-text');
    if (supportingText != null) {
      // 查找包含"最新："的span元素中的链接
      final spans = supportingText.querySelectorAll('span');
      for (final span in spans) {
        if (span.text.contains('最新：')) {
          final link = span.querySelector('a');
          if (link != null) {
            latestChapter = link.text.trim();
            break;
          }
        }
      }
      
      // 如果没有找到链接，尝试用正则表达式提取
      if (latestChapter == null) {
        final latestText = supportingText.text;
        final latestMatch = RegExp(r'最新：\s*([^(]+)').firstMatch(latestText);
        if (latestMatch != null) {
          latestChapter = latestMatch.group(1)?.trim();
        }
      }
    }
    
    // 备用：从meta标签获取
    latestChapter ??= _getMetaContent(document, 'og:novel:latest_chapter_name');
    
    // 获取封面
    final coverUrl = _getMetaContent(document, 'og:image') ?? 
                     document.querySelector('.comics-detail__poster amp-img')?.attributes['src'] ?? '';
    
    return Comic(
      id: comicId,
      title: title,
      author: author,
      description: description,
      coverUrl: _buildImageUrl(coverUrl),
      tags: tags,
      status: status,
      latestChapter: latestChapter,
    );
  }
  
  /// 获取meta标签内容的辅助方法
  static String? _getMetaContent(document, String property) {
    // 尝试获取 data-hid 属性
    final metaElement = document.querySelector('meta[data-hid="$property"]') ?? 
                        document.querySelector('meta[name="$property"]') ?? 
                        document.querySelector('meta[property="$property"]');
    return metaElement?.attributes['content']?.trim();
  }

  /// 解析章节列表
  static List<Chapter> parseChapterList(String htmlContent, String comicId) {
    final document = html_parser.parse(htmlContent);
    final chapterElements = document.querySelectorAll('.comics-chapters__item');
    
    // 解析所有章节
    final rawChapters = chapterElements.asMap().entries.map((entry) {
      final element = entry.value;
      
      try {
        final href = element.attributes['href'] ?? '';
        final titleSpan = element.querySelector('span');
        final title = titleSpan?.text.trim() ?? '';
        
        final chapterId = _extractChapterId(href);
        
        // 从标题中提取章节号用于排序和去重
        final chapterNumber = _extractChapterNumber(title);
        
        return Chapter(
          id: chapterId,
          title: title,
          comicId: comicId,
          chapterNumber: chapterNumber,
          url: href,
        );
      } catch (e) {
        print('Error parsing chapter: $e');
        return null;
      }
    }).where((chapter) => chapter != null && chapter.id.isNotEmpty).cast<Chapter>().toList();
    
    // 去重：使用Map以章节号为key，保留最后一个（通常是更完整的数据）
    final Map<int, Chapter> uniqueChapters = {};
    for (final chapter in rawChapters) {
      if (chapter.chapterNumber != null) {
        uniqueChapters[chapter.chapterNumber!] = chapter;
      } else {
        // 如果无法提取章节号，仍然保留（使用ID作为唯一标识）
        final key = int.tryParse(chapter.id) ?? chapter.id.hashCode;
        if (!uniqueChapters.containsKey(key)) {
          uniqueChapters[key] = chapter;
        }
      }
    }
    
    // 按章节号排序：从小到大（1, 2, 3, ...）
    final sortedChapters = uniqueChapters.values.toList();
    sortedChapters.sort((a, b) {
      final aNum = a.chapterNumber ?? 999999;
      final bNum = b.chapterNumber ?? 999999;
      return aNum.compareTo(bNum);
    });
    
    print('解析章节列表: 原始${rawChapters.length}章，去重后${sortedChapters.length}章');
    return sortedChapters;
  }

  /// 解析章节图片
  static List<String> parseChapterImages(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final imageUrls = <String>[];
    
    // 方法1: 查找所有amp-img标签，尝试多个属性
    final imageElements = document.querySelectorAll('amp-img');
    
    for (final imgElement in imageElements) {
      // 尝试从多个可能的属性中获取图片URL
      String? src = imgElement.attributes['src'] ?? 
                    imgElement.attributes['data-src'] ??
                    imgElement.attributes['data-original'] ??
                    imgElement.attributes['data-lazy-src'];
      
      // 如果找到URL且包含图片CDN域名
      if (src != null && src.isNotEmpty && 
          (src.contains('baozicdn.com') || src.contains('static'))) {
        final fullUrl = _buildImageUrl(src);
        if (!imageUrls.contains(fullUrl)) {
          imageUrls.add(fullUrl);
        }
      }
    }
    
    // 方法2: 如果方法1没有找到图片，尝试从script标签中提取
    if (imageUrls.isEmpty) {
      final scriptElements = document.querySelectorAll('script');
      for (final script in scriptElements) {
        final scriptContent = script.text;
        
        // 查找可能包含图片URL的JSON数据
        if (scriptContent.contains('baozicdn.com') || scriptContent.contains('imageUrls')) {
          // 使用正则表达式提取所有图片URL
          final urlPattern = RegExp(r'https?://[^"\s]+?baozicdn\.com[^"\s]+?\.(?:jpg|jpeg|png|webp|gif)', caseSensitive: false);
          final matches = urlPattern.allMatches(scriptContent);
          
          for (final match in matches) {
            final url = match.group(0);
            if (url != null && !imageUrls.contains(url)) {
              imageUrls.add(url);
            }
          }
        }
      }
    }
    
    return imageUrls;
  }

  /// 解析章节图片（包含尺寸信息）
  static List<ComicImage> parseChapterImagesWithDimensions(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final images = <ComicImage>[];
    
    // 方法1: 查找所有amp-img标签
    final imageElements = document.querySelectorAll('amp-img');
    
    for (int i = 0; i < imageElements.length; i++) {
      final imgElement = imageElements[i];
      
      // 尝试从多个可能的属性中获取图片URL
      String? src = imgElement.attributes['src'] ?? 
                    imgElement.attributes['data-src'] ??
                    imgElement.attributes['data-original'] ??
                    imgElement.attributes['data-lazy-src'];
      
      final widthStr = imgElement.attributes['width'];
      final heightStr = imgElement.attributes['height'];
      
      // 如果找到URL且包含图片CDN域名
      if (src != null && src.isNotEmpty && 
          (src.contains('baozicdn.com') || src.contains('static')) &&
          widthStr != null && heightStr != null) {
        final width = int.tryParse(widthStr) ?? 1280;
        final height = int.tryParse(heightStr) ?? 1200;
        final url = _buildImageUrl(src);
        
        // 检查是否已存在相同URL的图片
        if (!images.any((img) => img.url == url)) {
          images.add(ComicImage(
            url: url,
            width: width,
            height: height,
            index: i,
          ));
        }
      }
    }
    
    // 方法2: 如果方法1没有找到图片，尝试从script标签中提取
    if (images.isEmpty) {
      final scriptElements = document.querySelectorAll('script');
      for (final script in scriptElements) {
        final scriptContent = script.text;
        
        // 查找可能包含图片URL的JSON数据
        if (scriptContent.contains('baozicdn.com') || scriptContent.contains('imageUrls')) {
          // 使用正则表达式提取所有图片URL
          final urlPattern = RegExp(r'https?://[^"\s]+?baozicdn\.com[^"\s]+?\.(?:jpg|jpeg|png|webp|gif)', caseSensitive: false);
          final matches = urlPattern.allMatches(scriptContent);
          
          int index = 0;
          for (final match in matches) {
            final url = match.group(0);
            if (url != null && !images.any((img) => img.url == url)) {
              images.add(ComicImage(
                url: url,
                width: 1280, // 默认宽度
                height: 1200, // 默认高度
                index: index++,
              ));
            }
          }
        }
      }
    }
    
    return images;
  }

  /// 解析章节详细信息（包含分页）
  static Chapter parseChapterDetail(String htmlContent, String chapterId, String comicId) {
    final document = html_parser.parse(htmlContent);
    
    // 从标题中提取章节信息和分页信息
    final titleElement = document.querySelector('.text .title') ?? 
                        document.querySelector('.title');
    final fullTitle = titleElement?.text.trim() ?? '';
    
    // 解析分页信息，例如："第211話   神隕之雨(1/4)"
    String chapterTitle = fullTitle;
    int? currentPage;
    int? totalPages;
    
    final pageMatch = RegExp(r'\((\d+)/(\d+)\)').firstMatch(fullTitle);
    if (pageMatch != null) {
      currentPage = int.tryParse(pageMatch.group(1) ?? '');
      totalPages = int.tryParse(pageMatch.group(2) ?? '');
      chapterTitle = fullTitle.replaceFirst(pageMatch.group(0) ?? '', '').trim();
    }
    
    // 解析所有图片（包含尺寸信息）
    final images = parseChapterImagesWithDimensions(htmlContent);
    final imageUrls = images.map((img) => img.url).toList(); // 保持向后兼容
    
    // 提取章节号
    final chapterNumber = _extractChapterNumber(chapterTitle);
    
    return Chapter(
      id: chapterId,
      title: chapterTitle,
      comicId: comicId,
      chapterNumber: chapterNumber,
      imageUrls: imageUrls,
      images: images, // 新增包含尺寸信息的图片列表
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  /// 解析分类列表
  static List<Category> parseCategories(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final categoryElements = document.querySelectorAll('.classify-nav .item');
    
    return categoryElements.map((element) {
      final name = element.text.trim();
      final id = element.attributes['data-type'] ?? name.toLowerCase();
      
      return Category(
        id: id,
        name: name,
      );
    }).where((category) => category.name.isNotEmpty).toList();
  }

  /// 解析搜索建议
  static List<String> parseSearchSuggestions(String jsonContent) {
    try {
      // 假设返回的是简单的字符串数组
      final suggestions = <String>[];
      // 这里需要根据实际API返回格式解析
      return suggestions;
    } catch (e) {
      print('Error parsing search suggestions: $e');
      return [];
    }
  }

  /// 提取漫画ID
  static String _extractComicId(String href) {
    final regex = RegExp(r'/comic/([^/?]+)');
    final match = regex.firstMatch(href);
    return match?.group(1) ?? '';
  }

  /// 提取章节ID
  static String _extractChapterId(String href) {
    final regex = RegExp(r'chapter_slot=(\d+)');
    final match = regex.firstMatch(href);
    return match?.group(1) ?? '';
  }

  /// 提取章节号
  static int? _extractChapterNumber(String title) {
    // 尝试从标题中提取章节号，如"第211話"
    final regex = RegExp(r'第(\d+)[話话]');
    final match = regex.firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    
    // 尝试其他格式，如"Chapter 211"
    final regex2 = RegExp(r'Chapter\s*(\d+)', caseSensitive: false);
    final match2 = regex2.firstMatch(title);
    if (match2 != null) {
      return int.tryParse(match2.group(1) ?? '');
    }
    
    // 尝试纯数字格式
    final regex3 = RegExp(r'(\d+)');
    final match3 = regex3.firstMatch(title);
    if (match3 != null) {
      return int.tryParse(match3.group(1) ?? '');
    }
    
    return null;
  }

  /// 构建完整图片URL
  static String _buildImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return 'https://static-tw.baozimh.com$url';
    return url;
  }
  
  /// 尝试从页面中提取图片数量信息
  static int? _extractImageCount(String htmlContent) {
    // 尝试从标题中提取分页信息，例如："第246話 覺醒全新技能！(1/4)"
    final document = html_parser.parse(htmlContent);
    final titleElement = document.querySelector('.text .title') ?? 
                        document.querySelector('.title');
    final fullTitle = titleElement?.text.trim() ?? '';
    
    // 解析分页信息
    final pageMatch = RegExp(r'\((\d+)/(\d+)\)').firstMatch(fullTitle);
    if (pageMatch != null) {
      final totalPages = int.tryParse(pageMatch.group(2) ?? '');
      return totalPages;
    }
    
    // 尝试从页面中查找图片数量的其他线索
    // 例如：查找所有的图片占位符
    final imagePlaceholders = document.querySelectorAll('.comic-contain amp-img, .comic-contain .image-placeholder');
    if (imagePlaceholders.isNotEmpty) {
      return imagePlaceholders.length;
    }
    
    return null;
  }
}
