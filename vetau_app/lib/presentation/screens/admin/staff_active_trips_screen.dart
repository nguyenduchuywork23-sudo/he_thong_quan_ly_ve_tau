/// StaffActiveTripsScreen – Chuyến tàu đang hoạt động
/// GET /api/Staff/active-trips (StaffProvider)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/staff_provider.dart';

class StaffActiveTripsScreen extends StatefulWidget {
  const StaffActiveTripsScreen({super.key});
  @override
  State<StaffActiveTripsScreen> createState() => _StaffActiveTripsScreenState();
}

class _StaffActiveTripsScreenState extends State<StaffActiveTripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadActiveTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(builder: (ctx, sp, _) {
      if (sp.tripsState == StaffLoadState.loading && sp.activeTrips.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: AppTheme.success));
      }
      if (sp.tripsState == StaffLoadState.error && sp.activeTrips.isEmpty) {
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(sp.tripsError ?? 'Lỗi tải dữ liệu',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => sp.loadActiveTrips(force: true),
              child: const Text('Thử lại'),
            ),
          ],
        ));
      }
      if (sp.activeTrips.isEmpty) {
        return const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.train_outlined, color: AppTheme.textHint, size: 64),
            SizedBox(height: 12),
            Text('Không có chuyến tàu đang chạy',
                style: TextStyle(color: AppTheme.textSecondary,
                    fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Chưa có chuyến nào hoạt động hôm nay',
                style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
          ],
        ));
      }

      return RefreshIndicator(
        color: AppTheme.success,
        backgroundColor: AppTheme.cardColor,
        onRefresh: () => sp.loadActiveTrips(force: true),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: sp.activeTrips.length,
          itemBuilder: (_, i) {
            final trip = sp.activeTrips[i];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.success.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.train,
                      color: AppTheme.success, size: 24),
                ),
                title: Text('${trip.trainName} (${trip.trainCode}) – ${trip.routeName}',
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${trip.fromStation} → ${trip.toStation}',
                        style: const TextStyle(fontSize: 12,
                            color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.access_time_outlined,
                          size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text('${trip.departureTime} – ${trip.arrivalTime}',
                          style: const TextStyle(fontSize: 11,
                              color: AppTheme.textHint)),
                    ]),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.success.withOpacity(0.4)),
                      ),
                      child: const Text('Đang chạy',
                          style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.success)),
                    ),
                    const SizedBox(height: 4),
                    Text('${trip.passengerCount} khách',
                        style: const TextStyle(fontSize: 11,
                            color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
