using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using VetauBackend.Data;
using VetauBackend.Models;

namespace VetauBackend.Services
{
    public interface IStaffService
    {
        Task<object> GetPendingBookingsAsync();
        Task<bool> ApproveBookingAsync(int id);
        Task<bool> RejectBookingAsync(int id, string? reason);
        Task<object> GetPassengerStatsAsync();
        Task<object> GetActiveTripsAsync();
        Task<object> GetStaffDashboardAsync();
    }

    public class StaffService : IStaffService
    {
        private readonly AppDbContext _context;

        public StaffService(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Lấy danh sách đơn vé chờ duyệt (status = "pending") — flat DTO
        /// </summary>
        public async Task<object> GetPendingBookingsAsync()
        {
            var bookings = await _context.Bookings
                .Include(b => b.Trip).ThenInclude(t => t.Train)
                .Include(b => b.FromStation)
                .Include(b => b.ToStation)
                .Include(b => b.Seat)
                .Include(b => b.Carriage)
                .Where(b => b.Status == "pending")
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();

            return bookings.Select(b => new
            {
                b.Id,
                b.BookingCode,
                b.PassengerName,
                b.PassengerIdCard,
                b.PassengerPhone,
                b.PassengerEmail,
                b.PassengerType,
                b.PaymentMethod,
                b.Status,
                TotalPrice = b.FinalPrice,
                b.FinalPrice,
                b.CreatedAt,
                b.PaymentDeadline,
                b.QrCodeData,
                b.TripId,
                TrainName = b.Trip?.Train?.Name ?? "",
                FromStation = b.FromStation?.Name ?? "",
                ToStation = b.ToStation?.Name ?? "",
                DepartureTime = b.Trip?.DepartureTime ?? "",
                ArrivalTime = b.Trip?.ArrivalTime ?? "",
                DepartureDate = b.Trip?.DepartureDate.ToString("yyyy-MM-dd") ?? "",
                SeatNumber = b.Seat?.SeatNumber ?? "",
                CarriageType = b.Carriage?.CarriageType ?? ""
            }).ToList();
        }

        /// <summary>
        /// Duyệt đơn vé → chuyển status "pending" → "confirmed"
        /// </summary>
        public async Task<bool> ApproveBookingAsync(int id)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null || booking.Status != "pending") return false;

            booking.Status = "confirmed";
            booking.PaidAt = DateTime.UtcNow;
            booking.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        /// <summary>
        /// Từ chối đơn vé → chuyển status sang "rejected"
        /// </summary>
        public async Task<bool> RejectBookingAsync(int id, string? reason)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null || booking.Status != "pending") return false;

            booking.Status = "rejected";
            booking.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        /// <summary>
        /// Thống kê số khách hiện tại:
        /// - Tổng khách có booking hôm nay
        /// - Pending / Confirmed / Cancelled
        /// - Tổng khách tất cả
        /// </summary>
        public async Task<object> GetPassengerStatsAsync()
        {
            var today = DateTime.UtcNow.Date;

            var totalPassengersToday = await _context.Bookings
                .CountAsync(b => b.CreatedAt.Date == today);

            var pendingToday = await _context.Bookings
                .CountAsync(b => b.Status == "pending" && b.CreatedAt.Date == today);

            var confirmedToday = await _context.Bookings
                .CountAsync(b => b.Status == "confirmed" && b.CreatedAt.Date == today);

            var cancelledToday = await _context.Bookings
                .CountAsync(b => (b.Status == "cancelled" || b.Status == "rejected") && b.CreatedAt.Date == today);

            var totalConfirmedAllTime = await _context.Bookings
                .CountAsync(b => b.Status == "confirmed");

            var totalPendingAllTime = await _context.Bookings
                .CountAsync(b => b.Status == "pending");

            return new
            {
                Today = new
                {
                    Total = totalPassengersToday,
                    Pending = pendingToday,
                    Confirmed = confirmedToday,
                    Cancelled = cancelledToday
                },
                AllTime = new
                {
                    TotalConfirmed = totalConfirmedAllTime,
                    TotalPending = totalPendingAllTime
                }
            };
        }

