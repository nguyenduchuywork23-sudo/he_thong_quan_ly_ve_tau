library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/staff_provider.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});
  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(builder: (ctx, sp, _) {
      return RefreshIndicator(
        color: AppTheme.success,
        backgroundColor: AppTheme.cardColor,
        onRefresh: () => sp.loadDashboard(force: true),
        child: _buildBody(sp),
      );
    });
  }

  Widget _buildBody(StaffProvider sp) {
    if (sp.isDashLoading && sp.dashStats == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.success));
    }
    if (sp.dashState == StaffLoadState.error && sp.dashStats == null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(sp.dashError ?? 'Lỗi tải dữ liệu',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => sp.loadDashboard(force: true),
            child: const Text('Thử lại'),
          ),
        ],
      ));
    }

    final stats = sp.dashStats;
    if (stats == null) {
      return const Center(child: Text('Không có dữ liệu',
          style: TextStyle(color: AppTheme.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PendingHighlightCard(pendingCount: stats.pendingBookings),
        const SizedBox(height: 16),

        _sectionHeader('Thống kê vé hôm nay'),
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
              label: 'Chờ duyệt',
              value: stats.pendingBookings.toString(),
              icon: Icons.pending_actions,
              color: AppTheme.warning,
              highlight: stats.pendingBookings > 0,
            ),
            _StatCard(
              label: 'Đã xác nhận',
              value: stats.confirmedToday.toString(),
              icon: Icons.check_circle_outline,
              color: AppTheme.success,
            ),
            _StatCard(
              label: 'Đã hủy',
              value: stats.cancelledToday.toString(),
              icon: Icons.cancel_outlined,
              color: AppTheme.error,
            ),
            _StatCard(
              label: 'Chuyến đang chạy',
              value: stats.activeTrips.toString(),
              icon: Icons.train_outlined,
              color: AppTheme.info,
            ),
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader('Hành khách & Doanh thu hôm nay'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _StatCard(
            label: 'Tổng hành khách',
            value: stats.totalPassengersToday.toString(),
            icon: Icons.people_outline,
            color: const Color(0xFF8B5CF6),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(
            label: 'Doanh thu',
            value: '${(stats.revenueToday / 1000).toStringAsFixed(0)}K₫',
            icon: Icons.monetization_on_outlined,
            color: AppTheme.success,
          )),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(String title) => Row(children: [
    Container(width: 3, height: 16,
        decoration: BoxDecoration(color: AppTheme.success,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
  ]);
}

class _PendingHighlightCard extends StatelessWidget {
  final int pendingCount;
  const _PendingHighlightCard({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: pendingCount > 0 ? AppTheme.primaryGradient : null,
        color: pendingCount > 0 ? null : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: pendingCount > 0
              ? AppTheme.warning.withOpacity(0.3)
              : AppTheme.cardBorder,
          width: 0.5,
        ),
        boxShadow: pendingCount > 0 
          ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))] 
          : AppTheme.softShadow,
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: (pendingCount > 0 ? AppTheme.warning : AppTheme.textHint)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.pending_actions,
            color: pendingCount > 0 ? AppTheme.warning : AppTheme.textHint,
            size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text('ĐƠN VÉ CHỜ DUYỆT', style: TextStyle(
              fontSize: 11, color: pendingCount > 0 ? Colors.white54 : AppTheme.textHint,
              fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text('$pendingCount đơn',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                  color: pendingCount > 0 ? AppTheme.warning : AppTheme.textPrimary)),
          if (pendingCount > 0)
            const Text('Cần xử lý ngay!',
                style: TextStyle(fontSize: 12, color: AppTheme.warning)),
        ])),
      ]),
    );
  }
}

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
        color: highlight ? color.withOpacity(0.12) : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: highlight ? color.withOpacity(0.4) : AppTheme.cardBorder,
          width: highlight ? 1.5 : 0.5,
        ),
        boxShadow: highlight ? null : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              ),
              Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
