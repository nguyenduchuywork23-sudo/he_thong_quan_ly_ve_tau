/// TripProvider – State Management cho luồng tìm kiếm & chọn ghế
///
/// Quản lý 3 màn hình:
///   1. Home Search  → [searchTrips]
///   2. Seat Map     → [loadSeats], [selectSeat], [lockSelectedSeat]
///   3. Seat status  → [SeatLockState] theo từng ghế
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/train_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/services/trip_service.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

// ═══════════════════════════════════════════════
// ENUM TRẠNG THÁI PROVIDER
// ═══════════════════════════════════════════════

enum TripLoadState { idle, loading, loaded, error }

/// Trạng thái ghế từ góc nhìn của user hiện tại
enum SeatLockState {
  idle,       // Chưa làm gì
  locking,    // Đang gọi POST /api/trips/lock-seat
  locked,     // Lock thành công – đang đếm ngược 15p
  failed,     // Lock thất bại (ghế bị người khác lấy)
}

// ═══════════════════════════════════════════════
// TRIP PROVIDER
// ═══════════════════════════════════════════════

class TripProvider extends ChangeNotifier {
  final TripService _tripService = TripService();

  // ─── Search State ───────────────────────────────────
  TripLoadState _searchState = TripLoadState.idle;
  List<TripSearchResult> _searchResults = [];
  String? _searchError;

  // Tham số tìm kiếm hiện tại (giữ lại để refresh)
  String? _lastFromCode;
  String? _lastToCode;
  DateTime? _lastDate;

  // ─── Station State ─────────────────────────────────
  List<StationModel> _stations = [];
  TripLoadState _stationsState = TripLoadState.idle;
  String? _stationsError;

  // ─── Selected Trip ────────────────────────────
  TripSearchResult? _selectedTrip;

  // ─── Seats State ─────────────────────────────
  TripLoadState _seatsState = TripLoadState.idle;
  List<CarriageWithSeats> _carriages = [];
  String? _seatsError;

  // Tab toa đang chọn (index)
  int _selectedCarriageIndex = 0;

  // Ghế user đang chọn (trước khi lock)
  SeatAvailability? _selectedSeat;
  CarriageWithSeats? _selectedCarriage;

  // ─── Seat Lock State ──────────────────────────
  SeatLockState _seatLockState = SeatLockState.idle;
  String? _lockError;
  DateTime? _lockExpiry;        // Thời điểm hết hạn giữ chỗ
  LockSeatResponse? _lockResponse;
  
  Timer? _lockTimer;

  // Đếm ngược giữ chỗ
  int _lockRemainingSeconds = 0;

  // ─── Getters ──────────────────────────────────────
  TripLoadState get searchState => _searchState;
  List<TripSearchResult> get searchResults => _searchResults;
  String? get searchError => _searchError;
  bool get isSearchLoading => _searchState == TripLoadState.loading;
  String? get lastFromCode => _lastFromCode;
  String? get lastToCode => _lastToCode;
  DateTime? get lastDate => _lastDate;

  List<StationModel> get stations => List.unmodifiable(_stations);
  TripLoadState get stationsState => _stationsState;
  String? get stationsError => _stationsError;
  bool get stationsLoaded => _stationsState == TripLoadState.loaded;

  TripSearchResult? get selectedTrip => _selectedTrip;

  TripLoadState get seatsState => _seatsState;
  List<CarriageWithSeats> get carriages => _carriages;
  String? get seatsError => _seatsError;
  bool get isSeatsLoading => _seatsState == TripLoadState.loading;

  int get selectedCarriageIndex => _selectedCarriageIndex;
  CarriageWithSeats? get currentCarriage =>
      _carriages.isNotEmpty && _selectedCarriageIndex < _carriages.length
          ? _carriages[_selectedCarriageIndex]
          : null;

  SeatAvailability? get selectedSeat => _selectedSeat;
  CarriageWithSeats? get selectedCarriage => _selectedCarriage;

