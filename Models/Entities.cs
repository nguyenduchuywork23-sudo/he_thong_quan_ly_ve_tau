using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace VetauBackend.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }
        
        [Required, MaxLength(100)]
        public string Email { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string? Phone { get; set; }
        
        [Required]
        public string PasswordHash { get; set; } = string.Empty;
        
        [Required, MaxLength(100)]
        public string FullName { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string? IdCard { get; set; }
        
        [MaxLength(20)]
        public string Role { get; set; } = "customer"; // customer, admin, staff
        
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Station
    {
        [Key]
        public int Id { get; set; }
        
        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required, MaxLength(10)]
        public string Code { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string? City { get; set; }
        
        [MaxLength(50)]
        public string? Province { get; set; }
        
        public int SortOrder { get; set; } = 0;
        public bool IsActive { get; set; } = true;
    }

    public class Route
    {
        [Key]
        public int Id { get; set; }
        
        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required, MaxLength(20)]
        public string Code { get; set; } = string.Empty;
        
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;

        public ICollection<RouteStation> RouteStations { get; set; } = new List<RouteStation>();
    }

    public class RouteStation
    {
        [Key]
        public int Id { get; set; }
        
        public int RouteId { get; set; }
        public Route Route { get; set; } = null!;
        
        public int StationId { get; set; }
        public Station Station { get; set; } = null!;
        
        public int StopOrder { get; set; }
        public double DistanceKm { get; set; }
    }

    public class Train
    {
        [Key]
        public int Id { get; set; }
        
        [Required, MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [Required, MaxLength(20)]
        public string Code { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string TrainType { get; set; } = "express"; // express, local
        
        public int TotalCarriages { get; set; }
        public bool IsActive { get; set; } = true;

        public ICollection<Carriage> Carriages { get; set; } = new List<Carriage>();
    }

    public class Carriage
    {
        [Key]
        public int Id { get; set; }
        
        public int TrainId { get; set; }
        public Train Train { get; set; } = null!;
        
        public int CarriageNumber { get; set; }
        
        [Required, MaxLength(20)]
        public string CarriageType { get; set; } = string.Empty; // hard_seat, soft_seat, hard_berth_6, soft_berth_4, vip
        
        public int TotalSeats { get; set; }
        public bool IsActive { get; set; } = true;

        public ICollection<Seat> Seats { get; set; } = new List<Seat>();
    }

    public class Seat
    {
        [Key]
        public int Id { get; set; }
        
        public int CarriageId { get; set; }
        public Carriage Carriage { get; set; } = null!;
        
        [Required, MaxLength(10)]
        public string SeatNumber { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string? SeatPosition { get; set; } // window, aisle, middle, upper, lower
        
        public int Floor { get; set; } = 1;
        public bool IsActive { get; set; } = true;
    }

    public class Trip
    {
        [Key]
        public int Id { get; set; }
        
        public int TrainId { get; set; }
        public Train Train { get; set; } = null!;
        
        public int RouteId { get; set; }
        public Route Route { get; set; } = null!;
        
        public DateTime DepartureDate { get; set; }
        
        [Required, MaxLength(10)]
        public string DepartureTime { get; set; } = string.Empty; // "19:30"
        
        [Required, MaxLength(10)]
        public string ArrivalTime { get; set; } = string.Empty;
        
        public int DurationMinutes { get; set; }
        
        [MaxLength(20)]
        public string Status { get; set; } = "scheduled";
        
        public double BasePrice { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Booking
    {
        [Key]
        public int Id { get; set; }
        
        [Required, MaxLength(50)]
        public string BookingCode { get; set; } = string.Empty;
        
        public int? UserId { get; set; }
        public User? User { get; set; }
        
        public int TripId { get; set; }
        public Trip Trip { get; set; } = null!;
        
        public int FromStationId { get; set; }
        public Station FromStation { get; set; } = null!;
        
        public int ToStationId { get; set; }
        public Station ToStation { get; set; } = null!;
        
        [Required, MaxLength(100)]
        public string PassengerName { get; set; } = string.Empty;
        
        [Required, MaxLength(20)]
        public string PassengerIdCard { get; set; } = string.Empty;
        
        [Required, MaxLength(20)]
        public string PassengerPhone { get; set; } = string.Empty;
        
        public string? PassengerEmail { get; set; }
        
        [MaxLength(20)]
        public string PassengerType { get; set; } = "adult";
        
        public int SeatId { get; set; }
        public Seat Seat { get; set; } = null!;
        
        public int CarriageId { get; set; }
        public Carriage Carriage { get; set; } = null!;
        
        public double BasePrice { get; set; }
        public double DiscountPercent { get; set; }
        public double DiscountAmount { get; set; }
        public double FinalPrice { get; set; }
        
        [MaxLength(20)]
        public string Status { get; set; } = "pending";
        
        [MaxLength(50)]
        public string PaymentMethod { get; set; } = "qr_transfer";
        
        public DateTime? PaymentDeadline { get; set; }
        public DateTime? PaidAt { get; set; }
        
        public string? QrCodeData { get; set; } // Base64 image
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    public class SeatLock
    {
        [Key]
        public int Id { get; set; }
        
        public int SeatId { get; set; }
        public Seat Seat { get; set; } = null!;
        
        public int TripId { get; set; }
        public Trip Trip { get; set; } = null!;
        
        public int? UserId { get; set; }
        
        [Required, MaxLength(100)]
        public string SessionId { get; set; } = string.Empty;
        
        public DateTime LockedAt { get; set; } = DateTime.UtcNow;
        public DateTime LockedUntil { get; set; }
        
        public bool IsReleased { get; set; } = false;
    }

    public class ActivityLog
    {
        [Key]
        public int Id { get; set; }
        
        public int? UserId { get; set; }
        
        [Required, MaxLength(50)]
        public string Action { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string? EntityType { get; set; }
        
        public int? EntityId { get; set; }
        
        [MaxLength(50)]
        public string? IpAddress { get; set; }
        
        public string? Details { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class PriceMultiplier
    {
        [Key]
        public int Id { get; set; }
        
        [Required, MaxLength(50)]
        public string CarriageType { get; set; } = string.Empty;
        
        public double Multiplier { get; set; } = 1.0;
        
        public string? Description { get; set; }
    }
}
