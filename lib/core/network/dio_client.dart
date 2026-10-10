import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_constants.dart';

/// Fired whenever a request comes back 401 (expired/invalid token).
/// The router listens to this to force a redirect to /login.
typedef UnauthorizedCallback = void Function();

class DioClient {
  DioClient({this._onUnauthorized}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Never send a (possibly stale) token to the public auth endpoints.
          final isAuthCall = options.path.startsWith('/auth/');
          final token =
              isAuthCall ? null : await SecureStorageService.instance.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (_isSessionRejected(error)) {
            await SecureStorageService.instance.clear();
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Spring Security answers a missing/invalid/expired JWT with an
  /// empty-body 403 (not 401), while real application errors always carry a
  /// JSON `{message, ...}` body. Treat both as "session no longer valid",
  /// except on the public /auth endpoints.
  static bool _isSessionRejected(DioException error) {
    if (error.requestOptions.path.startsWith('/auth/')) return false;
    final response = error.response;
    if (response == null) return false;
    if (response.statusCode == 401) return true;
    if (response.statusCode == 403) {
      final data = response.data;
      return data == null || (data is String && data.isEmpty) || data is! Map;
    }
    return false;
  }

  late final Dio dio;
  final UnauthorizedCallback? _onUnauthorized;
}
