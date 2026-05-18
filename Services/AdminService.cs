using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using VetauBackend.Data;
using VetauBackend.Models;

namespace VetauBackend.Services
{
    public interface IAdminService
    {
        Task<List<Station>> GetStationsAsync();
        Task<Station?> CreateStationAsync(Station station);
        Task<Station?> UpdateStationAsync(int id, Station stationIn);
        Task<bool> DeleteStationAsync(int id);

        Task<List<Train>> GetTrainsAsync();

        Task<object> GetBookingsAsync(int page = 1, int pageSize = 50, string? status = null, string? search = null);
        Task<bool> UpdateBookingStatusAsync(int id, string status);
        
        Task<object> GetDashboardStatsAsync();
    }

    public class AdminService : IAdminService
    {
        private readonly AppDbContext _context;

        public AdminService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<Station>> GetStationsAsync()
        {
            return await _context.Stations.OrderBy(s => s.SortOrder).ToListAsync();
        }

        public async Task<Station?> CreateStationAsync(Station station)
        {
            var exists = await _context.Stations.AnyAsync(s => s.Code == station.Code);
            if (exists) return null; // Mã ga đã tồn tại

            _context.Stations.Add(station);
            await _context.SaveChangesAsync();
            return station;
        }

        public async Task<Station?> UpdateStationAsync(int id, Station stationIn)
        {
            var station = await _context.Stations.FindAsync(id);
            if (station == null) return null;

            station.Name = stationIn.Name;
            station.Code = stationIn.Code;
            station.City = stationIn.City;
            station.Province = stationIn.Province;
            station.SortOrder = stationIn.SortOrder;
            station.IsActive = stationIn.IsActive;

            await _context.SaveChangesAsync();
            return station;
        }

        public async Task<bool> DeleteStationAsync(int id)
        {
            var station = await _context.Stations.FindAsync(id);
            if (station == null) return false;

            station.IsActive = false;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<List<Train>> GetTrainsAsync()
        {
            return await _context.Trains.Include(t => t.Carriages).ToListAsync();
        }

        public async Task<object> GetBookingsAsync(int page = 1, int pageSize = 50, string? status = null, string? search = null)
        {
            var query = _context.Bookings
                .Include(b => b.Trip).ThenInclude(t => t.Train)
                .Include(b => b.FromStation)
                .Include(b => b.ToStation)
                .Include(b => b.Seat)
                .Include(b => b.Carriage)
                .AsQueryable();

            if (!string.IsNullOrEmpty(status) && status.ToLower() != "all")
            {
                query = query.Where(b => b.Status.ToLower() == status.ToLower());
            }

            if (!string.IsNullOrEmpty(search))
            {
                var s = search.ToLower();
                query = query.Where(b => b.BookingCode.ToLower().Contains(s) || 
                                         b.PassengerName.ToLower().Contains(s) || 
                                         b.PassengerPhone.Contains(s));
            }

            var totalCount = await query.CountAsync();

            var bookings = await query
                .OrderByDescending(b => b.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = bookings.Select(b => new
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
                b.BasePrice,
                b.DiscountPercent,
                b.DiscountAmount,
                b.FinalPrice,
                b.CreatedAt,
                b.UpdatedAt,
                b.PaymentDeadline,
                b.PaidAt,
                b.QrCodeData,
                b.UserId,
                b.TripId,
                b.FromStationId,
                b.ToStationId,
                b.SeatId,
                b.CarriageId,
                TrainName = b.Trip?.Train?.Name ?? "",
                FromStation = b.FromStation?.Name ?? "",
                ToStation = b.ToStation?.Name ?? "",
                DepartureTime = b.Trip?.DepartureTime ?? "",
                ArrivalTime = b.Trip?.ArrivalTime ?? "",
                DepartureDate = b.Trip?.DepartureDate.ToString("yyyy-MM-dd") ?? "",
                SeatNumber = b.Seat?.SeatNumber ?? "",
                CarriageType = b.Carriage?.CarriageType ?? ""
            }).ToList();

            return new { items, totalCount };
        }

        public async Task<bool> UpdateBookingStatusAsync(int id, string status)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return false;

            booking.Status = status; // e.g., "confirmed", "cancelled"
            booking.UpdatedAt = DateTime.UtcNow;
            if (status.Equals("confirmed", StringComparison.OrdinalIgnoreCase))
            {
                booking.PaidAt = DateTime.UtcNow;
            }
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<object> GetDashboardStatsAsync()
        {
            var today = DateTime.UtcNow.Date;

            var totalBookings = await _context.Bookings.CountAsync();
            var pendingBookings = await _context.Bookings.CountAsync(b => b.Status == "pending");
            var confirmedBookings = await _context.Bookings.CountAsync(b => b.Status == "confirmed");
            var cancelledBookings = await _context.Bookings.CountAsync(b => b.Status == "cancelled");

            var totalRevenue = await _context.Bookings
                .Where(b => b.Status == "confirmed")
                .SumAsync(b => b.FinalPrice);
            var todayRevenue = await _context.Bookings
                .Where(b => b.Status == "confirmed" && b.PaidAt != null && b.PaidAt.Value.Date == today)
                .SumAsync(b => b.FinalPrice);

            var totalCustomers = await _context.Users.CountAsync(u => u.Role == "customer");
            var totalStations = await _context.Stations.CountAsync(s => s.IsActive);
            var totalTrains = await _context.Trains.CountAsync(t => t.IsActive);
            var activeTrips = await _context.Trips.CountAsync(t => t.Status == "scheduled" && t.DepartureDate.Date == today);

            return new
            {
                TotalBookings = totalBookings,
                PendingBookings = pendingBookings,
                ConfirmedBookings = confirmedBookings,
                CancelledBookings = cancelledBookings,
                TotalRevenue = totalRevenue,
                TodayRevenue = todayRevenue,
                TotalCustomers = totalCustomers,
                TotalStations = totalStations,
                TotalTrains = totalTrains,
                ActiveTrips = activeTrips
            };
        }
    }
}
