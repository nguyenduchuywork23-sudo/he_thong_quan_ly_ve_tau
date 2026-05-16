/// SeatSelectionScreen – Sơ đồ ghế tàu
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/train_model.dart';
import '../../../presentation/providers/trip_provider.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../data/models/trip_model.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});
  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _tabCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tp = context.read<TripProvider>();
    if (tp.selectedTrip == null) return;
    await tp.loadSeats(tp.selectedTrip!.id);
    if (!mounted) return;
    _initTabs(context.read<TripProvider>().carriages.length);
  }

  void _initTabs(int count) {
    if (count == _tabCount || count == 0) return;
    _tabController?.dispose();
    _tabController = TabController(length: count, vsync: this)
      ..addListener(() {
        if (!_tabController!.indexIsChanging) {
          context.read<TripProvider>().selectCarriageTab(_tabController!.index);
        }
      });
    setState(() => _tabCount = count);
  }

  Future<void> _onContinue() async {
    final tp = context.read<TripProvider>();
    if (tp.selectedSeat == null) return;

    final success = await tp.lockSelectedSeat();
    if (!mounted) return;

    if (success) {
      // Tìm station IDs từ danh sách đã load
      final stations = tp.stations;
      int fromId = 0, toId = 0;
      for (final s in stations) {
        if (s.code == tp.lastFromCode) fromId = s.id;
        if (s.code == tp.lastToCode) toId = s.id;
      }
      context.read<BookingProvider>().setBookingContext(
        trip: tp.selectedTrip!,
        seat: tp.selectedSeat!,
        carriage: tp.selectedCarriage!,
        fromStationId: fromId,
        toStationId: toId,
      );
      context.push('/passenger-form');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tp.lockError ?? 'Không thể giữ chỗ. Vui lòng chọn ghế khác.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(builder: (ctx, tp, _) {
      // Sync tabs khi carriages load xong
      if (tp.seatsState == TripLoadState.loaded && tp.carriages.length != _tabCount) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _initTabs(tp.carriages.length));
      }

      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(tp),
        body: Column(children: [
          // Tab bar
          if (tp.seatsState == TripLoadState.loaded &&
              _tabController != null &&
              tp.carriages.isNotEmpty)
            _buildTabBar(tp),

          // Content
          Expanded(child: _buildBody(tp)),

          // Bottom panel
          _BottomPanel(tp: tp, onContinue: _onContinue),
        ]),
      );
    });
  }

  AppBar _buildAppBar(TripProvider tp) {
    final trip = tp.selectedTrip;
    return AppBar(
      backgroundColor: AppTheme.surface,
      title: Column(children: [
        Text(trip?.trainName ?? 'Chọn ghế',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        if (trip != null)
          Text('${trip.departureTime} → ${trip.arrivalTime}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildTabBar(TripProvider tp) {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primary,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        tabs: tp.carriages.map((c) => Tab(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Toa ${c.carriageNumber}'),
            Text(c.displayName.split('\n').last,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400)),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildBody(TripProvider tp) {
    if (tp.isSeatsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (tp.seatsState == TripLoadState.error) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 12),
          Text(tp.seatsError ?? 'Lỗi tải sơ đồ ghế',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
        ]),
      );
    }
    if (tp.carriages.isEmpty || _tabController == null) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      controller: _tabController,
      children: tp.carriages.map((carriage) {
        return _CarriageView(carriage: carriage, tp: tp);
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════
// CARRIAGE VIEW – router tới layout phù hợp
// ══════════════════════════════════════════════
class _CarriageView extends StatelessWidget {
  final CarriageWithSeats carriage;
  final TripProvider tp;
  const _CarriageView({required this.carriage, required this.tp});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Legend
        _Legend(),
        const SizedBox(height: 16),
        // Carriage info
        Row(children: [
          const Icon(Icons.train, color: AppTheme.textHint, size: 14),
          const SizedBox(width: 6),
          Text('Toa ${carriage.carriageNumber} – ${carriage.displayName.replaceAll('\n', ' ')}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text('${carriage.availableCount} ghế trống',
              style: const TextStyle(color: AppTheme.success, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),

        // Layout theo loại toa
        if (carriage.carriageType == 'soft_seat' ||
            carriage.carriageType == 'hard_seat')
          _ChairLayout(carriage: carriage, tp: tp)
        else
          _BerthLayout(carriage: carriage, tp: tp),
      ]),
    );
  }
}

// ══════════════════════════════════════════════
// CHAIR LAYOUT: Toa Ghế ngồi (Bắt buộc dùng GridView.builder)
// ══════════════════════════════════════════════
class _ChairLayout extends StatelessWidget {
  final CarriageWithSeats carriage;
  final TripProvider tp;
  const _ChairLayout({required this.carriage, required this.tp});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: carriage.seats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,      // Chia làm 4 cột ghế rõ ràng
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return _SeatWidget(
          seat: carriage.seats[index],
          tp: tp,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// BERTH LAYOUT: Toa Giường nằm 
// (Sử dụng chung cấu trúc GridView nhưng chia 2 cột cho giường nằm)
// ══════════════════════════════════════════════
class _BerthLayout extends StatelessWidget {
  final CarriageWithSeats carriage;
  final TripProvider tp;
  const _BerthLayout({required this.carriage, required this.tp});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: carriage.seats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,      // Giường nằm chia 2 cột cho phù hợp kích thước
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0,  // Kéo dài hiển thị giường nằm
      ),
      itemBuilder: (context, index) {
        return _SeatWidget(
          seat: carriage.seats[index],
          tp: tp,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════
// SEAT WIDGET: Định nghĩa Widget ghế độc lập
// ══════════════════════════════════════════════
class _SeatWidget extends StatelessWidget {
  final SeatAvailability seat;
  final TripProvider tp;
  
  const _SeatWidget({required this.seat, required this.tp});

  @override
  Widget build(BuildContext context) {
    final isSelected = tp.selectedSeat?.id == seat.id;
    final isAvailable = seat.isAvailable;

    Color bgColor;
    Color borderColor;

    // Phân nhánh màu sắc theo trạng thái thực tế
    if (!isAvailable) {
      bgColor = AppTheme.seatBooked; // Đã đặt: Màu xám
      borderColor = AppTheme.seatBooked;
    } else if (isSelected) {
      bgColor = AppTheme.seatSelected; // Đang chọn: Màu cam đỏ
      borderColor = AppTheme.seatSelected;
    } else {
      bgColor = Colors.transparent; 
      borderColor = AppTheme.seatAvailable; // Trống: Xanh lá viền mỏng
    }

    // Bọc trong Center để Container bên trong giữ được cứng width: 45, height: 45
    // thay vì bị GridView ép stretch lấp đầy ô.
    return Center(
      child: GestureDetector(
        onTap: () {
          if (!isAvailable) return; // Không cho click nếu đã đặt
          
          // Lấy carriage hiện tại chứa ghế này để truyền vào tapSeat
          final carriage = tp.carriages.firstWhere(
            (c) => c.seats.any((s) => s.id == seat.id),
            orElse: () => tp.carriages.first,
          );
          
          // Gọi hàm tapSeat đã định nghĩa sẵn trong TripProvider
          tp.tapSeat(seat, carriage);
        },
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Center(
            child: Text(
              seat.seatNumber,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: !isAvailable 
                    ? Colors.white // Đã đặt -> text trắng
                    : (isSelected ? Colors.white : AppTheme.seatAvailable), // Trống -> text xanh
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// LEGEND
// ══════════════════════════════════════════════
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _LegendItem(color: AppTheme.seatAvailable.withOpacity(0.15),
          border: AppTheme.seatAvailable, label: 'Trống'),
      const SizedBox(width: 12),
      _LegendItem(color: AppTheme.seatSelected, border: AppTheme.seatSelected,
          label: 'Đang chọn'),
      const SizedBox(width: 12),
      _LegendItem(color: AppTheme.seatBooked, border: AppTheme.seatBooked,
          label: 'Đã đặt'),
    ]);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color, border;
  final String label;
  const _LegendItem({required this.color, required this.border, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 18, height: 18,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
    ]);
  }
}

// ══════════════════════════════════════════════
// BOTTOM PANEL
// ══════════════════════════════════════════════
class _BottomPanel extends StatelessWidget {
  final TripProvider tp;
  final Future<void> Function() onContinue;
  const _BottomPanel({required this.tp, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16,
          12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (tp.selectedSeat == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Hãy chọn ghế bạn muốn',
                style: TextStyle(color: AppTheme.textHint)),
          )
        else ...[
          Row(children: [
            // Seat info
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ghế ${tp.selectedSeat!.seatNumber}',
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(tp.selectedCarriage?.displayName.replaceAll('\n', ' ') ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const Spacer(),
            // Price
            Text(price.format(tp.selectedSeat!.price),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppTheme.primary)),
          ]),
          // Countdown nếu đang lock
          if (tp.isSeatLocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.timer, color: AppTheme.warning, size: 16),
                const SizedBox(width: 6),
                Text('Thời gian giữ chỗ: ${tp.lockCountdownFormatted}',
                    style: const TextStyle(color: AppTheme.warning,
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          // Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: tp.isSeatLocking ? null : onContinue,
              child: tp.isSeatLocking
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(tp.isSeatLocked ? 'Tiếp tục đặt vé →' : 'Giữ chỗ & Tiếp tục',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ]),
    );
  }
}
