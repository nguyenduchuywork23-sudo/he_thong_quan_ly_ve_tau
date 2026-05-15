/// AdminStationsScreen – Quản lý Ga tàu (Full CRUD)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/trip_model.dart';
import '../../../presentation/providers/admin_provider.dart';

class AdminStationsScreen extends StatefulWidget {
  const AdminStationsScreen({super.key});
  @override
  State<AdminStationsScreen> createState() => _AdminStationsScreenState();
}

class _AdminStationsScreenState extends State<AdminStationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStations();
    });
  }

  // ── Show station form (create or edit) ───────
  Future<void> _showForm(BuildContext ctx, {StationModel? station}) async {
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StationFormSheet(
        station: station,
        onSubmit: (name, code, city, province, sortOrder, isActive) async {
          final ap = ctx.read<AdminProvider>();
          final String? err;
          if (station == null) {
            err = await ap.createStation(
              name: name, code: code, city: city,
              province: province, sortOrder: sortOrder, isActive: isActive,
            );
          } else {
            err = await ap.updateStation(
              station.id,
              name: name, code: code, city: city,
              province: province, sortOrder: sortOrder, isActive: isActive,
            );
          }
          if (!ctx.mounted) return;
          Navigator.pop(ctx); // close sheet
          _showSnackBar(ctx, err == null
              ? '${station == null ? "Thêm" : "Cập nhật"} ga thành công!'
              : err,
              err == null);
        },
      ),
    );
  }

  // ── Show delete confirmation dialog ──────────
  Future<void> _confirmDelete(BuildContext ctx, StationModel station) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cardBorder)),
        title: const Text('Xác nhận xóa',
            style: TextStyle(color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700)),
        content: RichText(text: TextSpan(children: [
          const TextSpan(text: 'Bạn có chắc chắn muốn xóa ga\n',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          TextSpan(text: '${station.name} (${station.code})',
              style: const TextStyle(color: AppTheme.primary,
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const TextSpan(text: '?\n\nHành động này không thể hoàn tác.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !ctx.mounted) return;
    final err = await ctx.read<AdminProvider>().deleteStation(station.id);
    if (ctx.mounted) _showSnackBar(ctx, err ?? 'Đã xóa ga thành công!', err == null);
  }

  void _showSnackBar(BuildContext ctx, String msg, bool ok) {
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
    return Consumer<AdminProvider>(builder: (ctx, ap, _) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: _buildBody(ctx, ap),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: ap.isStationOp ? null : () => _showForm(ctx),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
          label: const Text('Thêm ga',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
    });
  }

  Widget _buildBody(BuildContext ctx, AdminProvider ap) {
    if (ap.stationsState == AdminLoadState.loading && ap.stations.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (ap.stationsState == AdminLoadState.error && ap.stations.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(ap.stationOpError ?? 'Lỗi tải dữ liệu',
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ap.loadStations(force: true),
            child: const Text('Thử lại')),
        ],
      ));
    }

    if (ap.stations.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_outlined,
              color: AppTheme.textHint, size: 56),
          const SizedBox(height: 12),
          const Text('Chưa có ga nào trong hệ thống',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showForm(ctx),
            icon: const Icon(Icons.add),
            label: const Text('Thêm ga đầu tiên'),
          ),
        ],
      ));
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.cardColor,
      onRefresh: () => ap.loadStations(force: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: ap.stations.length,
        itemBuilder: (_, i) => _StationTile(
          station: ap.stations[i],
          onEdit: () => _showForm(ctx, station: ap.stations[i]),
          onDelete: () => _confirmDelete(ctx, ap.stations[i]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// STATION TILE
// ══════════════════════════════════════════════
class _StationTile extends StatelessWidget {
  final StationModel station;
  final VoidCallback onEdit, onDelete;
  const _StationTile({required this.station,
      required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(station.code,
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w900, color: AppTheme.primary),
              textAlign: TextAlign.center),
          ),
        ),
        title: Text(station.name,
            style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (station.city != null || station.province != null)
              Text([station.city, station.province]
                      .whereType<String>().join(', '),
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (station.isActive
                          ? AppTheme.success
                          : AppTheme.error)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (station.isActive
                            ? AppTheme.success
                            : AppTheme.error)
                        .withOpacity(0.3)),
                ),
                child: Text(
                  station.isActive ? 'Hoạt động' : 'Tạm ngừng',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: station.isActive
                        ? AppTheme.success : AppTheme.error),
                ),
              ),
              const SizedBox(width: 8),
              Text('Thứ tự: ${station.sortOrder}',
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textHint)),
            ]),
          ],
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.info, size: 20),
            tooltip: 'Sửa',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.error, size: 20),
            tooltip: 'Xóa',
            onPressed: onDelete,
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// STATION FORM BOTTOM SHEET (Create & Edit)
// ══════════════════════════════════════════════
typedef StationFormCallback = Future<void> Function(
    String name, String code, String? city,
    String? province, int sortOrder, bool isActive);

