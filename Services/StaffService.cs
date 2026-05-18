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

        public async Task<bool> RejectBookingAsync(int id, string? reason)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null || booking.Status != "pending") return false;

            booking.Status = "rejected";
            booking.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<object> GetPassengerStatsAsync()
        {
            var today = DateTime.UtcNow.Date;
            var currentTime = DateTime.UtcNow.ToString("HH:mm");

            var totalPassengers = await _context.Bookings
                .CountAsync(b => b.CreatedAt.Date == today);

            var tripsToday = await _context.Trips
                .Where(t => t.Status == "scheduled" && t.DepartureDate.Date == today)
                .ToListAsync();

            var tripIds = tripsToday.Select(t => t.Id).ToList();

            var passengerCounts = await _context.Bookings
                .Where(b => tripIds.Contains(b.TripId) && (b.Status == "confirmed" || b.Status == "pending"))
                .GroupBy(b => b.TripId)
                .Select(g => new { TripId = g.Key, Count = g.Count() })
                .ToListAsync();
            
            var countDict = passengerCounts.ToDictionary(x => x.TripId, x => x.Count);

            int onBoardCount = 0;
            int waitingCount = 0;

            foreach (var t in tripsToday)
            {
                var count = countDict.ContainsKey(t.Id) ? countDict[t.Id] : 0;
                var isDeparted = string.Compare(currentTime, t.DepartureTime, StringComparison.Ordinal) >= 0;
                if (isDeparted) {
                    onBoardCount += count;
                } else {
                    waitingCount += count;
                }
            }

            return new
            {
                TotalPassengers = totalPassengers,
                OnBoardCount = onBoardCount,
                WaitingCount = waitingCount
            };
        }

        public async Task<object> GetActiveTripsAsync()
        {
            var now = DateTime.UtcNow;
            var today = now.Date;
            var currentTime = now.ToString("HH:mm");

            var trips = await _context.Trips
                .Include(t => t.Train)
                .Include(t => t.Route).ThenInclude(r => r.RouteStations).ThenInclude(rs => rs.Station)
                .Where(t => t.Status == "scheduled" && t.DepartureDate.Date == today)
                .ToListAsync();

            var tripIds = trips.Select(t => t.Id).ToList();
            var passengerCounts = await _context.Bookings
                .Where(b => tripIds.Contains(b.TripId) && (b.Status == "confirmed" || b.Status == "pending"))
                .GroupBy(b => b.TripId)
                .Select(g => new { TripId = g.Key, Count = g.Count() })
                .ToListAsync();
            var countDict = passengerCounts.ToDictionary(x => x.TripId, x => x.Count);

            var result = trips.Select(t =>
            {
                var isDeparted = string.Compare(currentTime, t.DepartureTime, StringComparison.Ordinal) >= 0;
                
                var firstStation = t.Route?.RouteStations.OrderBy(rs => rs.StopOrder).FirstOrDefault()?.Station?.Name ?? t.Route?.Name ?? "";
                var lastStation = t.Route?.RouteStations.OrderByDescending(rs => rs.StopOrder).FirstOrDefault()?.Station?.Name ?? "";

                return new
                {
                    t.Id,
                    TrainName = t.Train?.Name ?? "",
                    TrainCode = t.Train?.Code ?? "",
                    RouteName = t.Route?.Name ?? "",
                    FromStation = firstStation,
                    ToStation = lastStation,
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

            return result;
        }

        public async Task<object> GetStaffDashboardAsync()
        {
            var today = DateTime.UtcNow.Date;

            var pendingBookings = await _context.Bookings.CountAsync(b => b.Status == "pending");
            var confirmedToday = await _context.Bookings
                .CountAsync(b => b.Status == "confirmed" && b.PaidAt != null && b.PaidAt.Value.Date == today);
            var cancelledToday = await _context.Bookings
                .CountAsync(b => (b.Status == "cancelled" || b.Status == "rejected") && b.CreatedAt.Date == today);
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
                CancelledToday = cancelledToday,
                TotalPassengersToday = totalPassengersToday,
                ActiveTrips = activeTrips,
                RevenueToday = todayRevenue
            };
        }
    }
}
