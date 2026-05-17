/// BookingConfirmScreen – Xác nhận đặt vé thành công & QR thanh toán
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../presentation/providers/trip_provider.dart';

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});
  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn)));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Đã sao chép mã đặt chỗ'),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingProvider, TripProvider>(
      builder: (ctx, bp, tp, _) {
        final result = bp.bookingResult;
        if (result == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                const SizedBox(height: 12),
                const Text('Không tìm thấy thông tin đặt vé.',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Về trang chủ'),
                ),
              ]),
            ),
          );
        }

        final priceFmt = NumberFormat.currency(
            locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
        final trip = bp.trip;
        final seat = bp.seat;
        final carriage = bp.carriage;
        final deadline = result.paymentDeadline;

        return Scaffold(
          backgroundColor: AppTheme.background,
          // Không có back button – WillPopScope ngăn back
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            automaticallyImplyLeading: false,
            title: const Text('Đặt vé thành công'),
            actions: [
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Trang chủ',
                    style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
          body: PopScope(
            canPop: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(children: [
                const SizedBox(height: 8),

                // ── Success Animation ──────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 80, height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 44),
                  ),
                ),
                const SizedBox(height: 16),

                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(children: [
                    const Text('Đặt vé thành công!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Vui lòng thanh toán trước khi hết hạn giữ chỗ.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Booking Code Card ──────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _BookingCodeCard(
                    bookingCode: result.bookingCode,
                    onCopy: () => _copyCode(result.bookingCode),
                  ),
                ),
                const SizedBox(height: 16),

                // ── QR Code Card ───────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _QrCard(
                    qrCodeData: result.qrCodeData,
                    bookingCode: result.bookingCode,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Trip Details Card ──────────────
                if (trip != null)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _TripDetailCard(
                      trip: trip,
                      seat: seat,
                      carriage: carriage,
                      finalPrice: result.finalPrice,
                      priceFmt: priceFmt,
                      passengerName: bp.passengerName,
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Payment deadline ───────────────
                if (deadline != null)
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _DeadlineCard(deadline: deadline),
                  ),
                const SizedBox(height: 24),

                // ── Action buttons ─────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(children: [
                    ElevatedButton.icon(
                      onPressed: () => _copyCode(result.bookingCode),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Sao chép mã đặt chỗ'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52)),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text('Về trang chủ'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52)),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ── Booking code card ─────────────────────────
class _BookingCodeCard extends StatelessWidget {
  final String bookingCode;
  final VoidCallback onCopy;
  const _BookingCodeCard({required this.bookingCode, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 0.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(children: [
        const Text('MÃ ĐẶT CHỖ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.textHint, letterSpacing: 2)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onCopy,
          child: Text(
            bookingCode,
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900,
              color: AppTheme.primary, letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy, size: 14, color: AppTheme.textSecondary),
          label: const Text('Nhấn để sao chép',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ),
      ]),
    );
  }
}

// ── QR code card ─────────────────────────────
class _QrCard extends StatelessWidget {
  final String? qrCodeData;
  final String bookingCode;
  const _QrCard({required this.qrCodeData, required this.bookingCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(children: [
        const Text('MÃ QR THANH TOÁN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.black54, letterSpacing: 2)),
        const SizedBox(height: 16),
        _buildQr(),
        const SizedBox(height: 12),
        const Text('Quét mã để check-in hoặc thanh toán tại ga',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center),
      ]),
    );
  }

  /// Dữ liệu QR = chuỗi ngắn "VETAU|<bookingCode>" — luôn dùng bookingCode
  /// để tránh lỗi QrInputTooLongException khi BE trả SVG/Base64 quá dài.
  String get _qrPayload => 'VETAU|$bookingCode';

  Widget _buildQr() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: _qrPayload,
        version: QrVersions.auto,
        size: 220.0,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}

// ── Trip detail card ──────────────────────────
class _TripDetailCard extends StatelessWidget {
  final dynamic trip, seat, carriage;
  final double finalPrice;
  final NumberFormat priceFmt;
  final String passengerName;
  const _TripDetailCard({
    required this.trip, required this.seat, required this.carriage,
    required this.finalPrice, required this.priceFmt, required this.passengerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('THÔNG TIN VÉ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.textHint, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _Row('Tàu', trip?.trainName ?? '—'),
        _Row('Hành trình', '${trip?.fromStation ?? ''} → ${trip?.toStation ?? ''}'),
        _Row('Ngày đi', trip?.departureDate != null
            ? DateFormat('dd/MM/yyyy').format(trip!.departureDate) : '—'),
        _Row('Giờ khởi hành', trip?.departureTime ?? '—'),
        if (seat != null) _Row('Số ghế', seat?.seatNumber ?? '—'),
        if (carriage != null)
          _Row('Toa', 'Toa ${carriage?.carriageNumber} – '
              '${carriage?.displayName.split('\n').last}'),
        if (passengerName.isNotEmpty) _Row('Hành khách', passengerName),
        const Divider(height: 20),
        Row(children: [
          const Text('TỔNG TIỀN', style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(priceFmt.format(finalPrice), style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 110,
          child: Text(label, style: const TextStyle(
              fontSize: 13, color: AppTheme.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}

// ── Payment deadline card ─────────────────────
class _DeadlineCard extends StatelessWidget {
  final DateTime deadline;
  const _DeadlineCard({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final remaining = deadline.difference(DateTime.now());
    final isExpired = remaining.isNegative;
    final fmt = DateFormat('HH:mm, dd/MM/yyyy');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isExpired ? AppTheme.error : AppTheme.warning).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isExpired ? AppTheme.error : AppTheme.warning).withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(isExpired ? Icons.warning_amber : Icons.access_time,
            color: isExpired ? AppTheme.error : AppTheme.warning, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isExpired ? 'Đã hết hạn thanh toán' : 'Hạn thanh toán',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isExpired ? AppTheme.error : AppTheme.warning)),
          Text(fmt.format(deadline),
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}
