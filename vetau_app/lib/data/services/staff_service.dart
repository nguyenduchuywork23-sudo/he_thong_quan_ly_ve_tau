/// StaffService – Kết nối tất cả Staff API endpoints
/// Yêu cầu JWT Bearer Token (role = admin | staff)
/// AuthInterceptor tự đính kèm token vào mọi request.
library;

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

// ─── Data models nội bộ (chỉ dùng trong Staff layer) ────────────────────────

class StaffDashboardStats {
  final int pendingBookings;
  final int confirmedToday;
  final int cancelledToday;
  final int totalPassengersToday;
  final int activeTrips;
  final double revenueToday;

  const StaffDashboardStats({
    required this.pendingBookings,
    required this.confirmedToday,
    required this.cancelledToday,
    required this.totalPassengersToday,
    required this.activeTrips,
    required this.revenueToday,
  });

  factory StaffDashboardStats.fromJson(Map<String, dynamic> json) {
    return StaffDashboardStats(
      pendingBookings: (json['pendingBookings'] as num?)?.toInt() ?? 0,
      confirmedToday: (json['confirmedToday'] as num?)?.toInt() ?? 0,
      cancelledToday: (json['cancelledToday'] as num?)?.toInt() ?? 0,
      totalPassengersToday:
          (json['totalPassengersToday'] as num?)?.toInt() ?? 0,
      activeTrips: (json['activeTrips'] as num?)?.toInt() ?? 0,
      revenueToday: (json['revenueToday'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PassengerStats {
  final int totalPassengers;
  final int onBoardCount;
  final int waitingCount;

  const PassengerStats({
    required this.totalPassengers,
    required this.onBoardCount,
    required this.waitingCount,
  });

  factory PassengerStats.fromJson(Map<String, dynamic> json) {
    return PassengerStats(
      totalPassengers: (json['totalPassengers'] as num?)?.toInt() ?? 0,
      onBoardCount: (json['onBoardCount'] as num?)?.toInt() ?? 0,
      waitingCount: (json['waitingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ActiveTrip {
  final int id;
  final String trainName;
  final String fromStation;
  final String toStation;
  final String departureTime;
  final String arrivalTime;
  final String status;
  final int passengerCount;

  const ActiveTrip({
    required this.id,
    required this.trainName,
    required this.fromStation,
    required this.toStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.status,
    required this.passengerCount,
  });

  factory ActiveTrip.fromJson(Map<String, dynamic> json) {
    return ActiveTrip(
      id: (json['id'] as num?)?.toInt() ?? 0,
      trainName: json['trainName'] as String? ?? '',
      fromStation: json['fromStation'] as String? ?? '',
      toStation: json['toStation'] as String? ?? '',
      departureTime: json['departureTime'] as String? ?? '',
      arrivalTime: json['arrivalTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      passengerCount: (json['passengerCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class StaffService {
  final Dio _dio = DioClient.instance.dio;

  // ── Dashboard ──────────────────────────────────────────────────────
  /// GET /api/Staff/dashboard
  Future<StaffDashboardStats> getDashboard() async {
    try {
      final res = await _dio.get(ApiConstants.staffDashboard);
      return StaffDashboardStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải dashboard nhân viên.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Pending Bookings ────────────────────────────────────────────────
  /// GET /api/Staff/pending-bookings
  /// Trả về raw List<Map> để tương thích với AdminBooking.fromJson
  Future<List<Map<String, dynamic>>> getPendingBookings() async {
    try {
      final res = await _dio.get(ApiConstants.staffPendingBookings);
      final data = res.data;
      if (data is List) {
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải danh sách đơn chờ duyệt.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Approve Booking ─────────────────────────────────────────────────
  /// PUT /api/Staff/bookings/{id}/approve
  Future<void> approveBooking(int bookingId) async {
    try {
      await _dio.put(ApiConstants.staffApproveBooking(bookingId));
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.response?.data?['Message'] as String? ??
            e.message ??
            'Không thể duyệt đơn vé.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Reject Booking ──────────────────────────────────────────────────
  /// PUT /api/Staff/bookings/{id}/reject
  /// [reason] là lý do từ chối (tùy chọn)
  Future<void> rejectBooking(int bookingId, {String? reason}) async {
    try {
      await _dio.put(
        ApiConstants.staffRejectBooking(bookingId),
        data: reason != null ? {'Reason': reason} : null,
      );
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.response?.data?['Message'] as String? ??
            e.message ??
            'Không thể từ chối đơn vé.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Passenger Stats ─────────────────────────────────────────────────
  /// GET /api/Staff/passenger-stats
  Future<PassengerStats> getPassengerStats() async {
    try {
      final res = await _dio.get(ApiConstants.staffPassengerStats);
      return PassengerStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải thống kê hành khách.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── Active Trips ────────────────────────────────────────────────────
  /// GET /api/Staff/active-trips
  Future<List<ActiveTrip>> getActiveTrips() async {
    try {
      final res = await _dio.get(ApiConstants.staffActiveTrips);
      final data = res.data;
      if (data is! List) return [];
      return data
          .map((e) => ActiveTrip.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(
        message: e.message ?? 'Không thể tải danh sách chuyến đang chạy.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