        /// <summary>
        /// Danh sách chuyến tàu đang di chuyển theo giờ hiện tại.
        /// Chuyến "đang chạy" = DepartureDate là hôm nay + Status = "scheduled"
        /// + giờ hiện tại >= DepartureTime
        /// </summary>
        public async Task<object> GetActiveTripsAsync()
        {
            var now = DateTime.UtcNow;
            var today = now.Date;
            var currentTime = now.ToString("HH:mm");

            var trips = await _context.Trips
                .Include(t => t.Train)
                .Include(t => t.Route)
                .Where(t => t.Status == "scheduled" && t.DepartureDate.Date == today)
                .ToListAsync();

            // Tính số khách đã confirmed cho mỗi chuyến
            var tripIds = trips.Select(t => t.Id).ToList();
            var passengerCounts = await _context.Bookings
                .Where(b => tripIds.Contains(b.TripId) && (b.Status == "confirmed" || b.Status == "pending"))
                .GroupBy(b => b.TripId)
                .Select(g => new { TripId = g.Key, Count = g.Count() })
                .ToListAsync();
            var countDict = passengerCounts.ToDictionary(x => x.TripId, x => x.Count);

            // Phân loại: đã khởi hành (giờ hiện tại >= departure) vs chưa khởi hành
            var result = trips.Select(t =>
            {
                var isDeparted = string.Compare(currentTime, t.DepartureTime, StringComparison.Ordinal) >= 0;
                return new
                {
                    t.Id,
                    TrainName = t.Train?.Name ?? "",
                    TrainCode = t.Train?.Code ?? "",
                    RouteName = t.Route?.Name ?? "",
                    t.DepartureTime,
                    t.ArrivalTime,
                    t.DurationMinutes,
                    DepartureDate = t.DepartureDate.ToString("yyyy-MM-dd"),
                    PassengerCount = countDict.ContainsKey(t.Id) ? countDict[t.Id] : 0,
                    Status = isDeparted ? "in_transit" : "waiting",
                    StatusLabel = isDeparted ? "Đang di chuyển" : "Chưa khởi hành"
                };
            })
            .OrderBy(t => t.DepartureTime)
            .ToList();

            return new
            {
                CurrentTime = currentTime,
                TotalTripsToday = trips.Count,
                InTransit = result.Count(t => t.Status == "in_transit"),
                Waiting = result.Count(t => t.Status == "waiting"),
                TotalPassengers = result.Sum(t => t.PassengerCount),
                Trips = result
            };
        }

        /// <summary>
        /// Dashboard tổng hợp nhanh cho Staff
        /// </summary>
        public async Task<object> GetStaffDashboardAsync()
        {
            var today = DateTime.UtcNow.Date;

            var pendingBookings = await _context.Bookings.CountAsync(b => b.Status == "pending");
            var confirmedToday = await _context.Bookings
                .CountAsync(b => b.Status == "confirmed" && b.PaidAt != null && b.PaidAt.Value.Date == today);
            var totalPassengersToday = await _context.Bookings
                .CountAsync(b => b.CreatedAt.Date == today);
            var activeTrips = await _context.Trips
                .CountAsync(t => t.Status == "scheduled" && t.DepartureDate.Date == today);
            var todayRevenue = await _context.Bookings
                .Where(b => b.Status == "confirmed" && b.PaidAt != null && b.PaidAt.Value.Date == today)
                .SumAsync(b => b.FinalPrice);

            return new
            {
                PendingBookings = pendingBookings,
                ConfirmedToday = confirmedToday,
                TotalPassengersToday = totalPassengersToday,
                ActiveTrips = activeTrips,
                TodayRevenue = todayRevenue
            };
        }
    }
}
