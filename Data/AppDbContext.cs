using Microsoft.EntityFrameworkCore;
using VetauBackend.Models;

namespace VetauBackend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Station> Stations { get; set; }
        public DbSet<VetauBackend.Models.Route> Routes { get; set; }
        public DbSet<RouteStation> RouteStations { get; set; }
        public DbSet<Train> Trains { get; set; }
        public DbSet<Carriage> Carriages { get; set; }
        public DbSet<Seat> Seats { get; set; }
        public DbSet<Trip> Trips { get; set; }
        public DbSet<Booking> Bookings { get; set; }
        public DbSet<SeatLock> SeatLocks { get; set; }
        public DbSet<ActivityLog> ActivityLogs { get; set; }
        public DbSet<PriceMultiplier> PriceMultipliers { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();
            modelBuilder.Entity<Station>().HasIndex(s => s.Code).IsUnique();
            modelBuilder.Entity<VetauBackend.Models.Route>().HasIndex(r => r.Code).IsUnique();
            modelBuilder.Entity<Train>().HasIndex(t => t.Code).IsUnique();
            
            modelBuilder.Entity<RouteStation>()
                .HasIndex(rs => new { rs.RouteId, rs.StationId }).IsUnique();
            
            modelBuilder.Entity<Carriage>()
                .HasIndex(c => new { c.TrainId, c.CarriageNumber }).IsUnique();
                
            modelBuilder.Entity<Seat>()
                .HasIndex(s => new { s.CarriageId, s.SeatNumber }).IsUnique();
                
            modelBuilder.Entity<Trip>()
                .HasIndex(t => new { t.TrainId, t.DepartureDate, t.DepartureTime }).IsUnique();
                
            modelBuilder.Entity<Booking>().HasIndex(b => b.BookingCode).IsUnique();
            
            modelBuilder.Entity<SeatLock>()
                .HasIndex(sl => new { sl.SeatId, sl.TripId }).IsUnique();
                
            modelBuilder.Entity<PriceMultiplier>().HasIndex(p => p.CarriageType).IsUnique();

            modelBuilder.Entity<Booking>()
                .HasOne(b => b.FromStation)
                .WithMany()
                .HasForeignKey(b => b.FromStationId)
                .OnDelete(DeleteBehavior.Restrict);
                
            modelBuilder.Entity<Booking>()
                .HasOne(b => b.ToStation)
                .WithMany()
                .HasForeignKey(b => b.ToStationId)
                .OnDelete(DeleteBehavior.Restrict);
                
            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Seat)
                .WithMany()
                .HasForeignKey(b => b.SeatId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Carriage)
                .WithMany()
                .HasForeignKey(b => b.CarriageId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Booking>()
                .HasOne(b => b.Trip)
                .WithMany()
                .HasForeignKey(b => b.TripId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
