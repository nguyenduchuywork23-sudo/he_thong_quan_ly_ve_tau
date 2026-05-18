library;

import 'package:flutter/foundation.dart';
import '../../data/services/staff_service.dart';
import '../../core/network/dio_client.dart';

enum StaffLoadState { idle, loading, loaded, error }

class StaffProvider extends ChangeNotifier {
  final StaffService _service = StaffService();

  StaffLoadState _dashState = StaffLoadState.idle;
  StaffDashboardStats? _dashStats;
  String? _dashError;

  StaffLoadState _pendingState = StaffLoadState.idle;
  List<Map<String, dynamic>> _pendingBookings = [];
  String? _pendingError;

  bool _isActing = false;
  String? _actError;

  StaffLoadState _statsState = StaffLoadState.idle;
  PassengerStats? _passengerStats;
  String? _statsError;

  StaffLoadState _tripsState = StaffLoadState.idle;
  List<ActiveTrip> _activeTrips = [];
  String? _tripsError;

  StaffLoadState get dashState => _dashState;
  StaffDashboardStats? get dashStats => _dashStats;
  String? get dashError => _dashError;
  bool get isDashLoading => _dashState == StaffLoadState.loading;

  StaffLoadState get pendingState => _pendingState;
  List<Map<String, dynamic>> get pendingBookings =>
      List.unmodifiable(_pendingBookings);
  String? get pendingError => _pendingError;
  bool get isPendingLoading => _pendingState == StaffLoadState.loading;

  bool get isActing => _isActing;
  String? get actError => _actError;

  StaffLoadState get statsState => _statsState;
  PassengerStats? get passengerStats => _passengerStats;
  String? get statsError => _statsError;

  StaffLoadState get tripsState => _tripsState;
  List<ActiveTrip> get activeTrips => List.unmodifiable(_activeTrips);
  String? get tripsError => _tripsError;

  Future<void> loadDashboard({bool force = false}) async {
    if (_dashState == StaffLoadState.loaded && !force) return;
    _dashState = StaffLoadState.loading;
    _dashError = null;
    notifyListeners();
    try {
      _dashStats = await _service.getDashboard();
      _dashState = StaffLoadState.loaded;
    } on AppException catch (e) {
      _dashError = e.message;
      _dashState = StaffLoadState.error;
    } catch (e) {
      _dashError = 'Lỗi tải dashboard: $e';
      _dashState = StaffLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadPendingBookings({bool force = false}) async {
    if (_pendingState == StaffLoadState.loaded && !force) return;
    _pendingState = StaffLoadState.loading;
    _pendingError = null;
    notifyListeners();
    try {
      _pendingBookings = await _service.getPendingBookings();
      _pendingState = StaffLoadState.loaded;
    } on AppException catch (e) {
      _pendingError = e.message;
      _pendingState = StaffLoadState.error;
    } catch (e) {
      _pendingError = 'Lỗi tải danh sách chờ duyệt: $e';
      _pendingState = StaffLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> approveBooking(int bookingId) async {
    _isActing = true;
    _actError = null;
    notifyListeners();
    try {
      await _service.approveBooking(bookingId);
      _pendingBookings.removeWhere((b) => (b['id'] as int?) == bookingId);
      _isActing = false;
      notifyListeners();
      loadDashboard(force: true);
      loadPendingBookings(force: true);
      return true;
    } on AppException catch (e) {
      _actError = e.message;
      _isActing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actError = 'Lỗi duyệt đơn vé: $e';
      _isActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBooking(int bookingId, {String? reason}) async {
    _isActing = true;
    _actError = null;
    notifyListeners();
    try {
      await _service.rejectBooking(bookingId, reason: reason);
      _pendingBookings.removeWhere((b) => (b['id'] as int?) == bookingId);
      _isActing = false;
      notifyListeners();
      loadDashboard(force: true);
      loadPendingBookings(force: true);
      return true;
    } on AppException catch (e) {
      _actError = e.message;
      _isActing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _actError = 'Lỗi từ chối đơn vé: $e';
      _isActing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPassengerStats({bool force = false}) async {
    if (_statsState == StaffLoadState.loaded && !force) return;
    _statsState = StaffLoadState.loading;
    _statsError = null;
    notifyListeners();
    try {
      _passengerStats = await _service.getPassengerStats();
      _statsState = StaffLoadState.loaded;
    } on AppException catch (e) {
      _statsError = e.message;
      _statsState = StaffLoadState.error;
    } catch (e) {
      _statsError = 'Lỗi tải thống kê hành khách: $e';
      _statsState = StaffLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadActiveTrips({bool force = false}) async {
    if (_tripsState == StaffLoadState.loaded && !force) return;
    _tripsState = StaffLoadState.loading;
    _tripsError = null;
    notifyListeners();
    try {
      _activeTrips = await _service.getActiveTrips();
      _tripsState = StaffLoadState.loaded;
    } on AppException catch (e) {
      _tripsError = e.message;
      _tripsState = StaffLoadState.error;
    } catch (e) {
      _tripsError = 'Lỗi tải chuyến đang chạy: $e';
      _tripsState = StaffLoadState.error;
    }
    notifyListeners();
  }

  void clearActError() {
    _actError = null;
    notifyListeners();
  }

  void refreshAll() {
    loadDashboard(force: true);
    loadPendingBookings(force: true);
    loadPassengerStats(force: true);
    loadActiveTrips(force: true);
  }
}
