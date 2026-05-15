/// Trip Models – ánh xạ 1:1 từ C# Models/Entities.cs
///
/// C# classes được chuyển đổi:
///   Trip            → [TripModel]
///
/// Response shape từ TripService.SearchTripsAsync() (anonymous object C#):
///   TripSearchResult → [TripSearchResult]
library;

// ═══════════════════════════════════════════════
// ENTITY MODEL
// ═══════════════════════════════════════════════

/// Ánh xạ từ class Trip trong Entities.cs
///
/// Lưu ý quan trọng:
///   - [departureTime] và [arrivalTime] là String "HH:mm" (vd: "19:30"),
///     KHÔNG phải DateTime – đúng với thiết kế BE.
///   - [status]: "scheduled" | "delayed" | "cancelled"
class TripModel {
  final int id;
  final int trainId;
  final int routeId;
  final DateTime departureDate;
  final String departureTime; // "HH:mm" vd: "19:30"
  final String arrivalTime;   // "HH:mm" vd: "06:00+1"
  final int durationMinutes;
  final String status; // scheduled | delayed | cancelled
  final double basePrice;
  final DateTime createdAt;

  const TripModel({
    required this.id,
    required this.trainId,
    required this.routeId,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.status,
    required this.basePrice,
    required this.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return TripModel(
      id: _k('id') as int,
      trainId: _k('trainId') as int,
      routeId: _k('routeId') as int,
      departureDate: DateTime.parse(_k('departureDate') as String),
      departureTime: _k('departureTime') as String,
      arrivalTime: _k('arrivalTime') as String,
      durationMinutes: _k('durationMinutes') as int,
      status: _k('status') as String? ?? 'scheduled',
      basePrice: (_k('basePrice') as num).toDouble(),
      createdAt: DateTime.parse(_k('createdAt') as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainId': trainId,
        'routeId': routeId,
        'departureDate': departureDate.toIso8601String(),
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'durationMinutes': durationMinutes,
        'status': status,
        'basePrice': basePrice,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Thời gian di chuyển định dạng "Xh Ym"
  String get durationFormatted {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}p';
    if (m == 0) return '${h}h';
    return '${h}h ${m}p';
  }
}

// ═══════════════════════════════════════════════
// RESPONSE SHAPE (từ anonymous object C# trong TripService.SearchTripsAsync)
// ═══════════════════════════════════════════════

/// Kết quả tìm kiếm chuyến tàu.
/// Ánh xạ từ anonymous object bên trong TripService.SearchTripsAsync():
/// ```csharp
/// new {
///   t.Id, t.DepartureDate, t.DepartureTime, t.ArrivalTime,
///   TrainName = t.Train.Name, RouteName = t.Route.Name,
///   BasePrice = t.BasePrice, FromStation = fromRs.Station.Name,
///   ToStation = toRs.Station.Name,
///   Distance = toRs.DistanceKm - fromRs.DistanceKm
/// }
/// ```
class TripSearchResult {
  final int id;
  final DateTime departureDate;
  final String departureTime; // "HH:mm"
  final String arrivalTime;   // "HH:mm"
  final String trainName;     // vd: "Tàu Thống Nhất SE1"
  final String routeName;     // vd: "Hà Nội - TP.HCM"
  final double basePrice;     // Giá cơ bản (trước nhân hệ số toa)
  final String fromStation;   // Tên ga đi (đã join từ BE)
  final String toStation;     // Tên ga đến (đã join từ BE)
  final double distance;      // Khoảng cách km (toRs.DistanceKm - fromRs.DistanceKm)

  const TripSearchResult({
    required this.id,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.trainName,
    required this.routeName,
    required this.basePrice,
    required this.fromStation,
    required this.toStation,
    required this.distance,
  });

  factory TripSearchResult.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return TripSearchResult(
      id: _k('id') as int,
      departureDate: DateTime.parse(_k('departureDate') as String),
      departureTime: _k('departureTime') as String,
      arrivalTime: _k('arrivalTime') as String,
      trainName: _k('trainName') as String,
      routeName: _k('routeName') as String,
      basePrice: (_k('basePrice') as num).toDouble(),
      fromStation: _k('fromStation') as String,
      toStation: _k('toStation') as String,
      distance: (_k('distance') as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'departureDate': departureDate.toIso8601String(),
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'trainName': trainName,
        'routeName': routeName,
        'basePrice': basePrice,
        'fromStation': fromStation,
        'toStation': toStation,
        'distance': distance,
      };

  /// Tính thời gian di chuyển dựa trên departureTime và arrivalTime.
  /// Hỗ trợ trường hợp tàu qua đêm (arrivalTime có thể nhỏ hơn departureTime).
  String get durationFormatted {
    try {
      final depParts = departureTime.split(':');
      final arrParts = arrivalTime.replaceAll('+1', '').split(':');
      final depMinutes =
          int.parse(depParts[0]) * 60 + int.parse(depParts[1]);
      int arrMinutes = int.parse(arrParts[0]) * 60 + int.parse(arrParts[1]);

      // Nếu tàu qua đêm: thêm 24 giờ vào giờ đến
      if (arrMinutes <= depMinutes) arrMinutes += 24 * 60;

      final diff = arrMinutes - depMinutes;
      final h = diff ~/ 60;
      final m = diff % 60;
      if (h == 0) return '${m}p';
      if (m == 0) return '${h}h';
      return '${h}h${m}p';
    } catch (_) {
      return '--';
    }
  }
}

// ─────────────────────────────────────────────

/// Station model đơn giản – dùng trong picker và hiển thị.
/// Ánh xạ từ class Station trong Entities.cs.
class StationModel {
  final int id;
  final String name;
  final String code;
  final String? city;
  final String? province;
  final int sortOrder;
  final bool isActive;

  const StationModel({
    required this.id,
    required this.name,
    required this.code,
    this.city,
    this.province,
    required this.sortOrder,
    required this.isActive,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    dynamic _k(String key) => json[key] ?? json[key[0].toUpperCase() + key.substring(1)];
    return StationModel(
      id: _k('id') as int,
      name: _k('name') as String,
      code: _k('code') as String,
      city: _k('city') as String?,
      province: _k('province') as String?,
      sortOrder: _k('sortOrder') as int? ?? 0,
      isActive: _k('isActive') as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'city': city,
        'province': province,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StationModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
