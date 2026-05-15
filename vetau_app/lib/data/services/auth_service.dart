/// Auth Service – Gọi API đăng nhập .NET Core
library;

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  final Dio _dio = DioClient.instance.dio;

  /// POST /api/auth/login
  /// Trả về Map { "Token": "...", "User": { ... } }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'Email': email, 'Password': password},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Đăng nhập thất bại.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi không xác định khi đăng nhập.');
    }
  }
  /// POST /api/auth/register
  /// Trả về Map { "Token": "...", "User": { ... } }
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'Email': email,
          'Password': password,
          'FullName': fullName,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.response?.data?['Message'] ?? e.message ?? 'Đăng ký thất bại.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi không xác định khi đăng ký.');
    }
  }
}
