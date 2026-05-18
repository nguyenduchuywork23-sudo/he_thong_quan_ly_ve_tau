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
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/my_tickets/my_tickets_screen.dart';
import 'presentation/screens/admin/admin_layout.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/providers/staff_provider.dart';
import 'presentation/screens/admin/staff_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await DioClient.instance.init();

  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: const VetauApp(),
    ),
  );
}


final GoRouter _router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/search-result',
      name: 'search-result',
      builder: (context, state) => const SearchResultScreen(),
    ),

    GoRoute(
      path: '/seat-selection',
      name: 'seat-selection',
      builder: (context, state) => const SeatSelectionScreen(),
    ),

    GoRoute(
      path: '/passenger-form',
      name: 'passenger-form',
      builder: (context, state) => const PassengerFormScreen(),
    ),

    GoRoute(
      path: '/booking-success',
      name: 'booking-success',
      builder: (context, state) => const BookingConfirmScreen(),
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),

    GoRoute(
      path: '/my-tickets',
      name: 'my-tickets',
      builder: (context, state) => const MyTicketsScreen(),
    ),

    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminLayout(),
    ),

    GoRoute(
      path: '/staff',
      name: 'staff',
      builder: (context, state) => const StaffLayout(),
    ),
  ],
);


class VetauApp extends StatelessWidget {
  const VetauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vé Tàu – Đặt vé tàu nhanh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,

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

