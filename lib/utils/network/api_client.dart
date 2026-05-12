import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;
  final String baseUrl;

  ApiClient({
    required this.baseUrl,
    Map<String, String>? headers,
    int? connectTimeout,
    int? receiveTimeout,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(milliseconds: connectTimeout ?? 30000),
          receiveTimeout: Duration(milliseconds: receiveTimeout ?? 30000),
          headers: headers ?? {'Content-Type': 'application/json'},
        ));

  Dio get dio => _dio;

  void setAuth(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void setHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  void clearAuth() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final options = Options(headers: headers);
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final options = Options(headers: headers);
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Map<String, String>? headers}) async {
    final options = Options(headers: headers);
    return _dio.put(path, data: data, options: options);
  }

  Future<Response> delete(String path, {Map<String, String>? headers}) async {
    final options = Options(headers: headers);
    return _dio.delete(path, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, String>? headers}) async {
    final options = Options(headers: headers);
    return _dio.patch(path, data: data, options: options);
  }
}