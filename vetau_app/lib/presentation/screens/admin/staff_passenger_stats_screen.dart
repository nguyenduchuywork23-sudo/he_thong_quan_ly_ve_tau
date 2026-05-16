/// StaffPassengerStatsScreen – Thống kê hành khách
/// GET /api/Staff/passenger-stats (StaffProvider)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/staff_provider.dart';

class StaffPassengerStatsScreen extends StatefulWidget {
  const StaffPassengerStatsScreen({super.key});
  @override
  State<StaffPassengerStatsScreen> createState() =>
      _StaffPassengerStatsScreenState();
}

class _StaffPassengerStatsScreenState
    extends State<StaffPassengerStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadPassengerStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(builder: (ctx, sp, _) {
      if (sp.statsState == StaffLoadState.loading && sp.passengerStats == null) {
        return const Center(
            child: CircularProgressIndicator(color: AppTheme.success));
      }
      if (sp.statsState == StaffLoadState.error && sp.passengerStats == null) {
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(sp.statsError ?? 'Lỗi tải dữ liệu',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => sp.loadPassengerStats(force: true),
              child: const Text('Thử lại'),
            ),
          ],
        ));
      }

      final stats = sp.passengerStats;
      if (stats == null) {
        return const Center(child: Text('Không có dữ liệu',
            style: TextStyle(color: AppTheme.textSecondary)));
      }

      // Tỷ lệ trên tàu
      final onboardRatio = stats.totalPassengers > 0
          ? stats.onBoardCount / stats.totalPassengers
          : 0.0;

      return RefreshIndicator(
        color: AppTheme.success,
        backgroundColor: AppTheme.cardColor,
        onRefresh: () => sp.loadPassengerStats(force: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Total card ────────────────────────
            _BigStatCard(
              label: 'Tổng hành khách hôm nay',
              value: stats.totalPassengers.toString(),
              icon: Icons.people,
              color: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 12),

            // ── On board & Waiting ─────────────────
            Row(children: [
              Expanded(child: _BigStatCard(
                label: 'Đang trên tàu',
                value: stats.onBoardCount.toString(),
                icon: Icons.airline_seat_recline_normal,
                color: AppTheme.success,
              )),
              const SizedBox(width: 10),
              Expanded(child: _BigStatCard(
                label: 'Chờ lên tàu',
                value: stats.waitingCount.toString(),
                icon: Icons.schedule,
                color: AppTheme.warning,
              )),
            ]),
            const SizedBox(height: 20),

            // ── Progress bar ──────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    const Text('Tỷ lệ đã lên tàu',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text('${(onboardRatio * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: onboardRatio,
                      minHeight: 10,
                      backgroundColor: AppTheme.cardBorder,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Text('Đã lên: ${stats.onBoardCount}',
                        style: const TextStyle(fontSize: 11,
                            color: AppTheme.textHint)),
                    Text('Tổng: ${stats.totalPassengers}',
                        style: const TextStyle(fontSize: 11,
                            color: AppTheme.textHint)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BigStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _BigStatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 32,
            fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12,
            color: AppTheme.textSecondary)),
      ]),
    );
  }
}
