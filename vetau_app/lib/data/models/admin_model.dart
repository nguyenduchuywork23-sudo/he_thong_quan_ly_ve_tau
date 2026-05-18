library;

class DashboardStats {
  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final double totalRevenue;
  final double todayRevenue;
  final int totalStations;
  final int totalTrains;
  final int activeTrips;
  final int totalCustomers;

  const DashboardStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.totalStations,
    required this.totalTrains,
    required this.activeTrips,
    required this.totalCustomers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalBookings: _int(j, 'totalBookings'),
    pendingBookings: _int(j, 'pendingBookings'),
    confirmedBookings: _int(j, 'confirmedBookings'),
    cancelledBookings: _int(j, 'cancelledBookings'),
    totalRevenue: _double(j, 'totalRevenue'),
    todayRevenue: _double(j, 'todayRevenue'),
    totalStations: _int(j, 'totalStations'),
    totalTrains: _int(j, 'totalTrains'),
    activeTrips: _int(j, 'activeTrips'),
    totalCustomers: _int(j, 'totalCustomers'),
  );

  static int _int(Map m, String k) =>
      (m[k] ?? m[_camel(k)] ?? 0) is num ? (m[k] ?? m[_camel(k)] ?? 0) as int : 0;

  static double _double(Map m, String k) {
    final v = m[k] ?? m[_camel(k)] ?? 0;
    return (v is num) ? v.toDouble() : 0.0;
  }

  static String _camel(String s) =>
      s[0].toUpperCase() + s.substring(1);
}

class AdminBooking {
  final int id;
  final String bookingCode;
  final String passengerName;
  final String passengerIdCard;
  final String passengerPhone;
  final String? passengerEmail;
  final String passengerType;
  final String paymentMethod;
  final String status; // Pending | Confirmed | Cancelled
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? paymentDeadline;
  final String? qrCodeData;
  final String trainName;
  final String fromStation;
  final String toStation;
  final String departureTime;
  final String arrivalTime;
  final String? departureDate;
  final String seatNumber;
  final String carriageType;
  final int? tripId;

  const AdminBooking({
    required this.id,
    required this.bookingCode,
    required this.passengerName,
    required this.passengerIdCard,
    required this.passengerPhone,
    this.passengerEmail,
    required this.passengerType,
    required this.paymentMethod,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.paymentDeadline,
    this.qrCodeData,
    required this.trainName,
    required this.fromStation,
    required this.toStation,
    required this.departureTime,
    required this.arrivalTime,
    this.departureDate,
    required this.seatNumber,
    required this.carriageType,
    this.tripId,
  });

  factory AdminBooking.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
    }

    String s(String k) => (j[k] ?? j[_cap(k)] ?? '') as String;
    double d(String k) { final v = j[k] ?? j[_cap(k)] ?? 0; return (v is num) ? v.toDouble() : 0.0; }
    int i(String k) { final v = j[k] ?? j[_cap(k)] ?? 0; return (v is num) ? v.toInt() : 0; }

    return AdminBooking(
      id: i('id'),
      bookingCode: s('bookingCode'),
      passengerName: s('passengerName'),
      passengerIdCard: s('passengerIdCard'),
      passengerPhone: s('passengerPhone'),
      passengerEmail: j['passengerEmail'] as String? ?? j['PassengerEmail'] as String?,
      passengerType: s('passengerType'),
      paymentMethod: s('paymentMethod'),
      status: s('status'),
      totalPrice: d('totalPrice'),
      createdAt: parseDate(j['createdAt'] ?? j['CreatedAt']),
      paymentDeadline: j['paymentDeadline'] != null
          ? DateTime.tryParse(j['paymentDeadline'].toString())
          : null,
      qrCodeData: j['qrCodeData'] as String?,
      trainName: s('trainName'),
      fromStation: s('fromStation'),
      toStation: s('toStation'),
      departureTime: s('departureTime'),
      arrivalTime: s('arrivalTime'),
      departureDate: j['departureDate'] as String?,
      seatNumber: s('seatNumber'),
      carriageType: s('carriageType'),
      tripId: j['tripId'] as int? ?? j['TripId'] as int?,
    );
  }

  static String _cap(String s) => s[0].toUpperCase() + s.substring(1);

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}

class UpdateBookingStatusRequest {
  final String status;
  const UpdateBookingStatusRequest({required this.status});
  Map<String, dynamic> toJson() => {'Status': status};
}
