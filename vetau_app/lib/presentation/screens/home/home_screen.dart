/// HomeScreen – Màn hình tìm kiếm chuyến tàu (Mobile-first)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/trip_model.dart';
import '../../../presentation/providers/trip_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/widgets/station_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  StationModel? _fromStation;
  StationModel? _toStation;
  DateTime _selectedDate = DateTime.now();
  bool _isRoundTrip = false;

  late AnimationController _swapCtrl;
  late Animation<double> _swapAnim;

  @override
  void initState() {
    super.initState();
    _swapCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _swapAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swapCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadStations();
    });
  }

  @override
  void dispose() {
    _swapCtrl.dispose();
    super.dispose();
  }

  void _swap() {
    _swapCtrl.forward(from: 0);
    setState(() {
      final t = _fromStation;
      _fromStation = _toStation;
      _toStation = t;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _search() async {
    if (_fromStation == null) { _snack('Vui lòng chọn ga đi'); return; }
    if (_toStation == null) { _snack('Vui lòng chọn ga đến'); return; }
    if (_fromStation!.code == _toStation!.code) {
      _snack('Ga đi và ga đến không được trùng'); return;
    }
    final tp = context.read<TripProvider>();
    await tp.searchTrips(
      fromStationCode: _fromStation!.code,
      toStationCode: _toStation!.code,
      date: _selectedDate,
    );
    if (!mounted) return;
    if (tp.searchState == TripLoadState.loaded) {
      context.push('/search-result');
    } else if (tp.searchError != null) {
      _snack(tp.searchError!);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.cardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          // Decorative blobs
          Positioned(top: -80, right: -60,
            child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.08)))),
          Positioned(bottom: 120, left: -80,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.05)))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: AppTheme.spacingL),
                    _Header(),
                    const SizedBox(height: 32),
                    Text('Chuyến đi nào\nbạn muốn?',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            height: 1.2, color: AppTheme.textPrimary, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('Đặt vé tàu nhanh chóng, an toàn',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildCard(),
                    const SizedBox(height: AppTheme.spacingL),
                    _buildSearchBtn(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(children: [
        // Trip type toggle
        Container(
          height: 42,
          decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            _ToggleOpt(label: 'Một chiều', icon: Icons.arrow_forward,
                isSelected: !_isRoundTrip, onTap: () => setState(() => _isRoundTrip = false)),
            _ToggleOpt(label: 'Khứ hồi', icon: Icons.sync_alt,
                isSelected: _isRoundTrip, onTap: () => setState(() => _isRoundTrip = true)),
          ]),
        ),
        const SizedBox(height: AppTheme.spacingM),

        // From station
        _StationTile(
          label: 'Ga đi', station: _fromStation,
          icon: Icons.radio_button_checked, iconColor: AppTheme.primary,
          onTap: () => StationPickerSheet.show(context: context, title: 'Chọn ga đi',
              selected: _fromStation, onSelected: (s) => setState(() => _fromStation = s)),
        ),

        // Swap
        Row(children: [
          Expanded(child: Container(height: 1, color: AppTheme.cardBorder)),
          GestureDetector(
            onTap: _swap,
            child: AnimatedBuilder(
              animation: _swapAnim,
              builder: (_, child) => Transform.rotate(
                  angle: _swapAnim.value * 3.14159, child: child),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12), shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 1.5)),
                child: const Icon(Icons.swap_vert, color: AppTheme.primary, size: 18),
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppTheme.cardBorder)),
        ]),

        // To station
        _StationTile(
          label: 'Ga đến', station: _toStation,
          icon: Icons.location_on, iconColor: AppTheme.warning,
          onTap: () => StationPickerSheet.show(context: context, title: 'Chọn ga đến',
              selected: _toStation, onSelected: (s) => setState(() => _toStation = s)),
        ),

        const Divider(height: 16),

        // Date
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(children: [
              const Icon(Icons.calendar_today, color: AppTheme.info, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Ngày đi', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ])),
              const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearchBtn() {
    return Consumer<TripProvider>(builder: (ctx, tp, _) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.softShadow,
        ),
        child: ElevatedButton(
          onPressed: tp.isSearchLoading ? null : _search,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary, shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
            minimumSize: const Size(double.infinity, 58)),
          child: tp.isSearchLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Text('Tìm chuyến tàu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ]),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════
// Private sub-widgets
// ═══════════════════════════════════════════════

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Logo
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.train, color: Colors.white, size: 20)),
      const SizedBox(width: 8),
      RichText(text: const TextSpan(children: [
        TextSpan(text: 'Vé', style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w800, color: AppTheme.primary)),
        TextSpan(text: 'Tàu', style: TextStyle(fontSize: 20,
            fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      ])),
      const Spacer(),

      // Auth section
      Consumer<AuthProvider>(builder: (ctx, auth, _) {
        // ── Chưa đăng nhập ──
        if (!auth.isAuthenticated) {
          return TextButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login, size: 16, color: AppTheme.primary),
            label: const Text('Đăng nhập',
                style: TextStyle(color: AppTheme.primary, fontSize: 13)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        }

        // ── Đã đăng nhập: Avatar + Dropdown ──
        final initial = auth.user?.fullName.isNotEmpty == true
            ? auth.user!.fullName[0].toUpperCase()
            : 'U';
        final name = auth.user?.fullName ?? 'User';

        return PopupMenuButton<String>(
          offset: const Offset(0, 48),
          color: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          onSelected: (value) async {
            if (value == 'tickets') {
              context.push('/my-tickets');
            } else if (value == 'admin' &&
                (auth.user?.isAdmin == true || auth.user?.isStaff == true)) {
              context.push('/admin');
            } else if (value == 'logout') {
              await auth.logout();
            }
          },
          itemBuilder: (_) => [
            // User info header
            PopupMenuItem<String>(
              enabled: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
                Text(auth.user?.email ?? '',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                if (auth.isStaff)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(auth.isAdmin ? 'Admin' : 'Nhân viên',
                        style: const TextStyle(fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                const Divider(height: 16),
              ]),
            ),
            // Vé của tôi
            const PopupMenuItem<String>(
              value: 'tickets',
              child: Row(children: [
                Icon(Icons.confirmation_number_outlined,
                    size: 18, color: AppTheme.textSecondary),
                SizedBox(width: 10),
                Text('Vé của tôi',
                    style: TextStyle(color: AppTheme.textPrimary,
                        fontSize: 14)),
              ]),
            ),
            // Admin (chỉ hiện nếu là admin/staff)
            if (auth.isStaff)
              const PopupMenuItem<String>(
                value: 'admin',
                child: Row(children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      size: 18, color: AppTheme.textSecondary),
                  SizedBox(width: 10),
                  Text('Quản trị',
                      style: TextStyle(color: AppTheme.textPrimary,
                          fontSize: 14)),
                ]),
              ),
            // Đăng xuất
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout, size: 18, color: AppTheme.error),
                SizedBox(width: 10),
                Text('Đăng xuất',
                    style: TextStyle(color: AppTheme.error, fontSize: 14)),
              ]),
            ),
          ],
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              child: Text(initial, style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w700,
                  fontSize: 15)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                color: AppTheme.textSecondary, size: 20),
          ]),
        );
      }),
    ]);
  }
}


class _StationTile extends StatelessWidget {
  final String label;
  final StationModel? station;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _StationTile({required this.label, required this.station,
      required this.icon, required this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
            const SizedBox(height: 2),
            Text(station?.name ?? 'Chọn $label',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: station != null ? AppTheme.textPrimary : AppTheme.textHint)),
            if (station?.city != null)
              Text(station!.city!, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
          if (station != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(station!.code, style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w700, color: AppTheme.primary)))
          else
            const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
        ]),
      ),
    );
  }
}

class _ToggleOpt extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleOpt({required this.label, required this.icon,
      required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.textHint),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textHint)),
          ]),
        ),
      ),
    );
  }
}
