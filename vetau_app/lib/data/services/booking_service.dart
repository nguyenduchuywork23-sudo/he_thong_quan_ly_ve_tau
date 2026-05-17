/// Booking Service – Gọi API thật tới .NET Core Backend
///
/// Endpoints được xử lý:
///   POST /api/bookings   → [createBooking]
library;

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/booking_model.dart';

class BookingService {
  final Dio _dio = DioClient.instance.dio;

  // ─────────────────────────────────────────────────────────────────
  // POST /api/bookings
  // Header: X-Session-Id (SessionInterceptor tự đính kèm)
  //         Authorization: Bearer <token> (AuthInterceptor – nếu đã login)
  //
  // BE kiểm tra X-Session-Id có tồn tại và match SeatLock.
  // Nếu thiếu → 400: "Thiếu SessionId giữ chỗ."
  // Nếu thành công → [CreateBookingResponse] chứa bookingCode và qrCodeData
  // ─────────────────────────────────────────────────────────────────
  Future<CreateBookingResponse> createBooking(
    CreateBookingRequest request,
    String sessionId,
  ) async {
    try {
      final requestData = request.toJson();

      final response = await _dio.post(
        ApiConstants.createBooking,
        data: requestData,
      );

      return CreateBookingResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;

      // Xử lý các lỗi 400 cụ thể từ BookingsController.cs
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      String message = 'Đặt vé thất bại. Vui lòng thử lại.';

      if (body is Map<String, dynamic>) {
        message = body['Message'] as String? ??
            body['message'] as String? ??
            message;
      }

      throw AppException(message: message, statusCode: statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi không xác định khi đặt vé: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET /api/bookings/my-bookings
  // Lấy danh sách lịch sử vé của người dùng đã đăng nhập.
  // Trả về List<Booking> (chuyển thành Map để xử lý)
  // ─────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    try {
      final response = await _dio.get(ApiConstants.myBookings);
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: 'Lỗi tải danh sách vé. Vui lòng thử lại.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Lỗi không xác định khi tải lịch sử vé.');
    }
  }
}
