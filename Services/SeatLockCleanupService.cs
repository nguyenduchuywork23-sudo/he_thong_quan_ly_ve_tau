using System;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using VetauBackend.Data;
using System.Threading;
using System.Threading.Tasks;

namespace VetauBackend.Services
{
    public class SeatLockCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<SeatLockCleanupService> _logger;

        public SeatLockCleanupService(IServiceProvider serviceProvider, ILogger<SeatLockCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SeatLock Cleanup Service is running.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                        // Release expired locks
                        var expiredLocks = await context.SeatLocks
                            .Where(sl => sl.LockedUntil < DateTime.UtcNow && !sl.IsReleased)
                            .ToListAsync(stoppingToken);

                        if (expiredLocks.Any())
                        {
                            foreach (var lockItem in expiredLocks)
                            {
                                lockItem.IsReleased = true;
                            }
                            await context.SaveChangesAsync(stoppingToken);
                            _logger.LogInformation($"Released {expiredLocks.Count} expired seat locks.");
                        }

                        // Expire pending bookings that pass payment deadline
                        var expiredBookings = await context.Bookings
                            .Where(b => b.Status == "pending" && b.PaymentDeadline < DateTime.UtcNow)
                            .ToListAsync(stoppingToken);

                        if (expiredBookings.Any())
                        {
                            foreach (var booking in expiredBookings)
                            {
                                booking.Status = "expired";
                            }
                            await context.SaveChangesAsync(stoppingToken);
                            _logger.LogInformation($"Expired {expiredBookings.Count} pending bookings.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred executing SeatLockCleanupService.");
                }

                // Run every minute
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }
}
