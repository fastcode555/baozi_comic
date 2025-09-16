import 'package:baozi_comic/controllers/controllers.dart';
import 'package:baozi_comic/pages/bookshelf_page.dart';
import 'package:baozi_comic/pages/comic_detail_page.dart';
import 'package:baozi_comic/pages/home_page.dart';
import 'package:baozi_comic/pages/reader_page.dart';
import 'package:baozi_comic/pages/search_page.dart';
import 'package:baozi_comic/routes/app_routes.dart';
import 'package:get/get.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.initial,
      page: HomePage.new,
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(HomeController.new);
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: HomePage.new,
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(HomeController.new);
      }),
    ),
    GetPage(
      name: AppRoutes.search,
      page: SearchPage.new,
      binding: BindingsBuilder(() {
        Get.lazyPut<SearchController>(SearchController.new);
      }),
    ),
    GetPage(
      name: AppRoutes.comic,
      page: ComicDetailPage.new,
      binding: BindingsBuilder(() {
        Get.lazyPut<ComicDetailController>(ComicDetailController.new);
      }),
    ),
    GetPage(
      name: AppRoutes.reader,
      page: ReaderPage.new,
      binding: BindingsBuilder(() {
        Get.lazyPut<ReaderController>(ReaderController.new);
      }),
    ),
    GetPage(
      name: AppRoutes.bookshelf,
      page: BookshelfPage.new,
      binding: BindingsBuilder(() {
        Get.lazyPut<BookshelfController>(BookshelfController.new);
      }),
    ),
  ];
}
