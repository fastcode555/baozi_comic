import 'package:get/get.dart';
import '../pages/home_page.dart';
import '../pages/search_page.dart';
import '../pages/comic_detail_page.dart';
import '../pages/reader_page.dart';
import '../pages/bookshelf_page.dart';
import '../controllers/controllers.dart';
import 'app_routes.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.initial,
      page: () => const HomePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SearchController>(() => SearchController());
      }),
    ),
    GetPage(
      name: AppRoutes.comic,
      page: () => const ComicDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ComicDetailController>(() => ComicDetailController());
      }),
    ),
    GetPage(
      name: AppRoutes.reader,
      page: () => const ReaderPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ReaderController>(() => ReaderController());
      }),
    ),
    GetPage(
      name: AppRoutes.bookshelf,
      page: () => const BookshelfPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BookshelfController>(() => BookshelfController());
      }),
    ),
  ];
}
