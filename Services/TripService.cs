using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using VetauBackend.Data;
using VetauBackend.DTOs;
using VetauBackend.Models;

namespace VetauBackend.Services
{
    public interface ITripService
    {
        Task<object> SearchTripsAsync(SearchTripRequest req);
        Task<object> GetAvailableSeatsAsync(int tripId);
        Task<bool> LockSeatAsync(LockSeatRequest req, string sessionId, int? userId);
    }

    public class TripService : ITripService
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public TripService(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        public async Task<object> SearchTripsAsync(SearchTripRequest req)
        {
            if (!DateTime.TryParse(req.Date, out var date))
                return null;

            // Truy vấn các chuyến trong ngày có ga đi, ga đến
            var trips = await _context.Trips
                .Include(t => t.Train)
                .Include(t => t.Route)
                .Where(t => t.DepartureDate.Date == date.Date && t.Status == "scheduled")
                .ToListAsync();

            // Lọc ra các chuyến mà ga đi có stop_order < ga đến
            var result = new List<object>();
            foreach (var t in trips)
            {
                var routeStations = await _context.RouteStations
                    .Include(rs => rs.Station)
                    .Where(rs => rs.RouteId == t.RouteId)
                    .ToListAsync();

                var fromRs = routeStations.FirstOrDefault(rs => rs.Station.Code == req.FromStation);
                var toRs = routeStations.FirstOrDefault(rs => rs.Station.Code == req.ToStation);

                if (fromRs != null && toRs != null && fromRs.StopOrder < toRs.StopOrder)
                {
                    result.Add(new
                    {
                        t.Id,
                        t.DepartureDate,
                        t.DepartureTime,
                        t.ArrivalTime,
                        TrainName = t.Train.Name,
                        RouteName = t.Route.Name,
                        BasePrice = t.BasePrice,
                        FromStation = fromRs.Station.Name,
                        ToStation = toRs.Station.Name,
                        Distance = toRs.DistanceKm - fromRs.DistanceKm
                    });
                }
            }

            return result;
        }

        public async Task<object> GetAvailableSeatsAsync(int tripId)
        {
            var trip = await _context.Trips.Include(t => t.Train).FirstOrDefaultAsync(t => t.Id == tripId);
            if (trip == null) return null;

            var carriages = await _context.Carriages
                .Include(c => c.Seats)
                .Where(c => c.TrainId == trip.TrainId)
                .ToListAsync();

            // Seats đã đặt (confirmed/pending)
            var bookedSeats = await _context.Bookings
                .Where(b => b.TripId == tripId && (b.Status == "pending" || b.Status == "confirmed"))
                .Select(b => b.SeatId)
                .ToListAsync();

            // Seats đang lock
            var lockedSeats = await _context.SeatLocks
                .Where(sl => sl.TripId == tripId && !sl.IsReleased && sl.LockedUntil > DateTime.UtcNow)
                .Select(sl => sl.SeatId)
                .ToListAsync();

            var unavailableSeats = bookedSeats.Concat(lockedSeats).Distinct().ToList();

            var multipliers = await _context.PriceMultipliers.ToDictionaryAsync(m => m.CarriageType, m => m.Multiplier);

            var result = new List<object>();
            foreach (var c in carriages)
            {
                var mult = multipliers.ContainsKey(c.CarriageType) ? multipliers[c.CarriageType] : 1.0;
                var seats = c.Seats.Select(s => new
                {
                    s.Id,
                    s.SeatNumber,
                    s.Floor,
                    IsAvailable = !unavailableSeats.Contains(s.Id),
                    Price = trip.BasePrice * mult
                }).ToList();

                result.Add(new
                {
                    c.Id,
                    c.CarriageNumber,
                    c.CarriageType,
                    Seats = seats
                });
            }

            return result;
        }

        public async Task<bool> LockSeatAsync(LockSeatRequest req, string sessionId, int? userId)
        {
            // Kiểm tra ghế đã lock hoặc đã book chưa
            var isBooked = await _context.Bookings.AnyAsync(b => b.TripId == req.TripId && b.SeatId == req.SeatId && (b.Status == "pending" || b.Status == "confirmed"));
            var isLocked = await _context.SeatLocks.AnyAsync(sl => sl.TripId == req.TripId && sl.SeatId == req.SeatId && !sl.IsReleased && sl.LockedUntil > DateTime.UtcNow);

            if (isBooked || isLocked) return false;

            var lockMinutes = _config.GetValue<int>("AppConfig:SeatLockMinutes", 15);
            var seatLock = new SeatLock
            {
                SeatId = req.SeatId,
                TripId = req.TripId,
                UserId = userId,
                SessionId = sessionId,
                LockedAt = DateTime.UtcNow,
                LockedUntil = DateTime.UtcNow.AddMinutes(lockMinutes),
                IsReleased = false
            };

            _context.SeatLocks.Add(seatLock);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
