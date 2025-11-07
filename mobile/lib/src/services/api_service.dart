import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config_service.dart';

class ApiService {
  late final Dio dio;
  final storage = const FlutterSecureStorage();

  ApiService() {
    // Start with the cached URL synchronously to avoid hitting an invalid default
    // before async storage finishes loading.
    final initialBase = ConfigService.I.getCachedBaseUrlSync();
    dio = Dio(BaseOptions(
      baseUrl: initialBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Load persisted base URL (if any) and apply at runtime
    _applyStoredBaseUrl();

    // Add interceptor to automatically add token to requests
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from storage and add to header
        final token = await storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('🔵 REQUEST[${options.method}] => ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print(
            '❌ ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}');
        print('   Message: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  Future<void> _applyStoredBaseUrl() async {
    try {
      final url = await ConfigService.I.getApiBaseUrl();
      if (url.isNotEmpty && dio.options.baseUrl != url) {
        dio.options.baseUrl = url;
        print('⚙️ ApiService baseUrl set to: ${dio.options.baseUrl}');
      }
    } catch (e) {
      print('⚠️ Failed to load stored base URL: $e');
    }
  }

  void setToken(String? token) {
    if (token == null) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Updates the base URL at runtime (e.g., after changing server settings).
  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
    print('🔧 ApiService baseUrl updated to: ${dio.options.baseUrl}');
  }

  String get baseUrl => dio.options.baseUrl;
}
