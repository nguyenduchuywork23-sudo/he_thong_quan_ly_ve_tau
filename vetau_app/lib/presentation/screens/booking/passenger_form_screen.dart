library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../presentation/providers/trip_provider.dart';

class PassengerFormScreen extends StatefulWidget {
  const PassengerFormScreen({super.key});
  @override
  State<PassengerFormScreen> createState() => _PassengerFormScreenState();
}

class _PassengerFormScreenState extends State<PassengerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocus = FocusNode();
  final _idFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _idFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final bp = context.read<BookingProvider>();
    if (!bp.validateForm()) return;

    final success = await bp.submitBooking();
    if (!mounted) return;
    if (success) {
      context.pushReplacement('/booking-success');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(bp.submitError ?? 'Đặt vé thất bại. Vui lòng thử lại.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingProvider, TripProvider>(
      builder: (ctx, bp, tp, _) {
        return Stack(children: [
          Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.surface,
              title: const Text('Thông tin hành khách'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppTheme.spacingM,
                    right: AppTheme.spacingM,
                    top: AppTheme.spacingM,
                    bottom: AppTheme.spacingM + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  _TripSummaryCard(bp: bp, tp: tp),
                  const SizedBox(height: AppTheme.spacingM),

                  _SectionTitle('Loại hành khách'),
                  _PassengerTypeSelector(bp: bp),
                  const SizedBox(height: AppTheme.spacingM),

                  _SectionTitle('Thông tin hành khách'),
                  const SizedBox(height: 8),

                  _FormField(
                    label: 'Họ và tên *',
                    hint: 'Nhập họ tên đầy đủ',
                    icon: Icons.person_outline,
                    errorText: bp.fieldErrors['passengerName'],
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.words,
                    onChanged: bp.setPassengerName,
                    nextFocus: _idFocus,
                    inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  ),
                  const SizedBox(height: 12),

                  _FormField(
                    label: 'Số CMND / CCCD *',
                    hint: '9 hoặc 12 chữ số',
                    icon: Icons.badge_outlined,
                    errorText: bp.fieldErrors['passengerIdCard'],
                    focusNode: _idFocus,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    onChanged: bp.setPassengerIdCard,
                    nextFocus: _phoneFocus,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 12),

                  _FormField(
                    label: 'Số điện thoại *',
                    hint: '0xxxxxxxxx (10 số)',
                    icon: Icons.phone_outlined,
                    errorText: bp.fieldErrors['passengerPhone'],
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: bp.setPassengerPhone,
                    nextFocus: _emailFocus,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 12),

                  _FormField(
                    label: 'Email (không bắt buộc)',
                    hint: 'example@email.com',
                    icon: Icons.email_outlined,
                    errorText: bp.fieldErrors['passengerEmail'],
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: bp.setPassengerEmail,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  _SectionTitle('Phương thức thanh toán'),
                  const SizedBox(height: 8),
                  _PaymentMethodCard(bp: bp),
                  const SizedBox(height: AppTheme.spacingM),

                  _PriceSummary(bp: bp),
                  const SizedBox(height: AppTheme.spacingL),

                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      boxShadow: [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: bp.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Xác nhận đặt vé',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      if (bp.isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Đang xử lý đặt vé...',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  final BookingProvider bp;
  final TripProvider tp;
  const _TripSummaryCard({required this.bp, required this.tp});

  @override
  Widget build(BuildContext context) {
    final trip = bp.trip;
    final seat = bp.seat;
    final carriage = bp.carriage;
    if (trip == null || seat == null) {
      return const SizedBox.shrink();
    }

    final price = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.train, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(trip.trainName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(trip.departureTime, style: const TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            Text(trip.fromStation, style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          Column(children: [
            const Icon(Icons.arrow_forward, color: AppTheme.primary, size: 16),
            Text(trip.durationFormatted, style: const TextStyle(
                fontSize: 10, color: AppTheme.textHint)),
          ]),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Text(trip.arrivalTime, style: const TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            Text(trip.toStation, style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
          ])),
        ]),
        const Divider(height: 20),
        Row(children: [
          _InfoPill(Icons.event_seat, 'Ghế ${seat.seatNumber}'),
          const SizedBox(width: 8),
          if (carriage != null)
            _InfoPill(Icons.train_outlined,
                'Toa ${carriage.carriageNumber} – ${carriage.displayName.split('\n').last}'),
        ]),
        const SizedBox(height: 8),
        if (tp.isSeatLocked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.timer, color: AppTheme.warning, size: 14),
              const SizedBox(width: 6),
              Text('Giữ chỗ còn: ${tp.lockCountdownFormatted}',
                  style: const TextStyle(color: AppTheme.warning,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight,
          child: Text(price.format(seat.price),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.primary))),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppTheme.textHint),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]),
  );
}

class _PassengerTypeSelector extends StatelessWidget {
  final BookingProvider bp;
  const _PassengerTypeSelector({required this.bp});

  static const types = [
    ('adult', 'Người lớn', Icons.person),
    ('child', 'Trẻ em', Icons.child_care),
    ('elderly', 'Người cao tuổi', Icons.elderly),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(children: types.map((t) {
      final isSelected = bp.passengerType == t.$1;
      return Expanded(
        child: GestureDetector(
          onTap: () => bp.setPassengerType(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withOpacity(0.12) : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                  width: isSelected ? 1.5 : 1),
            ),
            child: Column(children: [
              Icon(t.$3, size: 20,
                  color: isSelected ? AppTheme.primary : AppTheme.textHint),
              const SizedBox(height: 4),
              Text(t.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary)),
            ]),
          ),
        ),
      );
    }).toList());
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final String? errorText;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String) onChanged;

  const _FormField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.errorText,
    this.focusNode,
    this.nextFocus,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        focusNode: focusNode,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        onChanged: onChanged,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textHint, size: 20),
          errorText: errorText,
          errorStyle: const TextStyle(color: AppTheme.error, fontSize: 11),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            borderSide: const BorderSide(color: AppTheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            borderSide: const BorderSide(color: AppTheme.error, width: 2),
          ),
        ),
      ),
    ]);
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final BookingProvider bp;
  const _PaymentMethodCard({required this.bp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.qr_code, color: AppTheme.primary, size: 22)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text('Chuyển khoản QR', style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text('Quét mã QR để thanh toán sau khi đặt vé',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
        const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
      ]),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final BookingProvider bp;
  const _PriceSummary({required this.bp});

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final seatPrice = bp.seat?.price ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(children: [
        _PriceRow('Giá vé', price.format(seatPrice)),
        _PriceRow('Phí dịch vụ', price.format(0)),
        const Divider(height: 20),
        Row(children: [
          const Text('Tổng cộng', style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const Spacer(),
          Text(price.format(seatPrice), style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ]),
      ]),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13,
          fontWeight: FontWeight.w600)),
    ]),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 15,
        fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
  );
}
