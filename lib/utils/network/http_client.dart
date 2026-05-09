import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

class HttpClient {
  late final Dio _dio;

  HttpClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: AppConfig.connectionTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Dio get dio => _dio;

  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  void clearHeaders() {
    _dio.options.headers.clear();
  }

  HttpClient._();
}

final httpClient = HttpClient._();