  SeatLockState get seatLockState => _seatLockState;
  String? get lockError => _lockError;
  DateTime? get lockExpiry => _lockExpiry;
  LockSeatResponse? get lockResponse => _lockResponse;
  int get lockRemainingSeconds => _lockRemainingSeconds;
  bool get isSeatLocked => _seatLockState == SeatLockState.locked;
  bool get isSeatLocking => _seatLockState == SeatLockState.locking;

  // ═══════════════════════════════════════════════
  // ACTIONS – TẢI DANH SÁCH GA TÀU
  // Gọi GET /api/Trips/stations
  // Chỉ thành công khi user đã login (JWT hợp lệ)
  // Nếu 401 → _stationsState = error (UI hiển thị fallback text field)
  // ═══════════════════════════════════════════════
  Future<void> loadStations() async {
    // Không reload nếu đã tải thành công
    if (_stationsState == TripLoadState.loaded && _stations.isNotEmpty) return;
    _stationsState = TripLoadState.loading;
    notifyListeners();
    try {
      _stations = await _tripService.getStations();
      _stationsState = TripLoadState.loaded;
    } on AppException catch (e) {
      _stationsError = e.message;
      _stationsState = TripLoadState.error;
    } catch (e) {
      _stationsError = 'Không thể tải danh sách ga.';
      _stationsState = TripLoadState.error;
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // ACTIONS – TÌM KIẾM CHUYẾN
  // ═══════════════════════════════════════════════

  /// Gọi GET /api/trips/search
  Future<void> searchTrips({
    required String fromStationCode,
    required String toStationCode,
    required DateTime date,
  }) async {
    _searchState = TripLoadState.loading;
    _searchError = null;
    _searchResults = [];
    notifyListeners();

    // Lưu params để có thể refresh
    _lastFromCode = fromStationCode;
    _lastToCode = toStationCode;
    _lastDate = date;

    try {
      _searchResults = await _tripService.searchTrips(
        fromStationCode: fromStationCode,
        toStationCode: toStationCode,
        date: date,
      );
      _searchState = TripLoadState.loaded;
    } on AppException catch (e) {
      _searchError = e.message;
      _searchState = TripLoadState.error;
    } catch (e) {
      _searchError = 'Lỗi không xác định khi tìm kiếm.';
      _searchState = TripLoadState.error;
    }

    notifyListeners();
  }

  /// Chọn chuyến từ kết quả tìm kiếm → điều hướng sang màn Seat Map
  void selectTrip(TripSearchResult trip) {
    _selectedTrip = trip;
    // Reset trạng thái seat cũ
    _carriages = [];
    _selectedSeat = null;
    _selectedCarriage = null;
    _selectedCarriageIndex = 0;
    _seatLockState = SeatLockState.idle;
    _lockError = null;
    _lockExpiry = null;
    _lockResponse = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // ACTIONS – SƠ ĐỒ GHẾ
  // ═══════════════════════════════════════════════

  /// Gọi GET /api/trips/{id}/seats
  Future<void> loadSeats(int tripId) async {
    _seatsState = TripLoadState.loading;
    _seatsError = null;
    notifyListeners();

    try {
      _carriages = await _tripService.getAvailableSeats(tripId);
      _selectedCarriageIndex = 0;
      _seatsState = TripLoadState.loaded;
    } on AppException catch (e) {
      _seatsError = e.message;
      _seatsState = TripLoadState.error;
    } catch (e) {
      _seatsError = 'Lỗi không xác định khi tải sơ đồ ghế.';
      _seatsState = TripLoadState.error;
    }

    notifyListeners();
  }

  /// Đổi tab toa đang xem
  void selectCarriageTab(int index) {
    if (index < 0 || index >= _carriages.length) return;
    _selectedCarriageIndex = index;
    notifyListeners();
  }

  /// User tap vào 1 ghế trống → lưu ghế đang chọn (chưa lock)
  /// Nếu tap lại ghế đã chọn → bỏ chọn
  void tapSeat(SeatAvailability seat, CarriageWithSeats carriage) {
    if (!seat.isAvailable) return; // Ghế đã đặt → bỏ qua

    // Nếu ghế đang lock (đã confirm) → không cho đổi
    if (_seatLockState == SeatLockState.locked) return;

    if (_selectedSeat?.id == seat.id) {
      // Tap lại → bỏ chọn
      _selectedSeat = null;
      _selectedCarriage = null;
    } else {
      _selectedSeat = seat;
      _selectedCarriage = carriage;
      // Reset lock state cũ nếu có
      if (_seatLockState == SeatLockState.failed) {
        _seatLockState = SeatLockState.idle;
        _lockError = null;
      }
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════
  // ACTIONS – LOCK SEAT
  // Gọi POST /api/trips/lock-seat
  // X-Session-Id được SessionInterceptor tự đính kèm
  // ═══════════════════════════════════════════════

  /// Giữ ghế đang được chọn.
  /// Trả về true nếu lock thành công, false nếu thất bại.
  Future<bool> lockSelectedSeat() async {
    if (_selectedSeat == null || _selectedTrip == null) return false;

    _seatLockState = SeatLockState.locking;
    _lockError = null;
    notifyListeners();

    try {
      _lockResponse = await _tripService.lockSeat(
        seatId: _selectedSeat!.id,
        tripId: _selectedTrip!.id,
      );

      _seatLockState = SeatLockState.locked;
      _lockExpiry = DateTime.now().add(
        const Duration(minutes: ApiConstants.seatLockMinutes),
      );

      // Cập nhật trạng thái ghế trong danh sách cục bộ
      _markSeatAsUnavailable(_selectedSeat!.id);

      // Bắt đầu đếm ngược
      _startCountdown();

      notifyListeners();
      return true;
    } on AppException catch (e) {
      _seatLockState = SeatLockState.failed;
      _lockError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _seatLockState = SeatLockState.failed;
      _lockError = 'Không thể giữ chỗ. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  /// Đánh dấu ghế trong danh sách cục bộ là unavailable
  /// (để UI cập nhật ngay mà không cần reload)
  void _markSeatAsUnavailable(int seatId) {
    _carriages = _carriages.map((carriage) {
      final updatedSeats = carriage.seats.map((seat) {
        if (seat.id == seatId) return seat.copyWith(isAvailable: false);
        return seat;
      }).toList();
      return CarriageWithSeats(
        id: carriage.id,
        carriageNumber: carriage.carriageNumber,
        carriageType: carriage.carriageType,
        seats: updatedSeats,
      );
    }).toList();
  }

  /// Đếm ngược 15 phút giữ chỗ
  void _startCountdown() {
    _lockRemainingSeconds = ApiConstants.seatLockMinutes * 60;
    _lockTimer?.cancel();

    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seatLockState != SeatLockState.locked) {
        timer.cancel();
        return;
      }
      if (_lockRemainingSeconds <= 0) {
        // Hết giờ giữ chỗ → reset
        _seatLockState = SeatLockState.idle;
        _selectedSeat = null;
        _selectedCarriage = null;
        _lockExpiry = null;
        timer.cancel();
        notifyListeners();
        return;
      }
      _lockRemainingSeconds--;
      notifyListeners();
    });
  }

  /// Format countdown "MM:SS"
  String get lockCountdownFormatted {
    final m = _lockRemainingSeconds ~/ 60;
    final s = _lockRemainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─── Reset ────────────────────────────────────
  void resetSearch() {
    _searchState = TripLoadState.idle;
    _searchResults = [];
    _searchError = null;
    _selectedTrip = null;
    notifyListeners();
  }

  void resetSeatSelection() {
    _lockTimer?.cancel();
    _selectedSeat = null;
    _selectedCarriage = null;
    _seatLockState = SeatLockState.idle;
    _lockError = null;
    _lockExpiry = null;
    _lockResponse = null;
    _lockRemainingSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}
