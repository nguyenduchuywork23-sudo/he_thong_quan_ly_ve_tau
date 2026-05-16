/// StaffPendingScreen – Danh sách đơn vé chờ duyệt
/// GET /api/Staff/pending-bookings
/// PUT /api/Staff/bookings/{id}/approve
/// PUT /api/Staff/bookings/{id}/reject
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/staff_provider.dart';

class StaffPendingScreen extends StatefulWidget {
  const StaffPendingScreen({super.key});
  @override
  State<StaffPendingScreen> createState() => _StaffPendingScreenState();
}

class _StaffPendingScreenState extends State<StaffPendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadPendingBookings();
    });
  }

  Future<void> _approve(BuildContext ctx, int bookingId, String code) async {
    final ok = await ctx.read<StaffProvider>().approveBooking(bookingId);
    if (!ctx.mounted) return;
    _showSnack(ctx, ok ? 'Đã duyệt đơn $code' : ctx.read<StaffProvider>().actError ?? 'Lỗi', ok);
  }

  Future<void> _reject(BuildContext ctx, int bookingId, String code) async {
    // Hỏi lý do
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.cardBorder)),
        title: const Text('Từ chối đơn vé',
            style: TextStyle(color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Đơn: $code', style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Lý do từ chối (tùy chọn)',
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true || !ctx.mounted) return;
    final reason = reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();
    final ok = await ctx.read<StaffProvider>().rejectBooking(bookingId, reason: reason);
    if (!ctx.mounted) return;
    _showSnack(ctx, ok ? 'Đã từ chối đơn $code' : ctx.read<StaffProvider>().actError ?? 'Lỗi', ok);
  }

  void _showSnack(BuildContext ctx, String msg, bool ok) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(builder: (ctx, sp, _) {
      if (sp.isPendingLoading && sp.pendingBookings.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: AppTheme.success));
      }
      if (sp.pendingState == StaffLoadState.error && sp.pendingBookings.isEmpty) {
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(sp.pendingError ?? 'Lỗi tải dữ liệu',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => sp.loadPendingBookings(force: true),
              child: const Text('Thử lại'),
            ),
          ],
        ));
      }
      if (sp.pendingBookings.isEmpty) {
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: AppTheme.success, size: 64),
            const SizedBox(height: 12),
            const Text('Không có đơn nào chờ duyệt',
                style: TextStyle(color: AppTheme.textSecondary,
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Tất cả đơn đã được xử lý!',
                style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
          ],
        ));
      }

      return RefreshIndicator(
        color: AppTheme.success,
        backgroundColor: AppTheme.cardColor,
        onRefresh: () => sp.loadPendingBookings(force: true),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: sp.pendingBookings.length,
          itemBuilder: (_, i) {
            final b = sp.pendingBookings[i];
            final id = (b['id'] as num?)?.toInt() ?? 0;
            final code = b['bookingCode'] as String? ?? '#$id';
            final name = b['passengerName'] as String? ?? '';
            final phone = b['passengerPhone'] as String? ?? '';
            final trainName = b['trainName'] as String? ?? '';
            final from = b['fromStation'] as String? ?? '';
            final to = b['toStation'] as String? ?? '';
            final dep = b['departureDate'] as String? ?? '';
            final price = (b['finalPrice'] as num?)?.toDouble() ?? 0.0;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                    color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.warning.withOpacity(0.4)),
                      ),
                      child: Text(code, style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900,
                          color: AppTheme.warning)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name, style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis)),
                    Text('${(price / 1000).toStringAsFixed(0)}K₫',
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success)),
                  ]),
                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.cardBorder, height: 1),
                  const SizedBox(height: 8),

                  // Trip info
                  Row(children: [
                    const Icon(Icons.train_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(child: Text('$trainName · $from → $to',
                        style: const TextStyle(fontSize: 12,
                            color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(dep, style: const TextStyle(fontSize: 12,
                        color: AppTheme.textSecondary)),
                    const SizedBox(width: 16),
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(phone, style: const TextStyle(fontSize: 12,
                        color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: sp.isActing
                          ? null : () => _reject(ctx, id, code),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Từ chối'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          minimumSize: const Size(0, 40)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: sp.isActing
                          ? null : () => _approve(ctx, id, code),
                      icon: sp.isActing
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, size: 16),
                      label: const Text('Duyệt'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          minimumSize: const Size(0, 40)),
                    )),
                  ]),
                ]),
              ),
            );
          },
        ),
      );
    });
  }
}
