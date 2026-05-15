/// AdminProvider – State Management cho Admin Panel
library;

import 'package:flutter/foundation.dart';
import '../../data/models/admin_model.dart';
import '../../data/models/trip_model.dart';
import '../../data/services/admin_service.dart';
import '../../core/network/dio_client.dart';

enum AdminLoadState { idle, loading, loaded, error }

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  // ── Dashboard ──────────────────────────────
  AdminLoadState _dashState = AdminLoadState.idle;
  DashboardStats? _stats;
  String? _dashError;

  // ── Bookings ───────────────────────────────
  AdminLoadState _bookingsState = AdminLoadState.idle;
  List<AdminBooking> _bookings = [];
  String? _bookingsError;
  String _statusFilter = 'all'; // all | Pending | Confirmed | Cancelled
  String _searchQuery = '';

  // ── Update status ──────────────────────────
  bool _isUpdating = false;
  String? _updateError;

  // ── Stations ───────────────────────────────
  AdminLoadState _stationsState = AdminLoadState.idle;
  List<StationModel> _stations = [];
  bool _isStationOp = false;   // create / update / delete in progress
  String? _stationOpError;

  // ── Trains ─────────────────────────────────
  AdminLoadState _trainsState = AdminLoadState.idle;
  List<Map<String, dynamic>> _trains = [];
  String? _trainsError;


  // ─── Getters ──────────────────────────────
  AdminLoadState get dashState => _dashState;
  DashboardStats? get stats => _stats;
  String? get dashError => _dashError;
  bool get isDashLoading => _dashState == AdminLoadState.loading;

  AdminLoadState get bookingsState => _bookingsState;
  List<AdminBooking> get bookings => _filteredBookings();
  List<AdminBooking> get allBookings => List.unmodifiable(_bookings);
  String? get bookingsError => _bookingsError;
  bool get isBookingsLoading => _bookingsState == AdminLoadState.loading;

  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;

  AdminLoadState get stationsState => _stationsState;
  List<StationModel> get stations => List.unmodifiable(_stations);
  bool get isStationOp => _isStationOp;
  String? get stationOpError => _stationOpError;

  AdminLoadState get trainsState => _trainsState;
  List<Map<String, dynamic>> get trains => List.unmodifiable(_trains);
  String? get trainsError => _trainsError;

  // ─── Filter bookings locally ───────────────
  List<AdminBooking> _filteredBookings() {
    var list = _bookings;
    if (_statusFilter != 'all') {
      list = list.where((b) =>
          b.status.toLowerCase() == _statusFilter.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) =>
          b.bookingCode.toLowerCase().contains(q) ||
          b.passengerName.toLowerCase().contains(q) ||
          b.passengerPhone.contains(q)).toList();
    }
    return list;
  }

  // ════════════════════════════════════════════
  // ACTIONS – DASHBOARD
  // ════════════════════════════════════════════
  Future<void> loadDashboard({bool force = false}) async {
    if (_dashState == AdminLoadState.loaded && !force) return;
    _dashState = AdminLoadState.loading;
    _dashError = null;
    notifyListeners();
    try {
      _stats = await _service.getDashboard();
      _dashState = AdminLoadState.loaded;
    } on AppException catch (e) {
      _dashError = e.message;
      _dashState = AdminLoadState.error;
    } catch (e) {
      _dashError = 'Lỗi tải dashboard: $e';
      _dashState = AdminLoadState.error;
    }
    notifyListeners();
  }

  // ════════════════════════════════════════════
  // ACTIONS – BOOKINGS
  // ════════════════════════════════════════════
  Future<void> loadBookings({bool force = false}) async {
    if (_bookingsState == AdminLoadState.loaded && !force) return;
    _bookingsState = AdminLoadState.loading;
    _bookingsError = null;
    notifyListeners();
    try {
      _bookings = await _service.getBookings();
      _bookingsState = AdminLoadState.loaded;
    } on AppException catch (e) {
      _bookingsError = e.message;
      _bookingsState = AdminLoadState.error;
    } catch (e) {
      _bookingsError = 'Lỗi tải danh sách vé: $e';
      _bookingsState = AdminLoadState.error;
    }
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// PUT /api/admin/bookings/{id}/status
  /// Trả về true nếu thành công, false nếu lỗi
  Future<bool> updateBookingStatus(int bookingId, String newStatus) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();
    try {
      await _service.updateBookingStatus(bookingId, newStatus);
      // Cập nhật local state ngay (optimistic update)
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) {
        final old = _bookings[idx];
        _bookings[idx] = AdminBooking(
          id: old.id,
          bookingCode: old.bookingCode,
          passengerName: old.passengerName,
          passengerIdCard: old.passengerIdCard,
          passengerPhone: old.passengerPhone,
          passengerEmail: old.passengerEmail,
          passengerType: old.passengerType,
          paymentMethod: old.paymentMethod,
          status: newStatus,           // ← cập nhật
          totalPrice: old.totalPrice,
          createdAt: old.createdAt,
          paymentDeadline: old.paymentDeadline,
          qrCodeData: old.qrCodeData,
          trainName: old.trainName,
          fromStation: old.fromStation,
          toStation: old.toStation,
          departureTime: old.departureTime,
          arrivalTime: old.arrivalTime,
          departureDate: old.departureDate,
          seatNumber: old.seatNumber,
          carriageType: old.carriageType,
          tripId: old.tripId,
        );
      }
      _isUpdating = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _updateError = e.message;
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _updateError = 'Lỗi cập nhật trạng thái: $e';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════
  // ACTIONS – STATIONS CRUD
  // ════════════════════════════════════════════
  Future<void> loadStations({bool force = false}) async {
    if (_stationsState == AdminLoadState.loaded && !force) return;
    _stationsState = AdminLoadState.loading;
    notifyListeners();
    try {
      _stations = await _service.getStations();
      _stationsState = AdminLoadState.loaded;
    } on AppException catch (e) {
      _stationOpError = e.message;
      _stationsState = AdminLoadState.error;
    } catch (e) {
      _stationOpError = 'Lỗi tải danh sách ga: $e';
      _stationsState = AdminLoadState.error;
    }
    notifyListeners();
  }

  /// Tạo ga mới. Trả về null nếu thành công, String lỗi nếu thất bại.
  Future<String?> createStation({
    required String name,
    required String code,
    String? city,
    String? province,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    _isStationOp = true;
    _stationOpError = null;
    notifyListeners();
    try {
      final station = await _service.createStation({
        'Name': name.trim(),
        'Code': code.trim().toUpperCase(),
        'City': city?.trim(),
        'Province': province?.trim(),
        'SortOrder': sortOrder,
        'IsActive': isActive,
      });
      _stations.add(station);
      _stations.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _isStationOp = false;
      notifyListeners();
      return null; // thành công
    } on AppException catch (e) {
      _stationOpError = e.message;
      _isStationOp = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _stationOpError = 'Lỗi không xác định: $e';
      _isStationOp = false;
      notifyListeners();
      return _stationOpError;
    }
  }

  /// Cập nhật ga. Trả về null nếu thành công, String lỗi nếu thất bại.
  Future<String?> updateStation(
    int id, {
    required String name,
    required String code,
    String? city,
    String? province,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    _isStationOp = true;
    _stationOpError = null;
    notifyListeners();
    try {
      final updated = await _service.updateStation(id, {
        'Name': name.trim(),
        'Code': code.trim().toUpperCase(),
        'City': city?.trim(),
        'Province': province?.trim(),
        'SortOrder': sortOrder,
        'IsActive': isActive,
      });
      final idx = _stations.indexWhere((s) => s.id == id);
      if (idx != -1) _stations[idx] = updated;
      _isStationOp = false;
      notifyListeners();
      return null;
    } on AppException catch (e) {
      _stationOpError = e.message;
      _isStationOp = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _stationOpError = 'Lỗi không xác định: $e';
      _isStationOp = false;
      notifyListeners();
      return _stationOpError;
    }
  }

  /// Xóa ga. Trả về null nếu thành công, String lỗi nếu thất bại.
  Future<String?> deleteStation(int id) async {
    _isStationOp = true;
    _stationOpError = null;
    notifyListeners();
    try {
      await _service.deleteStation(id);
      _stations.removeWhere((s) => s.id == id);
      _isStationOp = false;
      notifyListeners();
      return null;
    } on AppException catch (e) {
      _stationOpError = e.message;
      _isStationOp = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _stationOpError = 'Lỗi không xác định: $e';
      _isStationOp = false;
      notifyListeners();
      return _stationOpError;
    }
  }

  void clearStationOpError() {
    _stationOpError = null;
    notifyListeners();
  }

  // ════════════════════════════════════════════
  // ACTIONS – TRAINS
  // ════════════════════════════════════════════
  Future<void> loadTrains({bool force = false}) async {
    if (_trainsState == AdminLoadState.loaded && !force) return;
    _trainsState = AdminLoadState.loading;
    _trainsError = null;
    notifyListeners();
    try {
      _trains = await _service.getTrains();
      _trainsState = AdminLoadState.loaded;
    } on AppException catch (e) {
      _trainsError = e.message;
      _trainsState = AdminLoadState.error;
    } catch (e) {
      _trainsError = 'Lỗi tải danh sách tàu: $e';
      _trainsState = AdminLoadState.error;
    }
    notifyListeners();
  }

  void clearUpdateError() {
    _updateError = null;
    notifyListeners();
  }

  void refreshAll() {
    loadDashboard(force: true);
    loadBookings(force: true);
  }
}
