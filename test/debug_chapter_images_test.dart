import 'package:flutter_test/flutter_test.dart';
import 'package:baozi_comic/services/comic_service.dart';
import 'package:baozi_comic/utils/debug_helper.dart';

/// 调试测试 - 用于诊断章节图片加载问题
/// 
/// 运行方式: flutter test test/debug_chapter_images_test.dart
void main() {
  group('章节图片调试测试', () {
    test('测试获取章节图片 - 第246话', () async {
      const comicId = 'silingfashiwojishitianzai-mantudezhuyuanzhuheiniaoshe_rjogsq';
      const chapterId = '246';
      
      print('\n开始测试获取章节图片...');
      print('漫画ID: $comicId');
      print('章节ID: $chapterId');
      
      final result = await ComicService.getChapterImages(comicId, chapterId);
      
      if (result.isSuccess && result.data != null) {
        print('\n✅ 成功获取 ${result.data!.length} 张图片');
        print('\n前5张图片URL:');
        for (int i = 0; i < result.data!.length && i < 5; i++) {
          print('  ${i + 1}. ${result.data![i]}');
        }
        
        // 测试第一张图片是否可访问
        if (result.data!.isNotEmpty) {
          print('\n测试第一张图片是否可访问...');
          await DebugHelper.testImageUrl(result.data!.first);
        }
      } else {
        print('\n❌ 获取图片失败: ${result.message}');
      }
    });
    
    test('测试获取章节详情 - 第246话', () async {
      const comicId = 'silingfashiwojishitianzai-mantudezhuyuanzhuheiniaoshe_rjogsq';
      const chapterId = '246';
      
      print('\n开始测试获取章节详情...');
      
      final result = await ComicService.getChapterDetail(comicId, chapterId);
      
      if (result.isSuccess && result.data != null) {
        final chapter = result.data!;
        print('\n✅ 成功获取章节详情');
        print('章节标题: ${chapter.title}');
        print('当前页: ${chapter.currentPage}');
        print('总页数: ${chapter.totalPages}');
        print('图片数量: ${chapter.imageUrls?.length ?? 0}');
        print('图片对象数量: ${chapter.images?.length ?? 0}');
        
        if (chapter.imageUrls != null && chapter.imageUrls!.isNotEmpty) {
          print('\n前3张图片URL:');
          for (int i = 0; i < chapter.imageUrls!.length && i < 3; i++) {
            print('  ${i + 1}. ${chapter.imageUrls![i]}');
          }
        }
        
        if (chapter.images != null && chapter.images!.isNotEmpty) {
          print('\n前3张图片详情:');
          for (int i = 0; i < chapter.images!.length && i < 3; i++) {
            final img = chapter.images![i];
            print('  ${i + 1}. ${img.width}x${img.height} - ${img.url}');
          }
        }
      } else {
        print('\n❌ 获取章节详情失败: ${result.message}');
      }
    });
  });
}
