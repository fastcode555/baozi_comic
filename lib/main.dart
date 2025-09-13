import 'package:baozi_comic/routes/routes.dart';
import 'package:baozi_comic/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  await initServices();

  runApp(const BaoziComicApp());
}

Future<void> initServices() async {
  // 初始化存储服务
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService);

  // 初始化其他服务
  Get.put(HttpService());
  Get.put(ParserService());
  Get.put(ComicService());
}

class BaoziComicApp extends StatelessWidget {
  const BaoziComicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // 设计稿的尺寸
      minTextAdapt: true, // 自动适配文字大小
      splitScreenMode: true, // 支持分屏模式
      builder: (_,__){
        return GetMaterialApp(
          title: '包子漫画',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.amber,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFD700), // 金黄色
            ),
            scaffoldBackgroundColor: Colors.grey[50],
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFD700), // 金黄色AppBar
              foregroundColor: Colors.black87,
              elevation: 2,
              shadowColor: Colors.black26,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                elevation: 2,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFFFD700),
              foregroundColor: Colors.black87,
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: Color(0xFFFFD700),
            ),
            useMaterial3: true,
          ),
          initialRoute: AppRoutes.initial,
          getPages: AppPages.pages,
        );
      }
    );
  }
}
