/// MyTicketsScreen – Lịch sử vé đã đặt (đọc từ SharedPreferences)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/booking_provider.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});
  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadSavedBookings();
    });
  }

  void _showQrSheet(BuildContext context, Map<String, dynamic> booking) {
    final code = booking['bookingCode'] as String? ?? '';
    final qrData = booking['qrCodeData'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrBottomSheet(
        bookingCode: code,
        qrCodeData: qrData,
        booking: booking,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Vé của tôi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (ctx, bp, _) {
          if (bp.isFetchingBookings && bp.savedBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final tickets = bp.savedBookings;

          if (tickets.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => context.read<BookingProvider>().loadSavedBookings(),
              child: Stack(
                children: [
                  ListView(), // Cần ListView để Pull-to-refresh hoạt động
                  _EmptyState(),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<BookingProvider>().loadSavedBookings(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tickets.length,
              itemBuilder: (ctx, i) => _TicketCard(
                booking: tickets[i],
                onTap: () => _showQrSheet(context, tickets[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TICKET CARD
// ══════════════════════════════════════════════
class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;
  const _TicketCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final code = booking['bookingCode'] as String? ?? '—';
    final from = booking['fromStation'] as String? ?? '—';
    final to = booking['toStation'] as String? ?? '—';
    final trainName = booking['trainName'] as String? ?? '—';
    final depDate = booking['departureDate'] as String?;
    final depTime = booking['departureTime'] as String? ?? '—';
    final seatNum = booking['seatNumber'] as String? ?? '—';
    final price = booking['finalPrice'];
    final savedAt = booking['savedAt'] as String?;

    final priceFmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    String? formattedDate;
    if (depDate != null) {
      try {
        formattedDate = DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(depDate));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(children: [
          // ── Header: mã đặt chỗ ──────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusCard)),
              border: const Border(
                  bottom: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(children: [
              const Icon(Icons.confirmation_number_outlined,
                  color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(code, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: AppTheme.primary, letterSpacing: 1.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.4)),
                ),
                child: const Text('Đã đặt', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppTheme.success)),
              ),
            ]),
          ),

          // ── Body: route & seat info ──────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Tuyến đường
              Row(children: [
                const Icon(Icons.train, color: AppTheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(trainName,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(from, style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                    const Text('Ga đi', style: TextStyle(
                        fontSize: 11, color: AppTheme.textHint)),
                  ],
                )),
                const Icon(Icons.arrow_forward,
                    color: AppTheme.primary, size: 18),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(to, style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                        textAlign: TextAlign.right),
                    const Text('Ga đến', style: TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                        textAlign: TextAlign.right),
                  ],
                )),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(children: [
                _InfoItem(Icons.calendar_today,
                    formattedDate ?? '—'),
                const SizedBox(width: 16),
                _InfoItem(Icons.access_time, depTime),
                const SizedBox(width: 16),
                _InfoItem(Icons.event_seat, 'Ghế $seatNum'),
                const Spacer(),
                if (price != null)
                  Text(priceFmt.format(price is num ? price : 0),
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary)),
              ]),
            ]),
          ),

          // ── Footer: tap to view QR ───────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radiusCard)),
              border: const Border(
                  top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, color: AppTheme.textHint, size: 16),
                SizedBox(width: 6),
                Text('Nhấn để xem mã QR',
                    style: TextStyle(fontSize: 12,
                        color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppTheme.textHint),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(
          fontSize: 12, color: AppTheme.textSecondary)),
    ],
  );
}

// ══════════════════════════════════════════════
// QR BOTTOM SHEET
// ══════════════════════════════════════════════
class _QrBottomSheet extends StatelessWidget {
  final String bookingCode;
  final String? qrCodeData;
  final Map<String, dynamic> booking;

  const _QrBottomSheet({
    required this.bookingCode,
    required this.qrCodeData,
    required this.booking,
  });

  /// Luôn dùng bookingCode làm dữ liệu QR — tránh lỗi QrInputTooLongException
  /// khi BE trả về chuỗi SVG/Base64 quá dài trong qrCodeData.
  Widget _buildQr() {
    return QrImageView(
      data: 'VETAU|$bookingCode',
      version: QrVersions.auto,
      size: 220,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final from = booking['fromStation'] as String? ?? '';
    final to = booking['toStation'] as String? ?? '';
    final depTime = booking['departureTime'] as String? ?? '';
    final depDate = booking['departureDate'] as String?;
    String? fmtDate;
    try {
      if (depDate != null) {
        fmtDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(depDate));
      }
    } catch (_) {}

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20,
          20 + MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Code
        const Text('MÃ ĐẶT CHỖ', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AppTheme.textHint, letterSpacing: 2)),
        const SizedBox(height: 6),
        Text(bookingCode, style: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.w900,
            color: AppTheme.primary, letterSpacing: 3)),
        const SizedBox(height: 6),
        Text('$from → $to • $depTime${fmtDate != null ? ' • $fmtDate' : ''}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),

        // QR
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildQr(),
        ),
        const SizedBox(height: 16),
        const Text('Xuất trình mã này tại quầy hoặc khi lên tàu',
            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Đóng'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 44)),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 96, height: 96,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder, width: 2),
            ),
            child: const Icon(Icons.confirmation_number_outlined,
                color: AppTheme.textHint, size: 44)),
          const SizedBox(height: 20),
          const Text('Chưa có chuyến đi nào',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Các vé bạn đặt sẽ được lưu tại đây\nđể tiện tra cứu và xuất trình.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 12, offset: const Offset(0, 5))],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Đặt vé ngay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(180, 52),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
