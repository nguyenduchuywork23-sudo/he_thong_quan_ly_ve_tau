/// AdminLayout – Khung điều hướng Admin Panel
///
/// BottomNavigationBar: Dashboard | Vé | Ga tàu | Tàu
/// AppBar tone tối (indigo) để phân biệt với Customer UI
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/admin_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_stations_screen.dart';
import 'admin_trains_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});
  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabInfo(icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, label: 'Dashboard'),
    _TabInfo(icon: Icons.confirmation_number_outlined,
        activeIcon: Icons.confirmation_number, label: 'Vé'),
    _TabInfo(icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on, label: 'Ga tàu'),
    _TabInfo(icon: Icons.train_outlined,
        activeIcon: Icons.train, label: 'Tàu'),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      AdminDashboardScreen(),
      AdminBookingsScreen(),
      AdminStationsScreen(),
      AdminTrainsScreen(),
    ];
    // Preload dashboard & bookings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ap = context.read<AdminProvider>();
      ap.loadDashboard();
      ap.loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.background,

      // ── Admin AppBar (indigo tone) ────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1F4E), Color(0xFF252B6B)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(children: [
                // Admin badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ADMIN',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 1.5)),
                ),
                const SizedBox(width: 10),
                Text(_tabs[_currentIndex].label,
                    style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const Spacer(),

                // User info + logout
                if (user != null) ...[
                  Column(crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(user.fullName,
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    Text(user.role == 'admin' ? 'Quản trị viên' : 'Nhân viên',
                        style: const TextStyle(fontSize: 10,
                            color: Colors.white54)),
                  ]),
                  const SizedBox(width: 10),
                ],

                // Refresh + Logout buttons
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: Colors.white70, size: 20),
                  tooltip: 'Làm mới',
                  onPressed: () => context.read<AdminProvider>().refreshAll(),
                ),
                PopupMenuButton<String>(
                  color: AppTheme.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.cardBorder)),
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white70, size: 20),
                  onSelected: (v) async {
                    if (v == 'home') context.go('/');
                    if (v == 'logout') {
                      await auth.logout();
                      if (mounted) context.go('/');
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'home',
                      child: Row(children: [
                        Icon(Icons.home_outlined, size: 18,
                            color: AppTheme.textSecondary),
                        SizedBox(width: 8),
                        Text('Trang khách hàng',
                            style: TextStyle(color: AppTheme.textPrimary,
                                fontSize: 13)),
                      ])),
                    const PopupMenuItem(value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 18, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text('Đăng xuất',
                            style: TextStyle(color: AppTheme.error,
                                fontSize: 13)),
                      ])),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),

      // ── Content ──────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Navigation ─────────────────────
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textHint,
          selectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: _tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon),
            activeIcon: Icon(t.activeIcon),
            label: t.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _TabInfo {
  final IconData icon, activeIcon;
  final String label;
  const _TabInfo({required this.icon, required this.activeIcon,
      required this.label});
}
