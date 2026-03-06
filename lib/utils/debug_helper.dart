import 'dart:io';
import 'package:html/parser.dart' as html_parser;

/// 调试辅助工具 - 用于诊断图片加载问题
class DebugHelper {
  /// 分析章节HTML内容，输出详细的调试信息
  static void analyzeChapterHtml(String htmlContent, String chapterId) {
    print('\n========== 章节 $chapterId HTML 分析 ==========');
    print('HTML 内容长度: ${htmlContent.length} 字符');
    
    final document = html_parser.parse(htmlContent);
    
    // 1. 检查标题
    final titleElement = document.querySelector('.text .title') ?? 
                        document.querySelector('.title');
    print('\n标题: ${titleElement?.text.trim() ?? "未找到"}');
    
    // 2. 检查所有 amp-img 标签
    final ampImgs = document.querySelectorAll('amp-img');
    print('\n找到 ${ampImgs.length} 个 amp-img 标签');
    
    for (int i = 0; i < ampImgs.length && i < 5; i++) {
      final img = ampImgs[i];
      print('\namp-img #$i 属性:');
      img.attributes.forEach((key, value) {
        print('  $key: ${value.length > 100 ? value.substring(0, 100) + "..." : value}');
      });
    }
    
    // 3. 检查 script 标签
    final scripts = document.querySelectorAll('script');
    print('\n找到 ${scripts.length} 个 script 标签');
    
    int scriptWithImages = 0;
    for (final script in scripts) {
      if (script.text.contains('baozicdn.com') || 
          script.text.contains('imageUrls') ||
          script.text.contains('__NUXT__') ||
          script.text.contains('window.__data')) {
        scriptWithImages++;
        print('\nScript 标签包含图片相关数据:');
        final content = script.text;
        if (content.length > 500) {
          print('  ${content.substring(0, 500)}...');
        } else {
          print('  $content');
        }
      }
    }
    print('\n包含图片数据的 script 标签数量: $scriptWithImages');
    
    // 4. 检查是否有图片URL模式
    final urlPattern = RegExp(r'https?://[^"\s]+?baozicdn\.com[^"\s]+?\.(?:jpg|jpeg|png|webp|gif)', caseSensitive: false);
    final matches = urlPattern.allMatches(htmlContent);
    print('\n通过正则表达式找到 ${matches.length} 个可能的图片URL');
    
    if (matches.isNotEmpty) {
      print('\n前3个图片URL示例:');
      int count = 0;
      for (final match in matches) {
        if (count >= 3) break;
        print('  ${match.group(0)}');
        count++;
      }
    }
    
    // 5. 检查其他可能的图片容器
    final imageContainers = document.querySelectorAll('.comic-contain, .image-container, .chapter-images');
    print('\n找到 ${imageContainers.length} 个可能的图片容器');
    
    print('\n========== 分析完成 ==========\n');
  }
  
  /// 将HTML内容保存到文件以便检查
  static Future<void> saveHtmlToFile(String htmlContent, String filename) async {
    try {
      final file = File('debug_$filename.html');
      await file.writeAsString(htmlContent);
      print('HTML 内容已保存到: ${file.path}');
    } catch (e) {
      print('保存HTML文件失败: $e');
    }
  }
  
  /// 测试图片URL是否可访问
  static Future<bool> testImageUrl(String url) async {
    try {
      final client = HttpClient();
      final request = await client.headUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36');
      final response = await request.close();
      final accessible = response.statusCode == 200;
      print('图片URL测试 [$url]: ${accessible ? "可访问" : "不可访问 (${response.statusCode})"}');
      client.close();
      return accessible;
    } catch (e) {
      print('图片URL测试失败 [$url]: $e');
      return false;
    }
  }
}
