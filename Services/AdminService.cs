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
        // Quản lý Ga tàu (Stations)
        Task<List<Station>> GetStationsAsync();
        Task<Station?> CreateStationAsync(Station station);
        Task<Station?> UpdateStationAsync(int id, Station stationIn);
        Task<bool> DeleteStationAsync(int id);

        // Quản lý Tàu (Trains)
        Task<List<Train>> GetTrainsAsync();

        // Quản lý Đơn vé (Bookings)
        Task<List<Booking>> GetBookingsAsync();
        Task<bool> UpdateBookingStatusAsync(int id, string status);
        
        // Thống kê Dashboard
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

            // Đơn giản là đánh dấu InActive thay vì xóa thật nếu có liên kết
            station.IsActive = false;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<List<Train>> GetTrainsAsync()
        {
            return await _context.Trains.Include(t => t.Carriages).ToListAsync();
        }

        public async Task<List<Booking>> GetBookingsAsync()
        {
            return await _context.Bookings
                .Include(b => b.Trip)
                .ThenInclude(t => t.Train)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();
        }

        public async Task<bool> UpdateBookingStatusAsync(int id, string status)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return false;

            booking.Status = status; // e.g., "confirmed", "cancelled"
            if (status == "confirmed")
            {
                booking.PaidAt = System.DateTime.UtcNow;
            }
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<object> GetDashboardStatsAsync()
        {
            var totalBookings = await _context.Bookings.CountAsync();
            var totalRevenue = await _context.Bookings.Where(b => b.Status == "confirmed").SumAsync(b => b.FinalPrice);
            var pendingBookings = await _context.Bookings.CountAsync(b => b.Status == "pending");
            var totalUsers = await _context.Users.CountAsync(u => u.Role == "customer");

            return new
            {
                TotalBookings = totalBookings,
                TotalRevenue = totalRevenue,
                PendingBookings = pendingBookings,
                TotalCustomers = totalUsers
            };
        }
    }
}
