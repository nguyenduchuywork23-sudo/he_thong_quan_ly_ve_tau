using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VetauBackend.DTOs;
using VetauBackend.Services;
using System.Security.Claims;

namespace VetauBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var res = await _authService.LoginAsync(req);
            if (res == null) return Unauthorized(new { Message = "Email hoặc mật khẩu không đúng." });
            return Ok(res);
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest req)
        {
            try
            {
                var res = await _authService.RegisterAsync(req);
                return Ok(res);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }

    [ApiController]
    [Route("api/[controller]")]
    public class TripsController : ControllerBase
    {
        private readonly ITripService _tripService;

        public TripsController(ITripService tripService)
        {
            _tripService = tripService;
        }

        [HttpGet("search")]
        public async Task<IActionResult> Search([FromQuery] SearchTripRequest req)
        {
            var res = await _tripService.SearchTripsAsync(req);
            return Ok(res);
        }

        [HttpGet("{id}/seats")]
        public async Task<IActionResult> GetSeats(int id)
        {
            var res = await _tripService.GetAvailableSeatsAsync(id);
            if (res == null) return NotFound();
            return Ok(res);
        }

        [HttpPost("lock-seat")]
        public async Task<IActionResult> LockSeat([FromBody] LockSeatRequest req)
        {
            // Lấy SessionId từ header hoặc gen mới nếu khách chưa có
            if (!Request.Headers.TryGetValue("X-Session-Id", out var sessionId))
            {
                sessionId = Guid.NewGuid().ToString();
            }

            int? userId = null;
            if (User.Identity?.IsAuthenticated == true)
            {
                var idStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (int.TryParse(idStr, out int uid)) userId = uid;
            }

            var success = await _tripService.LockSeatAsync(req, sessionId, userId);
            if (!success) return BadRequest(new { Message = "Ghế đã bị đặt hoặc đang được giữ bởi người khác." });

            return Ok(new { SessionId = sessionId.ToString(), Message = "Giữ chỗ thành công. Bạn có 15 phút để thanh toán." });
        }
    }

    [ApiController]
    [Route("api/[controller]")]
    public class BookingsController : ControllerBase
    {
        private readonly IBookingService _bookingService;

        public BookingsController(IBookingService bookingService)
        {
            _bookingService = bookingService;
        }

        [HttpPost]
        public async Task<IActionResult> CreateBooking([FromBody] CreateBookingRequest req)
        {
            if (!Request.Headers.TryGetValue("X-Session-Id", out var sessionId))
            {
                return BadRequest(new { Message = "Thiếu SessionId giữ chỗ." });
            }

            int? userId = null;
            if (User.Identity?.IsAuthenticated == true)
            {
                var idStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (int.TryParse(idStr, out int uid)) userId = uid;
            }

            try
            {
                var booking = await _bookingService.CreateBookingAsync(req, sessionId, userId);
                return Ok(new 
                { 
                    Message = "Tạo đơn đặt vé thành công.", 
                    BookingCode = booking?.BookingCode,
                    FinalPrice = booking?.FinalPrice,
                    PaymentDeadline = booking?.PaymentDeadline,
                    QrCodeData = booking?.QrCodeData
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Khách hàng đã đăng nhập xem lịch sử vé của mình.
        /// </summary>
        [HttpGet("my-bookings")]
        [Authorize(Roles = "customer,admin,staff")]
        public async Task<IActionResult> GetMyBookings()
        {
            var idStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(idStr, out int userId))
                return Unauthorized(new { Message = "Không xác định được tài khoản." });

            var bookings = await _bookingService.GetMyBookingsAsync(userId);
            return Ok(bookings);
        }
    }

    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "admin,staff")]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;

        public AdminController(IAdminService adminService)
        {
            _adminService = adminService;
        }

        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            var stats = await _adminService.GetDashboardStatsAsync();
            return Ok(stats);
        }

        // --- STATIONS ---
        [HttpGet("stations")]
        public async Task<IActionResult> GetStations()
        {
            return Ok(await _adminService.GetStationsAsync());
        }

        [HttpPost("stations")]
        public async Task<IActionResult> CreateStation([FromBody] VetauBackend.Models.Station station)
        {
            var result = await _adminService.CreateStationAsync(station);
            if (result == null) return BadRequest(new { Message = "Mã ga đã tồn tại" });
            return Ok(result);
        }

        [HttpPut("stations/{id}")]
        public async Task<IActionResult> UpdateStation(int id, [FromBody] VetauBackend.Models.Station station)
        {
            var result = await _adminService.UpdateStationAsync(id, station);
            if (result == null) return NotFound();
            return Ok(result);
        }

        [HttpDelete("stations/{id}")]
        public async Task<IActionResult> DeleteStation(int id)
        {
            var result = await _adminService.DeleteStationAsync(id);
            if (!result) return NotFound();
            return Ok(new { Message = "Đã vô hiệu hóa ga tàu." });
        }

        // --- TRAINS ---
        [HttpGet("trains")]
        public async Task<IActionResult> GetTrains()
        {
            return Ok(await _adminService.GetTrainsAsync());
        }

        // --- BOOKINGS ---
        [HttpGet("bookings")]
        public async Task<IActionResult> GetBookings()
        {
            var bookings = await _adminService.GetBookingsAsync();
            return Ok(bookings);
        }

        [HttpPut("bookings/{id}/status")]
        public async Task<IActionResult> UpdateBookingStatus(int id, [FromBody] string status)
        {
            var result = await _adminService.UpdateBookingStatusAsync(id, status);
            if (!result) return NotFound();
            return Ok(new { Message = "Đã cập nhật trạng thái đơn vé." });
        }
    }
}
