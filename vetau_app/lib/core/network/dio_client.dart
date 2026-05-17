/// Dio HTTP Client – Network Layer duy nhất của app
///
/// Interceptors:
///   [AuthInterceptor]    – Tự động đính kèm JWT Bearer Token
///   [SessionInterceptor] – Tự động đính kèm X-Session-Id
///   [ErrorInterceptor]   – Chuẩn hóa lỗi từ .NET Core response
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

// ═══════════════════════════════════════════════
// DIO CLIENT SINGLETON
// ═══════════════════════════════════════════════

class DioClient {
  DioClient._();
  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._();

  late final Dio _dio;

  /// Khởi tạo Dio và gắn interceptors.
  /// Phải gọi [init()] trong main() trước khi dùng [dio].
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

// ═══════════════════════════════════════════════
// INTERCEPTOR 1: JWT AUTH
// Tự động thêm "Authorization: Bearer <token>" nếu đã đăng nhập
// ═══════════════════════════════════════════════

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

// ═══════════════════════════════════════════════
// INTERCEPTOR 2: X-SESSION-ID
// Tự động đính kèm X-Session-Id cho các endpoint:
//   - POST /api/trips/lock-seat
//   - POST /api/bookings
// Nếu chưa có session, tự sinh UUID và lưu vào SharedPreferences
// ═══════════════════════════════════════════════

class SessionInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  /// Danh sách path cần X-Session-Id (khớp với logic Controller C#)
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
      // Lấy session hiện tại hoặc sinh mới
      String? sessionId = _prefs.getString(ApiConstants.keySessionId);
      if (sessionId == null || sessionId.isEmpty) {
        sessionId = _generateSessionId();
        _prefs.setString(ApiConstants.keySessionId, sessionId);
      }
      options.headers['X-Session-Id'] = sessionId;
    }

    handler.next(options);
  }

  /// Sinh UUID v4 đơn giản không cần package bên ngoài
  String _generateSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Object().hashCode.abs();
    return 'sess-$now-$rand';
  }
}

// ═══════════════════════════════════════════════
// INTERCEPTOR 3: ERROR HANDLER
// Chuẩn hóa lỗi từ .NET Core (BadRequest, Unauthorized, NotFound…)
// thành [AppException] có thể hiển thị trực tiếp cho user
// ═══════════════════════════════════════════════

class ErrorInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  ErrorInterceptor(this._prefs);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    // Không có response = network error
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
      // Có thể thêm báo hiệu logout ở đây (VD dùng global event bus)
    }

    // Lấy message từ body .NET Core (format: { "message": "..." })
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
      // .NET Core trả về { "Message": "..." } hoặc { "message": "..." }
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

// ═══════════════════════════════════════════════
// APP EXCEPTION
// Lỗi có cấu trúc – Provider sẽ catch và hiển thị lên UI
// ═══════════════════════════════════════════════

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException($statusCode): $message';
}

// ignore: avoid_print
void debugPrint(String msg) => print(msg);
