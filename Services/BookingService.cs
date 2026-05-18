using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using VetauBackend.Data;
using VetauBackend.DTOs;
using VetauBackend.Models;

namespace VetauBackend.Services
{
    public interface IBookingService
    {
        Task<Booking?> CreateBookingAsync(CreateBookingRequest req, string sessionId, int? userId);
        Task<object> GetMyBookingsAsync(int userId);
    }

    public class BookingService : IBookingService
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;
        private readonly IPaymentService _paymentService;

        public BookingService(AppDbContext context, IConfiguration config, IPaymentService paymentService)
        {
            _context = context;
            _config = config;
            _paymentService = paymentService;
        }

        public async Task<Booking?> CreateBookingAsync(CreateBookingRequest req, string sessionId, int? userId)
        {
            var slock = await _context.SeatLocks
                .FirstOrDefaultAsync(sl => sl.TripId == req.TripId && sl.SeatId == req.SeatId && sl.SessionId == sessionId && !sl.IsReleased && sl.LockedUntil > DateTime.UtcNow);
            
            if (slock == null) throw new Exception("Ghế chưa được giữ hoặc thời gian giữ chỗ đã hết hạn.");

            var trip = await _context.Trips.FindAsync(req.TripId);
            var carriage = await _context.Carriages.FindAsync(req.CarriageId);
            var multiplier = await _context.PriceMultipliers.FirstOrDefaultAsync(m => m.CarriageType == carriage.CarriageType);
            
            double basePrice = trip.BasePrice * (multiplier?.Multiplier ?? 1.0);
            double discountPercent = 0;
            switch(req.PassengerType)
            {
                case "child": discountPercent = 25; break;
                case "student": discountPercent = 15; break;
                case "elderly": discountPercent = 20; break;
            }
            double finalPrice = basePrice * (100 - discountPercent) / 100;

            var deadlineMinutes = _config.GetValue<int>("AppConfig:PaymentDeadlineMinutes", 30);
            string bookingCode = "VT" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(100, 999).ToString();

            var booking = new Booking
            {
                BookingCode = bookingCode,
                UserId = userId,
                TripId = req.TripId,
                FromStationId = req.FromStationId,
                ToStationId = req.ToStationId,
                SeatId = req.SeatId,
                CarriageId = req.CarriageId,
                PassengerName = req.PassengerName,
                PassengerIdCard = req.PassengerIdCard,
                PassengerPhone = req.PassengerPhone,
                PassengerEmail = req.PassengerEmail,
                PassengerType = req.PassengerType,
                BasePrice = basePrice,
                DiscountPercent = discountPercent,
                DiscountAmount = basePrice * discountPercent / 100,
                FinalPrice = finalPrice,
                Status = "pending",
                PaymentMethod = req.PaymentMethod,
                PaymentDeadline = DateTime.UtcNow.AddMinutes(deadlineMinutes),
            };

            string svgQr = _paymentService.GenerateVietQr("970422", "0123456789", finalPrice, bookingCode);
            booking.QrCodeData = "data:image/svg+xml;utf8," + Uri.EscapeDataString(svgQr);

            _context.Bookings.Add(booking);
            
            slock.IsReleased = true;

            await _context.SaveChangesAsync();
            return booking;
        }

        public async Task<object> GetMyBookingsAsync(int userId)
        {
            var bookings = await _context.Bookings
                .Include(b => b.Trip).ThenInclude(t => t.Train)
                .Include(b => b.FromStation)
                .Include(b => b.ToStation)
                .Include(b => b.Seat)
                .Include(b => b.Carriage)
                .Where(b => b.UserId == userId)
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
        }
    }
}
