namespace VetauBackend.DTOs
{
    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class RegisterRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
    }

    public class AuthResponse
    {
        public string Token { get; set; } = string.Empty;
        public object User { get; set; } = null!;
    }

    public class SearchTripRequest
    {
        public string FromStation { get; set; } = string.Empty;
        public string ToStation { get; set; } = string.Empty;
        public string Date { get; set; } = string.Empty;
    }

    public class LockSeatRequest
    {
        public int SeatId { get; set; }
        public int TripId { get; set; }
    }

    public class CreateBookingRequest
    {
        public int TripId { get; set; }
        public int FromStationId { get; set; }
        public int ToStationId { get; set; }
        public int SeatId { get; set; }
        public int CarriageId { get; set; }
        
        public string PassengerName { get; set; } = string.Empty;
        public string PassengerIdCard { get; set; } = string.Empty;
        public string PassengerPhone { get; set; } = string.Empty;
        public string? PassengerEmail { get; set; }
        public string PassengerType { get; set; } = "adult";
        
        public string PaymentMethod { get; set; } = "qr_transfer";
    }

    /// <summary>
    /// DTO cho PUT /api/Admin/bookings/{id}/status
    /// FE gửi {"Status": "Confirmed"} hoặc {"Status": "Cancelled"}
    /// </summary>
    public class UpdateStatusRequest
    {
        public string Status { get; set; } = string.Empty;
    }

    /// <summary>
    /// DTO cho PUT /api/Staff/bookings/{id}/reject
    /// </summary>
    public class RejectBookingRequest
    {
        public string? Reason { get; set; }
    }
}

