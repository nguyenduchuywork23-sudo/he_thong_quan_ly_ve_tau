library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/booking_model.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/train_model.dart';
import '../../data/services/booking_service.dart';
import '../../core/network/dio_client.dart' hide debugPrint;
import '../../core/constants/api_constants.dart';


enum BookingSubmitState { idle, submitting, success, error }


class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  TripSearchResult? _trip;
  SeatAvailability? _seat;
  CarriageWithSeats? _carriage;
  int _fromStationId = 0;
  int _toStationId = 0;
  String _sessionId = '';

  String _passengerName = '';
  String _passengerIdCard = '';
  String _passengerPhone = '';
  String _passengerEmail = '';
  String _passengerType = 'adult';   // adult | child | elderly
  String _paymentMethod = 'qr_transfer';

  final Map<String, String?> _fieldErrors = {
    'passengerName': null,
    'passengerIdCard': null,
    'passengerPhone': null,
    'passengerEmail': null,
  };

  BookingSubmitState _submitState = BookingSubmitState.idle;
  String? _submitError;
  CreateBookingResponse? _bookingResult;

  List<Map<String, dynamic>> _savedBookings = [];
  bool _isFetchingBookings = false;

  TripSearchResult? get trip => _trip;
  SeatAvailability? get seat => _seat;
  CarriageWithSeats? get carriage => _carriage;

  String get passengerName => _passengerName;
  String get passengerIdCard => _passengerIdCard;
  String get passengerPhone => _passengerPhone;
  String get passengerEmail => _passengerEmail;
  String get passengerType => _passengerType;
  String get paymentMethod => _paymentMethod;

  Map<String, String?> get fieldErrors => Map.unmodifiable(_fieldErrors);
  bool get hasErrors => _fieldErrors.values.any((e) => e != null);

  BookingSubmitState get submitState => _submitState;
  String? get submitError => _submitError;
  CreateBookingResponse? get bookingResult => _bookingResult;
  bool get isSubmitting => _submitState == BookingSubmitState.submitting;
  bool get isSuccess => _submitState == BookingSubmitState.success;

  bool get isFetchingBookings => _isFetchingBookings;
  List<Map<String, dynamic>> get savedBookings =>
      List.unmodifiable(_savedBookings);


  void setBookingContext({
    required TripSearchResult trip,
    required SeatAvailability seat,
    required CarriageWithSeats carriage,
    required int fromStationId,
    required int toStationId,
    required String sessionId,
  }) {
    _trip = trip;
    _seat = seat;
    _carriage = carriage;
    _fromStationId = fromStationId;
    _toStationId = toStationId;
    _sessionId = sessionId;

    _resetForm();
    notifyListeners();
  }


  void setPassengerName(String value) {
    _passengerName = value;
    _validateField('passengerName', value);
    notifyListeners();
  }

  void setPassengerIdCard(String value) {
    _passengerIdCard = value;
    _validateField('passengerIdCard', value);
    notifyListeners();
  }

  void setPassengerPhone(String value) {
    _passengerPhone = value;
    _validateField('passengerPhone', value);
    notifyListeners();
  }

  void setPassengerEmail(String value) {
    _passengerEmail = value;
    _validateField('passengerEmail', value);
    notifyListeners();
  }

  void setPassengerType(String type) {
    _passengerType = type;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }


  void _validateField(String field, String value) {
    switch (field) {
      case 'passengerName':
        if (value.trim().isEmpty) {
          _fieldErrors[field] = 'Vui lòng nhập họ tên';
        } else if (value.trim().length < 2) {
          _fieldErrors[field] = 'Họ tên phải có ít nhất 2 ký tự';
        } else if (value.trim().length > 100) {
          _fieldErrors[field] = 'Họ tên không quá 100 ký tự';
        } else {
          _fieldErrors[field] = null;
        }

      case 'passengerIdCard':
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) {
          _fieldErrors[field] = 'Vui lòng nhập số CMND/CCCD';
        } else if (digits.length != 9 && digits.length != 12) {
          _fieldErrors[field] = 'CMND/CCCD phải có 9 hoặc 12 chữ số';
        } else {
          _fieldErrors[field] = null;
        }

      case 'passengerPhone':
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty) {
          _fieldErrors[field] = 'Vui lòng nhập số điện thoại';
        } else if (digits.length != 10) {
          _fieldErrors[field] = 'Số điện thoại phải có 10 chữ số';
        } else if (!digits.startsWith('0')) {
          _fieldErrors[field] = 'Số điện thoại phải bắt đầu bằng 0';
        } else {
          _fieldErrors[field] = null;
        }

      case 'passengerEmail':
        if (value.isEmpty) {
          _fieldErrors[field] = null; // Không bắt buộc
        } else if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(value)) {
          _fieldErrors[field] = 'Email không hợp lệ';
        } else {
          _fieldErrors[field] = null;
        }
    }
  }

  bool validateForm() {
    _validateField('passengerName', _passengerName);
    _validateField('passengerIdCard', _passengerIdCard);
    _validateField('passengerPhone', _passengerPhone);
    _validateField('passengerEmail', _passengerEmail);
    notifyListeners();
    return !hasErrors;
  }


  Future<bool> submitBooking() async {
    if (_trip == null || _seat == null || _carriage == null) {
      _submitError = 'Thông tin chuyến tàu không đầy đủ. Vui lòng quay lại.';
      _submitState = BookingSubmitState.error;
      notifyListeners();
      return false;
    }

    if (!validateForm()) return false;

    _submitState = BookingSubmitState.submitting;
    _submitError = null;
    notifyListeners();

    try {
      final request = CreateBookingRequest(
        tripId: _trip!.id,
        fromStationId: _fromStationId,
        toStationId: _toStationId,
        seatId: _seat!.id,
        carriageId: _carriage!.id,
        passengerName: _passengerName.trim(),
        passengerIdCard: _passengerIdCard.replaceAll(RegExp(r'\D'), ''),
        passengerPhone: _passengerPhone.replaceAll(RegExp(r'\D'), ''),
        passengerEmail: _passengerEmail.trim().isEmpty ? null : _passengerEmail.trim(),
        passengerType: _passengerType,
        paymentMethod: _paymentMethod,
      );

      _bookingResult = await _bookingService.createBooking(request, _sessionId);
      _submitState = BookingSubmitState.success;

      await _persistBooking(_bookingResult!);

      notifyListeners();
      return true;
    } on AppException catch (e) {
      _submitError = e.message;
      _submitState = BookingSubmitState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _submitError = 'Lỗi không xác định khi đặt vé. Vui lòng thử lại.';
      _submitState = BookingSubmitState.error;
      notifyListeners();
      return false;
    }
  }


  Future<void> _persistBooking(CreateBookingResponse result) async {
    final prefs = await SharedPreferences.getInstance();

    final bookingEntry = {
      'bookingCode': result.bookingCode,
      'finalPrice': result.finalPrice,
      'paymentDeadline': result.paymentDeadline?.toIso8601String(),
      'qrCodeData': result.qrCodeData,
      'trainName': _trip?.trainName ?? '',
      'fromStation': _trip?.fromStation ?? '',
      'toStation': _trip?.toStation ?? '',
      'departureDate': _trip?.departureDate.toIso8601String() ?? '',
      'departureTime': _trip?.departureTime ?? '',
      'arrivalTime': _trip?.arrivalTime ?? '',
      'seatNumber': _seat?.seatNumber ?? '',
      'carriageType': _carriage?.carriageType ?? '',
      'carriageNumber': _carriage?.carriageNumber ?? 0,
      'passengerName': _passengerName,
      'passengerType': _passengerType,
      'savedAt': DateTime.now().toIso8601String(),
    };

    final existing = prefs.getStringList(ApiConstants.keyMyBookings) ?? [];
    existing.insert(0, jsonEncode(bookingEntry));
    if (existing.length > 20) existing.removeRange(20, existing.length);
    await prefs.setStringList(ApiConstants.keyMyBookings, existing);

    _savedBookings.insert(0, bookingEntry);
    if (_savedBookings.length > 20) _savedBookings = _savedBookings.sublist(0, 20);
  }

  Future<void> loadSavedBookings() async {
    _isFetchingBookings = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.keyJwtToken);

    if (token != null && token.isNotEmpty) {
      try {
        final apiBookings = await _bookingService.getMyBookings();
        _savedBookings = apiBookings.map((b) {
          return {
            'bookingCode': b['bookingCode'] ?? b['BookingCode'] ?? '',
            'finalPrice': b['finalPrice'] ?? b['FinalPrice'] ?? 0,
            'qrCodeData': b['qrCodeData'] ?? b['QrCodeData'],
            'trainName': b['trainName'] ?? b['TrainName'] ?? '',
            'fromStation': b['fromStation'] ?? b['FromStation'] ?? '',
            'toStation': b['toStation'] ?? b['ToStation'] ?? '',
            'departureDate': b['departureDate'] ?? b['DepartureDate'] ?? '',
            'departureTime': b['departureTime'] ?? b['DepartureTime'] ?? '',
            'arrivalTime': b['arrivalTime'] ?? b['ArrivalTime'] ?? '',
            'seatNumber': b['seatNumber'] ?? b['SeatNumber'] ?? '',
            'passengerName': b['passengerName'] ?? b['PassengerName'] ?? '',
            'savedAt': b['createdAt'] ?? b['CreatedAt'] ?? '',
          };
        }).toList();
        
        _isFetchingBookings = false;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Lấy vé từ server thất bại, dùng local fallback: $e');
      }
    }

    final list = prefs.getStringList(ApiConstants.keyMyBookings) ?? [];
    _savedBookings = list.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
    
    _isFetchingBookings = false;
    notifyListeners();
  }

  void _resetForm() {
    _passengerName = '';
    _passengerIdCard = '';
    _passengerPhone = '';
    _passengerEmail = '';
    _passengerType = 'adult';
    _paymentMethod = 'qr_transfer';
    _fieldErrors.updateAll((_, __) => null);
    _submitState = BookingSubmitState.idle;
    _submitError = null;
    _bookingResult = null;
  }

  void resetSubmitState() {
    _submitState = BookingSubmitState.idle;
    _submitError = null;
    notifyListeners();
  }
}
