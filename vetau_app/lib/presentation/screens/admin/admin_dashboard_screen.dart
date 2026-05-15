/// AdminDashboardScreen – Tổng quan thống kê hệ thống
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/admin_provider.dart';
import '../../../data/models/admin_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (ctx, ap, _) {
      return RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.cardColor,
        onRefresh: () => ap.loadDashboard(force: true),
        child: _buildBody(ap),
      );
    });
  }

  Widget _buildBody(AdminProvider ap) {
    if (ap.isDashLoading && ap.stats == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (ap.dashState == AdminLoadState.error && ap.stats == null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(ap.dashError ?? 'Lỗi tải dữ liệu',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ap.loadDashboard(force: true),
            child: const Text('Thử lại'),
          ),
        ],
      ));
    }

    final stats = ap.stats;
    if (stats == null) {
      return const Center(child: Text('Không có dữ liệu',
          style: TextStyle(color: AppTheme.textSecondary)));
    }

    final priceFmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Revenue highlight ─────────────────
        _RevenueCard(stats: stats, priceFmt: priceFmt),
        const SizedBox(height: 16),

        // ── Booking stats grid ────────────────
        const _SectionHeader('Thống kê vé'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              label: 'Tổng vé',
              value: stats.totalBookings.toString(),
              icon: Icons.confirmation_number,
              color: AppTheme.info,
            ),
            _StatCard(
              label: 'Chờ xác nhận',
              value: stats.pendingBookings.toString(),
              icon: Icons.hourglass_empty,
              color: AppTheme.warning,
              highlight: stats.pendingBookings > 0,
            ),
            _StatCard(
              label: 'Đã xác nhận',
              value: stats.confirmedBookings.toString(),
              icon: Icons.check_circle_outline,
              color: AppTheme.success,
            ),
            _StatCard(
              label: 'Đã huỷ',
              value: stats.cancelledBookings.toString(),
              icon: Icons.cancel_outlined,
              color: AppTheme.error,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Infrastructure ────────────────────
        const _SectionHeader('Cơ sở hạ tầng'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              label: 'Ga tàu',
              value: stats.totalStations.toString(),
              icon: Icons.location_on_outlined,
              color: const Color(0xFF8B5CF6),
            ),
            _StatCard(
              label: 'Đoàn tàu',
              value: stats.totalTrains.toString(),
              icon: Icons.train_outlined,
              color: const Color(0xFF06B6D4),
            ),
            _StatCard(
              label: 'Chuyến chạy',
              value: stats.activeTrips.toString(),
              icon: Icons.route_outlined,
              color: AppTheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Revenue highlight card ─────────────────────
class _RevenueCard extends StatelessWidget {
  final DashboardStats stats;
  final NumberFormat priceFmt;
  const _RevenueCard({required this.stats, required this.priceFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F4E), Color(0xFF2D3494)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.trending_up, color: Colors.white60, size: 16),
          SizedBox(width: 6),
          Text('TỔNG DOANH THU', style: TextStyle(
              fontSize: 11, color: Colors.white54,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 8),
        Text(priceFmt.format(stats.totalRevenue),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                color: Colors.white)),
        const SizedBox(height: 16),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Hôm nay', style: TextStyle(
                fontSize: 11, color: Colors.white54)),
            const SizedBox(height: 4),
            Text(priceFmt.format(stats.todayRevenue),
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700, color: Colors.white)),
          ])),
          Container(width: 1, height: 36, color: Colors.white12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Tỷ lệ xác nhận', style: TextStyle(
                  fontSize: 11, color: Colors.white54)),
              const SizedBox(height: 4),
              Text(stats.totalBookings > 0
                  ? '${((stats.confirmedBookings / stats.totalBookings) * 100).toStringAsFixed(1)}%'
                  : '—',
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          )),
        ]),
      ]),
    );
  }
}

// ── Stat card ─────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool highlight;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.12) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: highlight ? color.withOpacity(0.4) : AppTheme.cardBorder,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 16,
        decoration: BoxDecoration(color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
  ]);
}
