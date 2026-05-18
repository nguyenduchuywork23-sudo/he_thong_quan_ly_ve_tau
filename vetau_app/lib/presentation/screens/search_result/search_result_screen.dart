library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/trip_provider.dart';
import '../../../presentation/widgets/trip_card.dart';

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({super.key});
  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  _SortMode _sortMode = _SortMode.departureTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<TripProvider>(
        builder: (ctx, tp, _) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(tp),

              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  sortMode: _sortMode,
                  onSortChanged: (m) => setState(() => _sortMode = m),
                  resultCount: tp.searchResults.length,
                ),
              ),

              if (tp.isSearchLoading)
                _buildShimmerSliver()
              else if (tp.searchState == TripLoadState.error)
                _buildErrorSliver(tp.searchError ?? 'Đã xảy ra lỗi', () {
                  if (tp.lastFromCode != null && tp.lastToCode != null && tp.lastDate != null) {
                    tp.searchTrips(
                      fromStationCode: tp.lastFromCode!,
                      toStationCode: tp.lastToCode!,
                      date: tp.lastDate!,
                    );
                  }
                })
              else if (tp.searchResults.isEmpty)
                _buildEmptySliver()
              else
                _buildResultsSliver(tp),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(TripProvider tp) {
    final from = tp.lastFromCode ?? '---';
    final to = tp.lastToCode ?? '---';
    final date = tp.lastDate != null
        ? DateFormat('dd/MM/yyyy').format(tp.lastDate!)
        : '';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppTheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Text(from, style: const TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, color: AppTheme.primary, size: 18),
                    ),
                    Text(to, style: const TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today, color: AppTheme.textHint, size: 12),
                    const SizedBox(width: 4),
                    Text(date, style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    const Icon(Icons.people, color: AppTheme.textHint, size: 12),
                    const SizedBox(width: 4),
                    const Text('1 người lớn', style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerSliver() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _ShimmerCard(),
        childCount: 4,
      ),
    );
  }

  Widget _buildErrorSliver(String msg, VoidCallback onRetry) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off, color: AppTheme.error, size: 32)),
            const SizedBox(height: 16),
            const Text('Không thể kết nối', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptySliver() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.cardColor, shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder)),
              child: const Icon(Icons.train_outlined, color: AppTheme.textHint, size: 36)),
            const SizedBox(height: 20),
            const Text('Không có chuyến tàu', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Không tìm thấy chuyến nào phù hợp.\nVui lòng thử ngày khác.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Tìm kiếm lại'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultsSliver(TripProvider tp) {
    final sorted = [...tp.searchResults];
    if (_sortMode == _SortMode.price) {
      sorted.sort((a, b) => a.basePrice.compareTo(b.basePrice));
    } else {
      sorted.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => TripCard(
          trip: sorted[i],
          onSelect: () {
            tp.selectTrip(sorted[i]);
            context.push('/seat-selection');
          },
        ),
        childCount: sorted.length,
      ),
    );
  }
}


enum _SortMode { departureTime, price }

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final _SortMode sortMode;
  final void Function(_SortMode) onSortChanged;
  final int resultCount;

  const _FilterBarDelegate({
    required this.sortMode,
    required this.onSortChanged,
    required this.resultCount,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  bool shouldRebuild(_FilterBarDelegate old) =>
      old.sortMode != sortMode || old.resultCount != resultCount;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.background,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
        child: Row(children: [
          Text('$resultCount chuyến',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          const Text('Sắp xếp:',
              style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          const SizedBox(width: 8),
          _SortChip(
            label: 'Giờ đi',
            selected: sortMode == _SortMode.departureTime,
            onTap: () => onSortChanged(_SortMode.departureTime),
          ),
          const SizedBox(width: 6),
          _SortChip(
            label: 'Giá thấp',
            selected: sortMode == _SortMode.price,
            onTap: () => onSortChanged(_SortMode.price),
          ),
        ]),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.cardBorder)),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}


class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          ),
        ),
      ),
    );
  }
}
