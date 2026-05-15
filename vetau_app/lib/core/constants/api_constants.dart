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
  static const String baseUrl = 'http://10.0.2.2:5065';

  // ─────────────────────────────────────────────
  // ENDPOINTS – ánh xạ từ Controllers/AppControllers.cs
  // ─────────────────────────────────────────────

  /// POST /api/Auth/login
  static const String login = '/api/Auth/login';

  /// POST /api/Auth/register
  static const String register = '/api/Auth/register';

  /// GET /api/Trips/search?FromStation=&ToStation=&Date=
  static const String tripsSearch = '/api/Trips/search';

  /// GET /api/Trips/{id}/seats
  static String tripSeats(int tripId) => '/api/Trips/$tripId/seats';

  /// POST /api/Trips/lock-seat  (Header: X-Session-Id)
  static const String lockSeat = '/api/Trips/lock-seat';

  /// POST /api/Bookings  (Header: X-Session-Id)
  static const String createBooking = '/api/Bookings';

  /// GET /api/Bookings/my-bookings
  static const String myBookings = '/api/Bookings/my-bookings';

  // ─── Admin Endpoints (JWT: role = admin | staff) ───

  /// GET /api/Admin/dashboard
  static const String adminDashboard = '/api/Admin/dashboard';

  /// GET | POST /api/Admin/stations
  static const String adminStations = '/api/Admin/stations';

  /// PUT /api/Admin/stations/{id}
  static String adminStationById(int id) => '/api/Admin/stations/$id';

  /// DELETE /api/Admin/stations/{id}
  static String adminDeleteStation(int id) => '/api/Admin/stations/$id';

  /// GET /api/Admin/trains
  static const String adminTrains = '/api/Admin/trains';

  /// GET /api/Admin/bookings
  static const String adminBookings = '/api/Admin/bookings';

  /// PUT /api/Admin/bookings/{id}/status
  static String adminBookingStatus(int id) => '/api/Admin/bookings/$id/status';

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
