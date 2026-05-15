/// Trip Service – Gọi API thật tới .NET Core Backend
///
/// Endpoints được xử lý:
///   GET  /api/trips/search          → [searchTrips]
///   GET  /api/trips/{id}/seats      → [getAvailableSeats]
///   POST /api/trips/lock-seat       → [lockSeat]
library;

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/trip_model.dart';
import '../models/train_model.dart';
import '../models/booking_model.dart';

class TripService {
  final Dio _dio = DioClient.instance.dio;

  // ─────────────────────────────────────────────────────────────────
  // GET /api/trips/search?FromStation=&ToStation=&Date=
  //
  // BE nhận [SearchTripRequest] dưới dạng query params:
  //   FromStation: mã ga đi (vd: "HAN")
  //   ToStation:   mã ga đến (vd: "SGN")
  //   Date:        ngày dạng "yyyy-MM-dd"
  //
  // Trả về List<TripSearchResult>
  // ─────────────────────────────────────────────────────────────────
  Future<List<TripSearchResult>> searchTrips({
    required String fromStationCode,
    required String toStationCode,
    required DateTime date,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.tripsSearch,
        queryParameters: {
          'FromStation': fromStationCode,
          'ToStation': toStationCode,
          // BE dùng DateTime.TryParse → gửi "yyyy-MM-dd"
          'Date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );

      final data = response.data;
      if (data is! List) return [];

      return data
          .map((e) => TripSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(message: e.message ?? 'Lỗi tìm kiếm chuyến đi.');
    } catch (e) {
      throw AppException(message: 'Lỗi không xác định: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET /api/trips/{id}/seats
  //
  // Trả về List<CarriageWithSeats> – từng toa kèm trạng thái ghế
  // ─────────────────────────────────────────────────────────────────
  Future<List<CarriageWithSeats>> getAvailableSeats(int tripId) async {
    try {
      final response = await _dio.get(ApiConstants.tripSeats(tripId));

      final data = response.data;
      if (data is! List) return [];

      return data
          .map((e) => CarriageWithSeats.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(message: e.message ?? 'Lỗi tải sơ đồ ghế.');
    } catch (e) {
      throw AppException(message: 'Lỗi không xác định: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // POST /api/trips/lock-seat
  // Header: X-Session-Id (SessionInterceptor tự đính kèm)
  //
  // Trả về [LockSeatResponse] nếu thành công
  // Ném [AppException] nếu ghế đã bị đặt/lock (BE trả 400)
  // ─────────────────────────────────────────────────────────────────
  Future<LockSeatResponse> lockSeat({
    required int seatId,
    required int tripId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.lockSeat,
        data: LockSeatRequest(seatId: seatId, tripId: tripId).toJson(),
      );

      return LockSeatResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      // BE trả 400: "Ghế đã bị đặt hoặc đang được giữ bởi người khác."
      throw AppException(
        message: e.message ?? 'Không thể giữ ghế. Vui lòng chọn ghế khác.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AppException(message: 'Lỗi không xác định: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GET /api/admin/stations  (dùng cho StationPicker)
  // Trả về List<StationModel>
  // ─────────────────────────────────────────────────────────────────
  Future<List<StationModel>> getStations() async {
    try {
      final response = await _dio.get(ApiConstants.adminStations);
      final data = response.data;
      if (data is! List) return [];

      return data
          .map((e) => StationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final appEx = e.error;
      if (appEx is AppException) throw appEx;
      throw AppException(message: e.message ?? 'Lỗi tải danh sách ga.');
    } catch (e) {
      throw AppException(message: 'Lỗi không xác định: $e');
    }
  }
}
