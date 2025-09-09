import 'dart:io';
import 'package:http/http.dart' as http;

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

  static Future<String> get(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  static Future<String> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
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
    } catch (e) {
      throw Exception('Network request failed: $e');
    }
  }

  static String buildUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    return '$baseUrl$path';
  }
}
