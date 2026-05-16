/// TripCard – Card hiển thị 1 chuyến tàu trong kết quả tìm kiếm
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/trip_model.dart';
import '../../core/theme/app_theme.dart';

class TripCard extends StatelessWidget {
  final TripSearchResult trip;
  final VoidCallback onSelect;

  const TripCard({
    super.key,
    required this.trip,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN', symbol: '₫', decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Tên tàu + Loại tàu badge ──────────
                Row(
                  children: [
                    const Icon(Icons.train, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        trip.trainName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _TrainTypeBadge(trainName: trip.trainName),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingM),

                // ── Row 2: Giờ đi ─── Duration ─── Giờ đến ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Giờ đi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.departureTime,
                          style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          trip.fromStation,
                          style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Duration line
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              trip.durationFormatted,
                              style: const TextStyle(
                                fontSize: 11, color: AppTheme.textHint,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(width: 6, height: 6,
                                    decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle)),
                                Expanded(
                                  child: Container(height: 1.5,
                                      color: AppTheme.cardBorder),
                                ),
                                const Icon(Icons.arrow_forward,
                                    color: AppTheme.primary, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Giờ đến
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trip.arrivalTime,
                          style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          trip.toStation,
                          style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingM),
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingM),

                // ── Row 3: Khoảng cách + Giá + Nút Chọn ──────
                Row(
                  children: [
                    // Distance & Route
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                            icon: Icons.straighten,
                            label: '${trip.distance.toStringAsFixed(0)} km',
                          ),
                          _InfoChip(
                            icon: Icons.route,
                            label: trip.routeName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Giá từ
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Từ',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textHint)),
                          Text(
                            priceFormat.format(trip.basePrice),
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút chọn
                    ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Chọn'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Badge loại tàu ──────────────────────────

class _TrainTypeBadge extends StatelessWidget {
  final String trainName;
  const _TrainTypeBadge({required this.trainName});

  @override
  Widget build(BuildContext context) {
    // SE = express, SPT = local
    final isExpress = trainName.toUpperCase().startsWith('SE');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isExpress
            ? AppTheme.primary.withOpacity(0.15)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpress ? AppTheme.primary : AppTheme.cardBorder,
        ),
      ),
      child: Text(
        isExpress ? '⚡ Nhanh' : 'Thường',
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: isExpress ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ─── Info chip nhỏ ───────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? maxWidth;
  const _InfoChip({required this.icon, required this.label, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textHint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
