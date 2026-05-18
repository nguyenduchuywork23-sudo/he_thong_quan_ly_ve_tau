library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/staff_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import 'staff_dashboard_screen.dart';
import 'staff_pending_screen.dart';
import 'staff_active_trips_screen.dart';
import 'staff_passenger_stats_screen.dart';

class StaffLayout extends StatefulWidget {
  const StaffLayout({super.key});
  @override
  State<StaffLayout> createState() => _StaffLayoutState();
}

class _StaffLayoutState extends State<StaffLayout> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabInfo(icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, label: 'Dashboard'),
    _TabInfo(icon: Icons.pending_actions_outlined,
        activeIcon: Icons.pending_actions, label: 'Chờ duyệt'),
    _TabInfo(icon: Icons.train_outlined,
        activeIcon: Icons.train, label: 'Chuyến chạy'),
    _TabInfo(icon: Icons.people_outline,
        activeIcon: Icons.people, label: 'Hành khách'),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      StaffDashboardScreen(),
      StaffPendingScreen(),
      StaffActiveTripsScreen(),
      StaffPassengerStatsScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<StaffProvider>();
      sp.loadDashboard();
      sp.loadPendingBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('STAFF',
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 1.5)),
                ),
                const SizedBox(width: 10),
                Text(_tabs[_currentIndex].label,
                    style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),

                if (user != null) ...[
                  Column(crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(user.fullName,
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const Text('Nhân viên',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(width: 10),
                ],

                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppTheme.textSecondary, size: 20),
                  tooltip: 'Làm mới',
                  onPressed: () => context.read<StaffProvider>().refreshAll(),
                ),
                PopupMenuButton<String>(
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.cardBorder)),
                  icon: const Icon(Icons.more_vert,
                      color: AppTheme.textSecondary, size: 20),
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

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

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
          selectedItemColor: AppTheme.success,
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
