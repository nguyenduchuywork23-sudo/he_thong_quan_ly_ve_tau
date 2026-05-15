/// AdminService – Kết nối tất cả Admin API endpoints
/// Yêu cầu JWT Bearer Token (AuthInterceptor tự đính kèm)
library;

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/admin_model.dart';
import '../models/trip_model.dart';

class AdminService {
  final Dio _dio = DioClient.instance.dio;

  // ── Dashboard ──────────────────────────────
  /// GET /api/admin/dashboard
  Future<DashboardStats> getDashboard() async {
    try {
      final res = await _dio.get(ApiConstants.adminDashboard);
      return DashboardStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải dashboard.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Bookings ───────────────────────────────
  /// GET /api/admin/bookings
  Future<List<AdminBooking>> getBookings({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (status != null && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final res = await _dio.get(ApiConstants.adminBookings,
          queryParameters: params);
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => AdminBooking.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Nếu response có wrapper { items: [...] }
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .map((e) => AdminBooking.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải danh sách vé.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// PUT /api/admin/bookings/{id}/status
  Future<void> updateBookingStatus(int bookingId, String status) async {
    try {
      await _dio.put(
        ApiConstants.adminBookingStatus(bookingId),
        data: UpdateBookingStatusRequest(status: status).toJson(),
      );
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể cập nhật trạng thái vé.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Stations ───────────────────────────────
  /// GET /api/admin/stations
  Future<List<StationModel>> getStations() async {
    try {
      final res = await _dio.get(ApiConstants.adminStations);
      final data = res.data;
      if (data is! List) return [];
      return data
          .map((e) => StationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải danh sách ga.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// POST /api/admin/stations
  Future<StationModel> createStation(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(ApiConstants.adminStations, data: data);
      return StationModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể thêm ga.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// PUT /api/admin/stations/{id}
  Future<StationModel> updateStation(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put(ApiConstants.adminStationById(id), data: data);
      return StationModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể cập nhật ga.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// DELETE /api/admin/stations/{id}
  Future<void> deleteStation(int id) async {
    try {
      await _dio.delete(ApiConstants.adminDeleteStation(id));
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể xóa ga.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Trains ─────────────────────────────────
  /// GET /api/admin/trains
  Future<List<Map<String, dynamic>>> getTrains() async {
    try {
      final res = await _dio.get(ApiConstants.adminTrains);
      final data = res.data;
      if (data is! List) return [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải danh sách tàu.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
