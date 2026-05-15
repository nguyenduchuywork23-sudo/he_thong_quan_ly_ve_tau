/// Booking Models – DTOs & Response shapes liên quan đến đặt vé
///
/// Ánh xạ từ:
///   DTOs/Models.cs → [LockSeatRequest], [CreateBookingRequest]
///   Models/Entities.cs → [BookingModel]
///   Controllers: response anonymous objects từ BookingsController
library;

// ═══════════════════════════════════════════════
// REQUEST DTOs (gửi lên BE)
// ═══════════════════════════════════════════════

/// Ánh xạ từ class LockSeatRequest trong DTOs/Models.cs
/// Gửi lên: POST /api/trips/lock-seat
/// Header bắt buộc: X-Session-Id (do SessionInterceptor tự đính kèm)
class LockSeatRequest {
  final int seatId;
  final int tripId;

  const LockSeatRequest({
    required this.seatId,
    required this.tripId,
  });

  Map<String, dynamic> toJson() => {
        'seatId': seatId,
        'tripId': tripId,
      };
}

// ─────────────────────────────────────────────

/// Ánh xạ từ class CreateBookingRequest trong DTOs/Models.cs
/// Gửi lên: POST /api/bookings
/// Header bắt buộc: X-Session-Id (do SessionInterceptor tự đính kèm)
///
/// [Required] fields từ C# → KHÔNG được null trong Dart:
///   passengerName, passengerIdCard, passengerPhone
/// Nullable fields từ C# (string?) → nullable String? trong Dart:
///   passengerEmail
class CreateBookingRequest {
  final int tripId;
  final int fromStationId;
  final int toStationId;
  final int seatId;
  final int carriageId;

  // [Required] – bắt buộc nhập (validate ở UI trước khi gọi API)
  final String passengerName;
  final String passengerIdCard;
  final String passengerPhone;

  // Optional – có thể null
  final String? passengerEmail;

  // Default values – khớp với default của BE
  final String passengerType;   // "adult" | "child" | "elderly"
  final String paymentMethod;   // "qr_transfer" (mặc định BE)

  const CreateBookingRequest({
    required this.tripId,
    required this.fromStationId,
    required this.toStationId,
    required this.seatId,
    required this.carriageId,
    required this.passengerName,
    required this.passengerIdCard,
    required this.passengerPhone,
    this.passengerEmail,
    this.passengerType = 'adult',
    this.paymentMethod = 'qr_transfer',
  });

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'fromStationId': fromStationId,
        'toStationId': toStationId,
        'seatId': seatId,
        'carriageId': carriageId,
        'passengerName': passengerName,
        'passengerIdCard': passengerIdCard,
        'passengerPhone': passengerPhone,
        if (passengerEmail != null) 'passengerEmail': passengerEmail,
        'passengerType': passengerType,
        'paymentMethod': paymentMethod,
      };
}

// ═══════════════════════════════════════════════
// RESPONSE DTOs (nhận từ BE)
// ═══════════════════════════════════════════════

/// Response từ POST /api/trips/lock-seat (OK 200)
/// ```csharp
/// return Ok(new { SessionId = ..., Message = "Giữ chỗ thành công..." });
/// ```
class LockSeatResponse {
  final String sessionId;
  final String message;

  const LockSeatResponse({
    required this.sessionId,
    required this.message,
  });

