library;

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/trip_model.dart';
import '../models/train_model.dart';
import '../models/booking_model.dart';

class TripService {
  final Dio _dio = DioClient.instance.dio;

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
      throw AppException(
        message: e.message ?? 'Không thể giữ ghế. Vui lòng chọn ghế khác.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AppException(message: 'Lỗi không xác định: $e');
    }
  }

  Future<List<StationModel>> getStations() async {
    try {
      final response = await _dio.get(ApiConstants.tripsStations);
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
