/// AdminTrainsScreen – Danh sách Đoàn tàu (Read-only + Refresh)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/admin_provider.dart';

class AdminTrainsScreen extends StatefulWidget {
  const AdminTrainsScreen({super.key});
  @override
  State<AdminTrainsScreen> createState() => _AdminTrainsScreenState();
}

class _AdminTrainsScreenState extends State<AdminTrainsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadTrains();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (ctx, ap, _) {
      return RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.cardColor,
        onRefresh: () => ap.loadTrains(force: true),
        child: _buildBody(ap),
      );
    });
  }

  Widget _buildBody(AdminProvider ap) {
    // Loading
    if (ap.trainsState == AdminLoadState.loading && ap.trains.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    // Error
    if (ap.trainsState == AdminLoadState.error && ap.trains.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(ap.trainsError ?? 'Không thể tải danh sách tàu',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ap.loadTrains(force: true),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ));
    }

    // Empty
    if (ap.trains.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.train_outlined,
              color: AppTheme.textHint, size: 56),
          const SizedBox(height: 12),
          const Text('Chưa có đoàn tàu nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Kéo xuống để làm mới danh sách',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: ap.trains.length,
      itemBuilder: (_, i) => _TrainCard(data: ap.trains[i]),
    );
  }
}

// ══════════════════════════════════════════════
// TRAIN CARD
// ══════════════════════════════════════════════
class _TrainCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TrainCard({required this.data});

  String _str(String key) =>
      (data[key] ?? data[key[0].toUpperCase() + key.substring(1)] ?? '') as String;

  int _int(String key) {
    final v = data[key] ?? data[key[0].toUpperCase() + key.substring(1)] ?? 0;
    return (v is num) ? v.toInt() : 0;
  }

  bool _bool(String key) {
    final v = data[key] ?? data[key[0].toUpperCase() + key.substring(1)];
    return (v is bool) ? v : true;
  }

  @override
  Widget build(BuildContext context) {
    final name = _str('name');
    final description = _str('description');
    final isActive = _bool('isActive');
    final totalCarriages = _int('totalCarriages');
    final totalSeats = _int('totalSeats');

    // Phân loại tàu từ tên: SE (Thống Nhất), TN (Thống Nhất chậm), etc.
    final trainType = _getTrainType(name);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1A1F4E).withOpacity(0.6)
                : AppTheme.cardColor,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusCard)),
            border: const Border(
                bottom: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: Row(children: [
            // Icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: trainType.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.train, color: trainType.color, size: 22),
            ),
            const SizedBox(width: 12),

            // Name + type
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
                Text(trainType.label, style: TextStyle(
                    fontSize: 12, color: trainType.color,
                    fontWeight: FontWeight.w600)),
              ],
            )),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.success : AppTheme.warning)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isActive ? AppTheme.success : AppTheme.warning)
                      .withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isActive ? Icons.check_circle : Icons.build_circle,
                    size: 12,
                    color: isActive ? AppTheme.success : AppTheme.warning),
                const SizedBox(width: 4),
                Text(isActive ? 'Hoạt động' : 'Bảo trì',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppTheme.success : AppTheme.warning)),
              ]),
            ),
          ]),
        ),

        // Body – stats & description
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            // Stats row
            Row(children: [
              _StatPill(Icons.directions_railway_filled_outlined,
                  '$totalCarriages toa'),
              const SizedBox(width: 10),
              _StatPill(Icons.event_seat_outlined,
                  '$totalSeats ghế'),
              const SizedBox(width: 10),
              _StatPill(Icons.route_outlined, trainType.speed),
            ]),

            // Description
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(description, style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary,
                  height: 1.4)),
            ],
          ]),
        ),
      ]),
    );
  }

  static _TrainTypeInfo _getTrainType(String name) {
    final n = name.toUpperCase();
    if (n.startsWith('SE')) {
      return _TrainTypeInfo('Tàu Thống Nhất', 'Tốc hành',
          const Color(0xFFE8470A));
    }
    if (n.startsWith('TN')) {
      return _TrainTypeInfo('Tàu Thống Nhất', 'Chặng dài',
          const Color(0xFF06B6D4));
    }
    if (n.startsWith('SPT') || n.startsWith('NA')) {
      return _TrainTypeInfo('Tàu Nội địa', 'Chặng ngắn',
          const Color(0xFF8B5CF6));
    }
    return _TrainTypeInfo('Đoàn tàu', 'Phổ thông',
        AppTheme.textSecondary);
  }
}

class _TrainTypeInfo {
  final String label, speed;
  final Color color;
  const _TrainTypeInfo(this.label, this.speed, this.color);
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.cardBorder),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppTheme.textHint),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
          fontSize: 11, color: AppTheme.textSecondary)),
    ]),
  );
}