class _StationFormSheet extends StatefulWidget {
  final StationModel? station;
  final StationFormCallback onSubmit;
  const _StationFormSheet({this.station, required this.onSubmit});
  @override
  State<_StationFormSheet> createState() => _StationFormSheetState();
}

class _StationFormSheetState extends State<_StationFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _sortCtrl;
  late bool _isActive;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.station;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _codeCtrl = TextEditingController(text: s?.code ?? '');
    _cityCtrl = TextEditingController(text: s?.city ?? '');
    _provinceCtrl = TextEditingController(text: s?.province ?? '');
    _sortCtrl = TextEditingController(
        text: (s?.sortOrder ?? 0).toString());
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _codeCtrl.dispose();
    _cityCtrl.dispose(); _provinceCtrl.dispose(); _sortCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.station != null;

  String? _nameErr;
  String? _codeErr;

  void _validate() {
    setState(() {
      _nameErr = _nameCtrl.text.trim().isEmpty ? 'Nhập tên ga' : null;
      _codeErr = _codeCtrl.text.trim().isEmpty
          ? 'Nhập mã ga'
          : _codeCtrl.text.trim().length > 6
              ? 'Tối đa 6 ký tự'
              : null;
    });
  }

  Future<void> _submit() async {
    _validate();
    if (_nameErr != null || _codeErr != null) return;
    setState(() => _submitting = true);
    await widget.onSubmit(
      _nameCtrl.text.trim(),
      _codeCtrl.text.trim().toUpperCase(),
      _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      _provinceCtrl.text.trim().isEmpty ? null : _provinceCtrl.text.trim(),
      int.tryParse(_sortCtrl.text.trim()) ?? 0,
      _isActive,
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20,
          20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),

        Text(_isEdit ? 'Chỉnh sửa ga' : 'Thêm ga mới',
            style: const TextStyle(fontSize: 17,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 20),

        // Tên ga
        _Field(ctrl: _nameCtrl, label: 'Tên ga *',
            hint: 'VD: Ga Hà Nội', icon: Icons.location_on_outlined,
            errorText: _nameErr,
            onChanged: (_) => setState(() => _nameErr = null)),
        const SizedBox(height: 12),

        // Mã ga + Thứ tự
        Row(children: [
          Expanded(child: _Field(
            ctrl: _codeCtrl, label: 'Mã ga *',
            hint: 'VD: HAN', icon: Icons.qr_code,
            errorText: _codeErr,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => setState(() => _codeErr = null),
          )),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: _Field(
            ctrl: _sortCtrl, label: 'Thứ tự',
            hint: '0', icon: Icons.sort,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          )),
        ]),
        const SizedBox(height: 12),

        // Thành phố
        _Field(ctrl: _cityCtrl, label: 'Thành phố',
            hint: 'VD: Hà Nội', icon: Icons.location_city_outlined),
        const SizedBox(height: 12),

        // Tỉnh
        _Field(ctrl: _provinceCtrl, label: 'Tỉnh/Tỉnh thành',
            hint: 'VD: Hà Nội', icon: Icons.map_outlined),
        const SizedBox(height: 12),

        // Active switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(children: [
            const Icon(Icons.toggle_on_outlined,
                color: AppTheme.textHint, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Đang hoạt động',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14))),
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: AppTheme.primary,
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(_isEdit ? Icons.save : Icons.add_location_alt),
            label: Text(_isEdit ? 'Lưu thay đổi' : 'Thêm ga',
                style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
          ),
        ),
      ]),
    );
  }
}

// ── Compact form field ─────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;

  const _Field({
    required this.ctrl, required this.label, required this.hint,
    required this.icon, this.errorText, this.keyboardType,
    this.inputFormatters, this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12,
          fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: const TextStyle(
            color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textHint, size: 18),
          errorText: errorText,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
        ),
      ),
    ],
  );
}
