library;

class ApiConstants {
  ApiConstants._(); // Ngăn khởi tạo instance

  static const String baseUrl = 'http://10.0.2.2:5065';


  static const String login = '/api/Auth/login';

  static const String register = '/api/Auth/register';

  static const String tripsSearch = '/api/Trips/search';

  static String tripSeats(int tripId) => '/api/Trips/$tripId/seats';

  static const String lockSeat = '/api/Trips/lock-seat';

  static const String tripsStations = '/api/Trips/stations';

  static const String createBooking = '/api/Bookings';

  static const String myBookings = '/api/Bookings/my-bookings';


  static const String adminDashboard = '/api/Admin/dashboard';

  static const String adminStations = '/api/Admin/stations';

  static String adminStationById(int id) => '/api/Admin/stations/$id';

  static String adminDeleteStation(int id) => '/api/Admin/stations/$id';

  static const String adminTrains = '/api/Admin/trains';

  static const String adminBookings = '/api/Admin/bookings';

  static String adminBookingStatus(int id) => '/api/Admin/bookings/$id/status';


  static const String staffDashboard = '/api/Staff/dashboard';

  static const String staffPendingBookings = '/api/Staff/pending-bookings';

  static String staffApproveBooking(int id) => '/api/Staff/bookings/$id/approve';

  static String staffRejectBooking(int id) => '/api/Staff/bookings/$id/reject';

  static const String staffPassengerStats = '/api/Staff/passenger-stats';

  static const String staffActiveTrips = '/api/Staff/active-trips';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const int seatLockMinutes = 15;

  static const String keyJwtToken = 'jwt_token';
  static const String keySessionId = 'session_id';
  static const String keyUserRole = 'user_role';
  static const String keyUserJson = 'user_json';
  static const String keyMyBookings = 'my_bookings';
}
