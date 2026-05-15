/// Train Models – ánh xạ 1:1 từ C# Models/Entities.cs
///
/// C# classes được chuyển đổi:
///   Train       → [TrainModel]
///   Carriage    → [CarriageModel]   (ICollection<Seat> → List<SeatModel>)
///   Seat        → [SeatModel]
///
/// Response shapes từ TripService.GetAvailableSeatsAsync():
///   CarriageWithSeats  → [CarriageWithSeats]   (anonymous object C#)
///   SeatAvailability   → [SeatAvailability]    (anonymous object C#)
library;

// ═══════════════════════════════════════════════
// ENTITY MODELS (ánh xạ từ class C# thuần)
// ═══════════════════════════════════════════════

/// Ánh xạ từ class Train trong Entities.cs
/// TrainType: "express" | "local"
class TrainModel {
  final int id;
  final String name;
  final String code;
  final String trainType; // express | local
  final int totalCarriages;
  final bool isActive;
  final List<CarriageModel> carriages;

  const TrainModel({
    required this.id,
    required this.name,
    required this.code,
    required this.trainType,
    required this.totalCarriages,
    required this.isActive,
    this.carriages = const [],
  });

  factory TrainModel.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return TrainModel(
      id: _k('id') as int,
      name: _k('name') as String,
      code: _k('code') as String,
      trainType: _k('trainType') as String? ?? 'express',
      totalCarriages: _k('totalCarriages') as int,
      isActive: _k('isActive') as bool? ?? true,
      carriages: (_k('carriages') as List<dynamic>?)
              ?.map((e) => CarriageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'trainType': trainType,
        'totalCarriages': totalCarriages,
        'isActive': isActive,
        'carriages': carriages.map((c) => c.toJson()).toList(),
      };
}

// ─────────────────────────────────────────────

/// Ánh xạ từ class Carriage trong Entities.cs
///
/// carriageType (từ BE comment):
///   "hard_seat"    → Ghế cứng
///   "soft_seat"    → Ghế mềm
///   "hard_berth_6" → Giường nằm cứng 6 chỗ
///   "soft_berth_4" → Giường nằm mềm 4 chỗ
///   "vip"          → VIP/Hạng nhất
class CarriageModel {
  final int id;
  final int trainId;
  final int carriageNumber;
  final String carriageType;
  final int totalSeats;
  final bool isActive;
  final List<SeatModel> seats;

  const CarriageModel({
    required this.id,
    required this.trainId,
    required this.carriageNumber,
    required this.carriageType,
    required this.totalSeats,
    required this.isActive,
    this.seats = const [],
  });

  factory CarriageModel.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return CarriageModel(
      id: _k('id') as int,
      trainId: _k('trainId') as int,
      carriageNumber: _k('carriageNumber') as int,
      carriageType: _k('carriageType') as String,
      totalSeats: _k('totalSeats') as int,
      isActive: _k('isActive') as bool? ?? true,
      seats: (_k('seats') as List<dynamic>?)
              ?.map((e) => SeatModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainId': trainId,
        'carriageNumber': carriageNumber,
        'carriageType': carriageType,
        'totalSeats': totalSeats,
        'isActive': isActive,
        'seats': seats.map((s) => s.toJson()).toList(),
      };

  /// Tên hiển thị thân thiện theo loại toa
  String get displayName {
    switch (carriageType) {
      case 'hard_seat':
        return 'Ghế cứng';
      case 'soft_seat':
        return 'Ghế mềm';
      case 'hard_berth_6':
        return 'Giường cứng 6 chỗ';
      case 'soft_berth_4':
        return 'Giường mềm 4 chỗ';
      case 'vip':
        return 'VIP';
      default:
        return carriageType;
    }
  }
}

// ─────────────────────────────────────────────

/// Ánh xạ từ class Seat trong Entities.cs
///
/// seatPosition (từ BE comment):
///   "window" | "aisle" | "middle" | "upper" | "lower"
class SeatModel {
  final int id;
  final int carriageId;
  final String seatNumber;
  final String? seatPosition; // window | aisle | middle | upper | lower
  final int floor;
  final bool isActive;

