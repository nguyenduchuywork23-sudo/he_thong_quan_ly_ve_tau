/// AuthProvider – Quản lý trạng thái đăng nhập
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_service.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';

// ─── Simple UserModel ─────────────────────────
/// Ánh xạ từ class User trong Entities.cs
/// (chỉ các field cần thiết cho Client)
class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? idCard;
  final String role; // customer | admin | staff
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.idCard,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      email: (json['email'] ?? json['Email'] ?? '') as String,
      fullName: (json['fullName'] ?? json['FullName'] ?? '') as String,
      phone: json['phone'] as String? ?? json['Phone'] as String?,
      idCard: json['idCard'] as String? ?? json['IdCard'] as String?,
      role: (json['role'] ?? json['Role'] ?? 'customer') as String,
      isActive: (json['isActive'] ?? json['IsActive'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'idCard': idCard,
        'role': role,
        'isActive': isActive,
      };

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff' || role == 'admin';
}

// ═══════════════════════════════════════════════
// AUTH PROVIDER
// ═══════════════════════════════════════════════

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _error;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStaff => _user?.isStaff ?? false;

  // ─── Khởi tạo: kiểm tra token đã lưu ─────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConstants.keyJwtToken);
    final userJson = prefs.getString(ApiConstants.keyUserJson);

    if (token != null && token.isNotEmpty && userJson != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _state = AuthState.authenticated;
      } catch (_) {
        _state = AuthState.unauthenticated;
      }
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // ─── Đăng nhập ────────────────────────────────
  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email: email, password: password);

      // BE trả về { "Token": "...", "User": { ... } }
      final token = data['Token'] as String? ?? data['token'] as String? ?? '';
      final userMap = data['User'] as Map<String, dynamic>? ??
          data['user'] as Map<String, dynamic>? ??
          {};

      _user = UserModel.fromJson(userMap);

      // Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.keyJwtToken, token);
      await prefs.setString(ApiConstants.keyUserJson, jsonEncode(_user!.toJson()));
      await prefs.setString(ApiConstants.keyUserRole, _user!.role);

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Lỗi không xác định khi đăng nhập.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Đăng ký ────────────────────────────────
  Future<bool> register(String email, String password, String fullName) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      final token = data['Token'] as String? ?? data['token'] as String? ?? '';
      final userMap = data['User'] as Map<String, dynamic>? ??
          data['user'] as Map<String, dynamic>? ??
          {};

      _user = UserModel.fromJson(userMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConstants.keyJwtToken, token);
      await prefs.setString(ApiConstants.keyUserJson, jsonEncode(_user!.toJson()));
      await prefs.setString(ApiConstants.keyUserRole, _user!.role);

      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Lỗi không xác định khi đăng ký.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Đăng xuất ────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyJwtToken);
    await prefs.remove(ApiConstants.keyUserJson);
    await prefs.remove(ApiConstants.keyUserRole);
    await prefs.remove(ApiConstants.keySessionId);

    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_state == AuthState.error) _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
