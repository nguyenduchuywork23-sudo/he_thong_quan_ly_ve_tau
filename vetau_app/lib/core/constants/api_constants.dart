/// API Constants & Configuration
/// Tập trung toàn bộ cấu hình kết nối backend tại đây.
/// Base URL trỏ tới .NET Core Backend đang chạy cục bộ.
library;

class ApiConstants {
  ApiConstants._(); // Ngăn khởi tạo instance

  // ─────────────────────────────────────────────
  // BASE URL
  // Android Emulator: 10.0.2.2 trỏ về localhost máy host
  // iOS Simulator   : 127.0.0.1
  // Thiết bị thật   : IP LAN của máy chạy BE (vd: 192.168.1.100)
  // ─────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:5000';

  // ─────────────────────────────────────────────
  // ENDPOINTS – ánh xạ từ Controllers/AppControllers.cs
  // ─────────────────────────────────────────────

  /// POST /api/auth/login
  static const String login = '/api/auth/login';

  /// POST /api/auth/register
  static const String register = '/api/auth/register';

  /// GET /api/trips/search?FromStation=&ToStation=&Date=
  static const String tripsSearch = '/api/trips/search';

  /// GET /api/trips/{id}/seats
  static String tripSeats(int tripId) => '/api/trips/$tripId/seats';

  /// POST /api/trips/lock-seat  (Header: X-Session-Id)
  static const String lockSeat = '/api/trips/lock-seat';

  /// POST /api/bookings  (Header: X-Session-Id)
  static const String createBooking = '/api/bookings';

  /// GET /api/bookings/my-bookings
  static const String myBookings = '/api/bookings/my-bookings';

  // ─── Admin Endpoints (JWT: role = admin | staff) ───

  /// GET /api/admin/dashboard
  static const String adminDashboard = '/api/admin/dashboard';

  /// GET | POST /api/admin/stations
  static const String adminStations = '/api/admin/stations';

  /// PUT /api/admin/stations/{id}
  static String adminStationById(int id) => '/api/admin/stations/$id';

  /// DELETE /api/admin/stations/{id}
  static String adminDeleteStation(int id) => '/api/admin/stations/$id';

  /// GET /api/admin/trains
  static const String adminTrains = '/api/admin/trains';

  /// GET /api/admin/bookings
  static const String adminBookings = '/api/admin/bookings';

  /// PUT /api/admin/bookings/{id}/status
  static String adminBookingStatus(int id) => '/api/admin/bookings/$id/status';

  // ─────────────────────────────────────────────
  // TIMEOUTS
  // ─────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ─────────────────────────────────────────────
  // SEAT LOCK
  // Thời gian giữ chỗ (phút) – khớp với AppConfig:SeatLockMinutes bên BE
  // ─────────────────────────────────────────────
  static const int seatLockMinutes = 15;

  // ─────────────────────────────────────────────
  // LOCAL STORAGE KEYS  (SharedPreferences)
  // ─────────────────────────────────────────────
  static const String keyJwtToken = 'jwt_token';
  static const String keySessionId = 'session_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserJson = 'user_json';
  static const String keyMyBookings = 'my_bookings';
}
