import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiHost,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('🚀 PETICIÓN [${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ RESPUESTA [${response.statusCode}] <= ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
              '❌ ERROR [${e.response?.statusCode}] <= ${e.requestOptions.path}');
          debugPrint('💬 MENSAJE: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
