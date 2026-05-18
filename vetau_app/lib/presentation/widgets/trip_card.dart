library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/trip_model.dart';
import '../../core/theme/app_theme.dart';

class TripCard extends StatefulWidget {
  final TripSearchResult trip;
  final VoidCallback onSelect;

  const TripCard({
    super.key,
    required this.trip,
    required this.onSelect,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN', symbol: '₫', decimalDigits: 0,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      opacity: _opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM, vertical: AppTheme.spacingS),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.cardBorder, width: 0.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSelect,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            splashColor: AppTheme.primaryLight.withOpacity(0.2),
            highlightColor: AppTheme.primaryLight.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.train, color: AppTheme.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.trip.trainName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _TrainTypeBadge(trainName: widget.trip.trainName),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trip.departureTime,
                              style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              widget.trip.fromStation,
                              style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text(
                                widget.trip.durationFormatted,
                                style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textHint,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(width: 6, height: 6,
                                      decoration: BoxDecoration(
                                          border: Border.all(color: AppTheme.primary, width: 2),
                                          shape: BoxShape.circle)),
                                  Expanded(
                                    child: Container(height: 1,
                                        color: AppTheme.primaryLight.withOpacity(0.5)),
                                  ),
                                  const Icon(Icons.arrow_forward_ios,
                                      color: AppTheme.primary, size: 10),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.trip.arrivalTime,
                              style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              widget.trip.toStation,
                              style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    height: 1,
                    color: AppTheme.cardBorder,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _InfoChip(
                              icon: Icons.straighten,
                              label: '${widget.trip.distance.toStringAsFixed(0)} km',
                            ),
                            _InfoChip(
                              icon: Icons.route,
                              label: widget.trip.routeName,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Giá chỉ từ',
                                style: TextStyle(
                                    fontSize: 10, color: AppTheme.textHint,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              priceFormat.format(widget.trip.basePrice),
                              style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900,
                                color: AppTheme.error, // Dùng màu nhấn đỏ/cam cho giá tiền
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: widget.onSelect,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0, // Đã có bóng ở container
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Chọn', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _TrainTypeBadge extends StatelessWidget {
  final String trainName;
  const _TrainTypeBadge({required this.trainName});

  @override
  Widget build(BuildContext context) {
    final isExpress = trainName.toUpperCase().startsWith('SE');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpress
            ? AppTheme.info.withOpacity(0.1)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpress ? AppTheme.info.withOpacity(0.3) : AppTheme.cardBorder,
        ),
      ),
      child: Text(
        isExpress ? '⚡ Tốc hành' : 'Thường',
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: isExpress ? AppTheme.info : AppTheme.textSecondary,
        ),
      ),
    );
  }
}


class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textHint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
