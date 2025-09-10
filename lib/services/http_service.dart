import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HttpService {
  static const String baseUrl = 'https://www.baozimh.com';
  static const Duration timeout = Duration(seconds: 30);
  
  static const Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
  };

  /// 创建HTTP客户端，针对不同平台进行优化
  static http.Client _createClient() {
    if (kIsWeb) {
      return http.Client();
    }
    
    // 为桌面平台创建自定义客户端
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return http.Client();
    }
    
    return http.Client();
  }

  static Future<String> get(String url) async {
    http.Client? client;
    try {
      client = _createClient();
      final response = await client.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      // 处理网络连接问题
      if (e.osError?.errorCode == 1 && Platform.isMacOS) {
        throw Exception('网络连接被拒绝，请检查macOS的网络权限设置。错误详情: $e');
      }
      throw Exception('网络连接失败: $e');
    } on HttpException catch (e) {
      throw Exception('HTTP请求失败: $e');
    } catch (e) {
      throw Exception('网络请求失败: $e');
    } finally {
      client?.close();
    }
  }

  static Future<String> post(String url, {Map<String, dynamic>? body}) async {
    http.Client? client;
    try {
      client = _createClient();
      final response = await client.post(
        Uri.parse(url),
        headers: {
          ...headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body?.map((key, value) => MapEntry(key, value.toString())),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      // 处理网络连接问题
      if (e.osError?.errorCode == 1 && Platform.isMacOS) {
        throw Exception('网络连接被拒绝，请检查macOS的网络权限设置。错误详情: $e');
      }
      throw Exception('网络连接失败: $e');
    } on HttpException catch (e) {
      throw Exception('HTTP请求失败: $e');
    } catch (e) {
      throw Exception('网络请求失败: $e');
    } finally {
      client?.close();
    }
  }

  static String buildUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '$baseUrl$path';
  }
}
