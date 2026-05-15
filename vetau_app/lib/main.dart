/// main.dart – Entry point của ứng dụng
///
/// Khởi tạo:
///   1. DioClient (Interceptors)
///   2. AuthProvider (restore session từ SharedPreferences)
///   3. MultiProvider bọc toàn bộ app
///   4. GoRouter với các route
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/trip_provider.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/search_result/search_result_screen.dart';
import 'presentation/screens/seat_selection/seat_selection_screen.dart';
import 'presentation/screens/booking/passenger_form_screen.dart';
import 'presentation/screens/booking/booking_confirm_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/my_tickets/my_tickets_screen.dart';
import 'presentation/screens/admin/admin_layout.dart';
import 'presentation/providers/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cố định portrait mode cho mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Khởi tạo Dio với interceptors
  await DioClient.instance.init();

  // Khởi tạo AuthProvider để restore session nếu có
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const VetauApp(),
    ),
  );
}

// ═══════════════════════════════════════════════
// ROUTER
// ═══════════════════════════════════════════════

final GoRouter _router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // Màn hình tìm kiếm (Home)
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Kết quả tìm kiếm chuyến tàu
    GoRoute(
      path: '/search-result',
      name: 'search-result',
      builder: (context, state) => const SearchResultScreen(),
    ),

    // Chọn ghế
    GoRoute(
      path: '/seat-selection',
      name: 'seat-selection',
      builder: (context, state) => const SeatSelectionScreen(),
    ),

    // Form hành khách
    GoRoute(
      path: '/passenger-form',
      name: 'passenger-form',
      builder: (context, state) => const PassengerFormScreen(),
    ),

    // Xác nhận & QR
    GoRoute(
      path: '/booking-success',
      name: 'booking-success',
      builder: (context, state) => const BookingConfirmScreen(),
    ),

    // Đăng nhập
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Vé của tôi
    GoRoute(
      path: '/my-tickets',
      name: 'my-tickets',
      builder: (context, state) => const MyTicketsScreen(),
    ),

    // Admin Panel
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminLayout(),
    ),
  ],
);

// ═══════════════════════════════════════════════
// APP WIDGET
// ═══════════════════════════════════════════════

class VetauApp extends StatelessWidget {
  const VetauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vé Tàu – Đặt vé tàu nhanh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,

      // SEO / Accessibility
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

// ── Admin placeholder (sẽ thay thế ở Phase Admin) ──
class _AdminPlaceholder extends StatelessWidget {
  const _AdminPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Quản trị hệ thống'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.admin_panel_settings,
              color: AppTheme.primary, size: 64),
          SizedBox(height: 16),
          Text('Màn hình Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          Text('Sẽ được triển khai ở Phase tiếp theo',
              style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}

