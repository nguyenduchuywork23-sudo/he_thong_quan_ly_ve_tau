/// StationPickerSheet – Bottom Sheet chọn ga tàu
///
/// Load danh sách từ TripProvider.stations (đã gọi API).
/// Nếu stations chưa load → hiển thị text field nhập mã ga thủ công.
/// Hỗ trợ tìm kiếm (search) trong danh sách.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/trip_model.dart';
import '../../presentation/providers/trip_provider.dart';
import '../../core/theme/app_theme.dart';

class StationPickerSheet extends StatefulWidget {
  final String title;
  final StationModel? selected;
  final void Function(StationModel station) onSelected;

  const StationPickerSheet({
    super.key,
    required this.title,
    required this.onSelected,
    this.selected,
  });

  /// Helper để mở bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String title,
    StationModel? selected,
    required void Function(StationModel) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationPickerSheet(
        title: title,
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<StationPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<StationModel> _filtered = [];
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final tp = context.read<TripProvider>();
    if (!tp.stationsLoaded) {
      tp.loadStations().then((_) {
        if (!mounted) return;
        final updated = context.read<TripProvider>();
        if (updated.stationsState == TripLoadState.error) {
          setState(() => _showManualInput = true);
        } else {
          _applyFilter('');
        }
      });
    } else {
      _applyFilter('');
    }
    _searchCtrl.addListener(() => _applyFilter(_searchCtrl.text));
  }

  void _applyFilter(String query) {
    final stations = context.read<TripProvider>().stations;
    setState(() {
      if (query.isEmpty) {
        _filtered = stations;
      } else {
        final q = query.toLowerCase();
        _filtered = stations
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                s.code.toLowerCase().contains(q) ||
                (s.city?.toLowerCase().contains(q) ?? false))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Title ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                child: Row(
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Search Field ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên ga hoặc mã ga...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textHint, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                  ),
                ),
              ),

              const Divider(height: 1),

              // ── Content ────────────────────────────
              Expanded(
                child: _buildContent(scrollCtrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollCtrl) {
    return Consumer<TripProvider>(
      builder: (ctx, tp, _) {
        // Loading state
        if (tp.stationsState == TripLoadState.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        // Error / fallback to manual input
        if (tp.stationsState == TripLoadState.error || _showManualInput) {
          return _ManualStationInput(onSubmit: widget.onSelected);
        }

        // Empty search result
        if (_filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, color: AppTheme.textHint, size: 48),
                const SizedBox(height: 12),
                Text('Không tìm thấy ga "${_searchCtrl.text}"',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        // Station list
        return ListView.separated(
          controller: scrollCtrl,
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
          itemBuilder: (ctx, i) {
            final station = _filtered[i];
            final isSelected = widget.selected?.id == station.id;
            return ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.15)
                      : AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    station.code,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              title: Text(
                station.name,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              subtitle: Text(
                station.city ?? station.province ?? '',
                style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                  : null,
              onTap: () {
                widget.onSelected(station);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}

// ── Fallback: nhập tay khi API stations không truy cập được ──

class _ManualStationInput extends StatefulWidget {
  final void Function(StationModel) onSubmit;
  const _ManualStationInput({required this.onSubmit});

  @override
  State<_ManualStationInput> createState() => _ManualStationInputState();
}

class _ManualStationInputState extends State<_ManualStationInput> {
  final _ctrl = TextEditingController();
  String? _error;

  void _submit() {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length < 2) {
      setState(() => _error = 'Mã ga phải có ít nhất 2 ký tự');
      return;
    }
    widget.onSubmit(StationModel(
      id: 0,
      name: code,
      code: code,
      sortOrder: 0,
      isActive: true,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16,
          16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.train, color: AppTheme.textHint, size: 40),
          const SizedBox(height: 12),
          Text('Nhập mã ga tàu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Ví dụ: HAN (Hà Nội), SGN (Sài Gòn), DAN (Đà Nẵng)',
            style: TextStyle(color: AppTheme.textHint, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Mã ga (VD: HAN)',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: const Text('Xác nhận')),
        ],
      ),
    );
  }
}
