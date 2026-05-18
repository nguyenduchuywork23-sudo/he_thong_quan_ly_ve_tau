library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';


class DioClient {
  DioClient._();
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._();

  late final Dio _dio;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(prefs),
      SessionInterceptor(prefs),
      ErrorInterceptor(prefs),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[DIO] $o'),
      ),
    ]);
  }

  Dio get dio => _dio;
}


class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  AuthInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _prefs.getString(ApiConstants.keyJwtToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}


class SessionInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  static const _sessionPaths = [
    '/api/trips/lock-seat',
    '/api/bookings',
  ];

  SessionInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final needsSession = _sessionPaths.any(
      (p) => options.path.toLowerCase().contains(p),
    );

    if (needsSession) {
      String? sessionId = _prefs.getString(ApiConstants.keySessionId);
      if (sessionId == null || sessionId.isEmpty) {
        sessionId = _generateSessionId();
        _prefs.setString(ApiConstants.keySessionId, sessionId);
      }
      options.headers['X-Session-Id'] = sessionId;
    }

    handler.next(options);
  }

  String _generateSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Object().hashCode.abs();
    return 'sess-$now-$rand';
  }
}


class ErrorInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  ErrorInterceptor(this._prefs);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response == null) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: AppException(
            message: 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng.',
            statusCode: 0,
          ),
          type: err.type,
        ),
      );
      return;
    }

    if (response.statusCode == 401) {
      _prefs.remove(ApiConstants.keyJwtToken);
    }

    String message = _extractMessage(response.data, err.response?.statusCode);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        error: AppException(
          message: message,
          statusCode: response.statusCode,
        ),
        type: err.type,
      ),
    );
  }

  String _extractMessage(dynamic data, int? statusCode) {
    if (data is Map<String, dynamic>) {
      return (data['Message'] ?? data['message'] ?? data['title'] ?? _statusMessage(statusCode))
          .toString();
    }
    return _statusMessage(statusCode);
  }

  String _statusMessage(int? code) => switch (code) {
        400 => 'Dữ liệu không hợp lệ.',
        401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        403 => 'Bạn không có quyền thực hiện thao tác này.',
        404 => 'Không tìm thấy dữ liệu.',
        500 => 'Lỗi máy chủ. Vui lòng thử lại sau.',
        _ => 'Đã xảy ra lỗi không xác định.',
      };
}


class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException($statusCode): $message';
}

void debugPrint(String msg) => print(msg);
