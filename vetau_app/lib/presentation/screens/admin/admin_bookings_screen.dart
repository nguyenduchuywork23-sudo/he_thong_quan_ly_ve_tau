/// AdminBookingsScreen – Quản lý vé toàn hệ thống
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/admin_provider.dart';
import '../../../data/models/admin_model.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});
  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadBookings();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showConfirmDialog(BuildContext ctx, AdminBooking booking) async {
    final ap = ctx.read<AdminProvider>();
    final action = await showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _BookingActionDialog(booking: booking),
    );
    if (action == null || !mounted) return;

    final ok = await ap.updateBookingStatus(booking.id, action);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Vé ${booking.bookingCode}: đã cập nhật → $action'
          : ap.updateError ?? 'Cập nhật thất bại'),
      backgroundColor: ok ? AppTheme.success : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
    if (!ok) ap.clearUpdateError();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(builder: (ctx, ap, _) {
      return Column(children: [
        // ── Filter & Search bar ─────────────────
        _FilterBar(ap: ap, searchCtrl: _searchCtrl),

        // ── Content ─────────────────────────────
        Expanded(child: _buildBody(ctx, ap)),
      ]);
    });
  }

  Widget _buildBody(BuildContext ctx, AdminProvider ap) {
    if (ap.isBookingsLoading && ap.allBookings.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (ap.bookingsState == AdminLoadState.error && ap.allBookings.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(ap.bookingsError ?? 'Lỗi tải dữ liệu',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ap.loadBookings(force: true),
            child: const Text('Thử lại'),
          ),
        ],
      ));
    }

    final list = ap.bookings;
    if (list.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: AppTheme.textHint, size: 48),
          const SizedBox(height: 12),
          const Text('Không tìm thấy vé nào',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ));
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      onRefresh: () => ap.loadBookings(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: list.length,
        itemBuilder: (_, i) => _AdminBookingCard(
          booking: list[i],
          onTap: () => _showConfirmDialog(ctx, list[i]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// FILTER BAR
// ══════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final AdminProvider ap;
  final TextEditingController searchCtrl;
  const _FilterBar({required this.ap, required this.searchCtrl});

  static const _filters = [
    ('all', 'Tất cả'),
    ('Pending', 'Chờ duyệt'),
    ('Confirmed', 'Đã xác nhận'),
    ('Cancelled', 'Đã huỷ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: searchCtrl,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            onChanged: ap.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Tìm mã vé, tên, SĐT...',
              prefixIcon: const Icon(Icons.search,
                  color: AppTheme.textHint, size: 18),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppTheme.textHint, size: 16),
                      onPressed: () {
                        searchCtrl.clear();
                        ap.setSearchQuery('');
                      })
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
            ),
          ),
        ),
        // Status filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _filters.map((f) {
              final isSelected = ap.statusFilter == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ap.setStatusFilter(f.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.cardBorder),
                    ),
                    child: Text(f.$2, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Count
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${ap.bookings.length} vé',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textHint)),
          ),
        ),
        const Divider(height: 1),
      ]),
    );
  }
}

// ══════════════════════════════════════════════
// BOOKING CARD
// ══════════════════════════════════════════════
class _AdminBookingCard extends StatelessWidget {
  final AdminBooking booking;
  final VoidCallback onTap;
  const _AdminBookingCard({required this.booking, required this.onTap});

  Color get _statusColor {
    if (booking.isPending) return AppTheme.warning;
    if (booking.isConfirmed) return AppTheme.success;
    return AppTheme.error;
  }

  String get _statusLabel {
    if (booking.isPending) return 'Chờ xác nhận';
    if (booking.isConfirmed) return 'Đã xác nhận';
    return 'Đã huỷ';
  }

  IconData get _statusIcon {
    if (booking.isPending) return Icons.hourglass_empty;
    if (booking.isConfirmed) return Icons.check_circle;
    return Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFmt = DateFormat('HH:mm dd/MM/yyyy');

    return GestureDetector(
      onTap: booking.isPending ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: booking.isPending
                ? AppTheme.warning.withOpacity(0.4)
                : AppTheme.cardBorder,
            width: 0.5,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(children: [
          // ── Header ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // Booking code
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.bookingCode, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: AppTheme.primary, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(dateFmt.format(booking.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint)),
                ],
              )),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_statusIcon, size: 12, color: _statusColor),
                  const SizedBox(width: 4),
                  Text(_statusLabel, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: _statusColor)),
                ]),
              ),
            ]),
          ),

          const Divider(height: 1),

          // ── Body ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              // Passenger
              Row(children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Expanded(child: Text(booking.passengerName,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary))),
                Text(booking.passengerPhone,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ]),
              const SizedBox(height: 8),
              // Route
              Row(children: [
                const Icon(Icons.train, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Expanded(child: Text(
                    '${booking.fromStation} → ${booking.toStation}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Text('${booking.departureTime} • Ghế ${booking.seatNumber}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const Spacer(),
                Text(priceFmt.format(booking.totalPrice),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
              ]),
            ]),
          ),

          // ── Action hint (Pending only) ─────────
          if (booking.isPending)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.radiusCard)),
                border: const Border(
                    top: BorderSide(color: AppTheme.cardBorder)),
              ),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.touch_app,
                    size: 13, color: AppTheme.warning),
                SizedBox(width: 6),
                Text('Nhấn để xác nhận hoặc huỷ vé',
                    style: TextStyle(fontSize: 11,
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// CONFIRM / CANCEL DIALOG
// ══════════════════════════════════════════════
class _BookingActionDialog extends StatelessWidget {
  final AdminBooking booking;
  const _BookingActionDialog({required this.booking});

  @override
  Widget build(BuildContext context) {
    final priceFmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cardBorder)),
      title: Column(children: [
        const Icon(Icons.confirmation_number,
            color: AppTheme.primary, size: 36),
        const SizedBox(height: 8),
        const Text('Xử lý vé', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        Text(booking.bookingCode, style: const TextStyle(
            fontSize: 14, color: AppTheme.primary,
            fontWeight: FontWeight.w700, letterSpacing: 1)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _DialogRow('Hành khách', booking.passengerName),
        _DialogRow('Hành trình',
            '${booking.fromStation} → ${booking.toStation}'),
        _DialogRow('Ghế', '${booking.seatNumber} (${booking.carriageType})'),
        _DialogRow('Số tiền', priceFmt.format(booking.totalPrice)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 14, color: AppTheme.warning),
            SizedBox(width: 6),
            Expanded(child: Text(
                'Sau khi xác nhận, vé sẽ không thể hoàn tác.',
                style: TextStyle(fontSize: 11, color: AppTheme.warning))),
          ]),
        ),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        // Cancel booking
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context, 'Cancelled'),
          icon: const Icon(Icons.cancel_outlined,
              size: 16, color: AppTheme.error),
          label: const Text('Huỷ vé',
              style: TextStyle(color: AppTheme.error)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.error),
            minimumSize: const Size(120, 44),
          ),
        ),
        // Confirm payment
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, 'Confirmed'),
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Xác nhận TT'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            minimumSize: const Size(130, 44),
          ),
        ),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label, value;
  const _DialogRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(
          fontSize: 12, color: AppTheme.textHint))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}