  factory LockSeatResponse.fromJson(Map<String, dynamic> json) {
    return LockSeatResponse(
      // BE trả về "SessionId" (PascalCase)
      sessionId: json['SessionId'] as String? ?? json['sessionId'] as String? ?? '',
      message: json['Message'] as String? ?? json['message'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────

/// Response từ POST /api/bookings (OK 200)
/// ```csharp
/// return Ok(new {
///   Message, BookingCode, FinalPrice, PaymentDeadline, QrCodeData
/// });
/// ```
class CreateBookingResponse {
  final String message;
  final String bookingCode;
  final double finalPrice;
  final DateTime? paymentDeadline; // nullable vì BE dùng DateTime?
  final String? qrCodeData;        // Base64 image string

  const CreateBookingResponse({
    required this.message,
    required this.bookingCode,
    required this.finalPrice,
    this.paymentDeadline,
    this.qrCodeData,
  });

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) {
    return CreateBookingResponse(
      message: json['Message'] as String? ?? json['message'] as String? ?? '',
      bookingCode: json['BookingCode'] as String? ?? json['bookingCode'] as String? ?? '',
      finalPrice: (json['FinalPrice'] ?? json['finalPrice'] as num? ?? 0).toDouble(),
      paymentDeadline: json['PaymentDeadline'] != null
          ? DateTime.tryParse(json['PaymentDeadline'].toString())
          : json['paymentDeadline'] != null
              ? DateTime.tryParse(json['paymentDeadline'].toString())
              : null,
      qrCodeData: json['QrCodeData'] as String? ?? json['qrCodeData'] as String?,
    );
  }
}

// ═══════════════════════════════════════════════
// ENTITY MODEL – BookingModel
// Ánh xạ từ class Booking trong Entities.cs
// Dùng cho màn hình My Tickets và Admin Bookings
// ═══════════════════════════════════════════════

/// Ánh xạ đầy đủ từ class Booking trong Models/Entities.cs
/// Tất cả nullable field của C# (int?, DateTime?, string?) → nullable trong Dart
class BookingModel {
  final int id;
  final String bookingCode;
  final int? userId;           // nullable – khách không cần login
  final int tripId;
  final int fromStationId;
  final int toStationId;

  // Thông tin hành khách
  final String passengerName;
  final String passengerIdCard;
  final String passengerPhone;
  final String? passengerEmail;
  final String passengerType;  // adult | child | elderly

  // Ghế & toa
  final int seatId;
  final int carriageId;

  // Giá
  final double basePrice;
  final double discountPercent;
  final double discountAmount;
  final double finalPrice;

  // Trạng thái
  final String status;         // pending | confirmed | cancelled
  final String paymentMethod;  // qr_transfer | ...
  final DateTime? paymentDeadline;
  final DateTime? paidAt;
  final String? qrCodeData;    // Base64 image

  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.bookingCode,
    this.userId,
    required this.tripId,
    required this.fromStationId,
    required this.toStationId,
    required this.passengerName,
    required this.passengerIdCard,
    required this.passengerPhone,
    this.passengerEmail,
    required this.passengerType,
    required this.seatId,
    required this.carriageId,
    required this.basePrice,
    required this.discountPercent,
    required this.discountAmount,
    required this.finalPrice,
    required this.status,
    required this.paymentMethod,
    this.paymentDeadline,
    this.paidAt,
    this.qrCodeData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return BookingModel(
      id: _k('id') as int,
      bookingCode: _k('bookingCode') as String,
      userId: _k('userId') as int?,
      tripId: _k('tripId') as int,
      fromStationId: _k('fromStationId') as int,
      toStationId: _k('toStationId') as int,
      passengerName: _k('passengerName') as String,
      passengerIdCard: _k('passengerIdCard') as String,
      passengerPhone: _k('passengerPhone') as String,
      passengerEmail: _k('passengerEmail') as String?,
      passengerType: _k('passengerType') as String? ?? 'adult',
      seatId: _k('seatId') as int,
      carriageId: _k('carriageId') as int,
      basePrice: (_k('basePrice') as num).toDouble(),
      discountPercent: (_k('discountPercent') as num? ?? 0).toDouble(),
      discountAmount: (_k('discountAmount') as num? ?? 0).toDouble(),
      finalPrice: (_k('finalPrice') as num).toDouble(),
      status: _k('status') as String? ?? 'pending',
      paymentMethod: _k('paymentMethod') as String? ?? 'qr_transfer',
      paymentDeadline: _k('paymentDeadline') != null
          ? DateTime.tryParse(_k('paymentDeadline').toString())
          : null,
      paidAt: _k('paidAt') != null
          ? DateTime.tryParse(_k('paidAt').toString())
          : null,
      qrCodeData: _k('qrCodeData') as String?,
      createdAt: DateTime.parse(_k('createdAt') as String),
      updatedAt: DateTime.parse(_k('updatedAt') as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingCode': bookingCode,
        'userId': userId,
        'tripId': tripId,
        'fromStationId': fromStationId,
        'toStationId': toStationId,
        'passengerName': passengerName,
        'passengerIdCard': passengerIdCard,
        'passengerPhone': passengerPhone,
        'passengerEmail': passengerEmail,
        'passengerType': passengerType,
        'seatId': seatId,
        'carriageId': carriageId,
        'basePrice': basePrice,
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'finalPrice': finalPrice,
        'status': status,
        'paymentMethod': paymentMethod,
        'paymentDeadline': paymentDeadline?.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'qrCodeData': qrCodeData,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Nhãn trạng thái hiển thị tiếng Việt
  String get statusLabel => switch (status) {
        'pending' => 'Chờ thanh toán',
        'confirmed' => 'Đã xác nhận',
        'cancelled' => 'Đã hủy',
        _ => status,
      };

  /// Còn trong thời gian giữ chỗ không?
  bool get isWithinDeadline =>
      paymentDeadline != null &&
      DateTime.now().isBefore(paymentDeadline!);
}