  const SeatModel({
    required this.id,
    required this.carriageId,
    required this.seatNumber,
    this.seatPosition,
    required this.floor,
    required this.isActive,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return SeatModel(
      id: _k('id') as int,
      carriageId: _k('carriageId') as int,
      seatNumber: _k('seatNumber') as String,
      seatPosition: _k('seatPosition') as String?,
      floor: _k('floor') as int? ?? 1,
      isActive: _k('isActive') as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'carriageId': carriageId,
        'seatNumber': seatNumber,
        'seatPosition': seatPosition,
        'floor': floor,
        'isActive': isActive,
      };
}

// ═══════════════════════════════════════════════
// RESPONSE SHAPES (từ anonymous objects C# trong TripService)
// Đây KHÔNG phải Entity thuần – là DTO trả về từ
// TripService.GetAvailableSeatsAsync()
// ═══════════════════════════════════════════════

/// Trạng thái của một ghế trong chuyến tàu cụ thể.
/// Ánh xạ từ anonymous object bên trong TripService.GetAvailableSeatsAsync():
/// ```csharp
/// new { s.Id, s.SeatNumber, s.Floor, IsAvailable = ..., Price = ... }
/// ```
class SeatAvailability {
  final int id;
  final String seatNumber;
  final int floor;
  final bool isAvailable; // false nếu đã book hoặc đang lock
  final double price; // BasePrice * PriceMultiplier của toa

  const SeatAvailability({
    required this.id,
    required this.seatNumber,
    required this.floor,
    required this.isAvailable,
    required this.price,
  });

  factory SeatAvailability.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return SeatAvailability(
      id: _k('id') as int,
      seatNumber: _k('seatNumber') as String,
      floor: _k('floor') as int? ?? 1,
      isAvailable: _k('isAvailable') as bool,
      price: (_k('price') as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seatNumber': seatNumber,
        'floor': floor,
        'isAvailable': isAvailable,
        'price': price,
      };

  /// Tạo bản sao với isAvailable mới (dùng khi user đang chọn/bỏ chọn ghế)
  SeatAvailability copyWith({bool? isAvailable}) {
    return SeatAvailability(
      id: id,
      seatNumber: seatNumber,
      floor: floor,
      isAvailable: isAvailable ?? this.isAvailable,
      price: price,
    );
  }
}

// ─────────────────────────────────────────────

/// Toa tàu kèm danh sách ghế với trạng thái real-time.
/// Ánh xạ từ anonymous object bên trong TripService.GetAvailableSeatsAsync():
/// ```csharp
/// new { c.Id, c.CarriageNumber, c.CarriageType, Seats = seats }
/// ```
class CarriageWithSeats {
  final int id;
  final int carriageNumber;
  final String carriageType;
  final List<SeatAvailability> seats;

  const CarriageWithSeats({
    required this.id,
    required this.carriageNumber,
    required this.carriageType,
    required this.seats,
  });

  factory CarriageWithSeats.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return CarriageWithSeats(
      id: _k('id') as int,
      carriageNumber: _k('carriageNumber') as int,
      carriageType: _k('carriageType') as String,
      seats: (_k('seats') as List<dynamic>)
          .map((e) => SeatAvailability.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'carriageNumber': carriageNumber,
        'carriageType': carriageType,
        'seats': seats.map((s) => s.toJson()).toList(),
      };

  /// Tên hiển thị cho tab toa
  String get displayName {
    final typeName = switch (carriageType) {
      'hard_seat' => 'Ghế cứng',
      'soft_seat' => 'Ghế mềm',
      'hard_berth_6' => 'Giường cứng 6',
      'soft_berth_4' => 'Giường mềm 4',
      'vip' => 'VIP',
      _ => carriageType,
    };
    return 'Toa $carriageNumber\n$typeName';
  }

  /// Số ghế còn trống
  int get availableCount => seats.where((s) => s.isAvailable).length;

  /// Giá thấp nhất trong toa (thường tất cả ghế cùng giá)
  double get minPrice =>
      seats.isNotEmpty ? seats.map((s) => s.price).reduce((a, b) => a < b ? a : b) : 0;
}
