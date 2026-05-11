import 'package:dio/dio.dart';

class HttpClient {
  late final Dio _dio;

  HttpClient({
    int connectTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
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