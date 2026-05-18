using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using VetauBackend.Models;

namespace VetauBackend.Data
{
    public static class SeedData
    {
        public static void Initialize(AppDbContext context)
        {
            context.Database.EnsureCreated();

            if (!context.Users.Any(u => u.Role == "admin"))
            {
                context.Users.Add(new User
                {
                    Email = "admin@vetau.vn",
                    FullName = "Admin Hệ Thống",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123456"),
                    Role = "admin",
                    IsActive = true
                });
                context.SaveChanges();
            }

            if (!context.Users.Any(u => u.Role == "staff"))
            {
                context.Users.Add(new User
                {
                    Email = "staff@vetau.vn",
                    FullName = "Nhân Viên Quản Lý",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("staff123456"),
                    Role = "staff",
                    IsActive = true
                });
                context.SaveChanges();
            }

            if (!context.PriceMultipliers.Any())
            {
                context.PriceMultipliers.AddRange(
                    new PriceMultiplier { CarriageType = "hard_seat", Multiplier = 1.0, Description = "Ghế ngồi cứng" },
                    new PriceMultiplier { CarriageType = "soft_seat", Multiplier = 1.3, Description = "Ghế ngồi mềm" },
                    new PriceMultiplier { CarriageType = "hard_berth_6", Multiplier = 1.6, Description = "Giường nằm cứng 6 chỗ" },
                    new PriceMultiplier { CarriageType = "soft_berth_4", Multiplier = 2.0, Description = "Giường nằm mềm 4 chỗ" },
                    new PriceMultiplier { CarriageType = "vip", Multiplier = 2.5, Description = "VIP" }
                );
                context.SaveChanges();
            }

            if (!context.Stations.Any())
            {
                var stations = new List<Station>
                {
                    new Station { Name = "Ga Hà Nội", Code = "HAN", City = "Hà Nội", Province = "Hà Nội", SortOrder = 1 },
                    new Station { Name = "Ga Phủ Lý", Code = "PLY", City = "Phủ Lý", Province = "Hà Nam", SortOrder = 3 },
                    new Station { Name = "Ga Nam Định", Code = "NDH", City = "Nam Định", Province = "Nam Định", SortOrder = 4 },
                    new Station { Name = "Ga Thanh Hóa", Code = "THA", City = "Thanh Hóa", Province = "Thanh Hóa", SortOrder = 6 },
                    new Station { Name = "Ga Vinh", Code = "VIH", City = "Vinh", Province = "Nghệ An", SortOrder = 7 },
                    new Station { Name = "Ga Đồng Hới", Code = "DOH", City = "Đồng Hới", Province = "Quảng Bình", SortOrder = 9 },
                    new Station { Name = "Ga Huế", Code = "HUE", City = "Huế", Province = "Thừa Thiên Huế", SortOrder = 11 },
                    new Station { Name = "Ga Đà Nẵng", Code = "DNG", City = "Đà Nẵng", Province = "Đà Nẵng", SortOrder = 12 },
                    new Station { Name = "Ga Nha Trang", Code = "NTG", City = "Nha Trang", Province = "Khánh Hòa", SortOrder = 17 },
                    new Station { Name = "Ga Sài Gòn", Code = "SGN", City = "TP.HCM", Province = "TP.HCM", SortOrder = 21 }
                };
                context.Stations.AddRange(stations);
                context.SaveChanges();
            }

            if (!context.Routes.Any())
            {
                var hnSg = new VetauBackend.Models.Route { Name = "Hà Nội - Sài Gòn", Code = "HN-SG", Description = "Tuyến Thống Nhất Bắc Nam (Chiều đi)" };
                context.Routes.Add(hnSg);
                
                var sgHn = new VetauBackend.Models.Route { Name = "Sài Gòn - Hà Nội", Code = "SG-HN", Description = "Tuyến Thống Nhất Bắc Nam (Chiều về)" };
                context.Routes.Add(sgHn);
                
                context.SaveChanges();

                var stations = context.Stations.OrderBy(s => s.SortOrder).ToList();
                
                int order = 1;
                foreach (var st in stations)
                {
                    context.RouteStations.Add(new RouteStation
                    {
                        RouteId = hnSg.Id,
                        StationId = st.Id,
                        StopOrder = order++,
                        DistanceKm = (order - 1) * 100
                    });
                }

                var reverseStations = stations.AsEnumerable().Reverse().ToList();
                int revOrder = 1;
                foreach (var st in reverseStations)
                {
                    context.RouteStations.Add(new RouteStation
                    {
                        RouteId = sgHn.Id,
                        StationId = st.Id,
                        StopOrder = revOrder++,
                        DistanceKm = (revOrder - 1) * 100
                    });
                }

                context.SaveChanges();
            }

            if (!context.Trains.Any())
            {
                var se1 = new Train { Name = "SE1", Code = "SE1", TrainType = "express", TotalCarriages = 5 };
                context.Trains.Add(se1);
                
                var se2 = new Train { Name = "SE2", Code = "SE2", TrainType = "express", TotalCarriages = 5 };
                context.Trains.Add(se2);
                context.SaveChanges();

                var trains = new[] { se1, se2 };
                var carriageTypes = new[] { "soft_seat", "soft_seat", "hard_berth_6", "soft_berth_4", "vip" };
                
                foreach (var tr in trains)
                {
                    for (int i = 0; i < carriageTypes.Length; i++)
                    {
                        var c = new Carriage
                        {
                            TrainId = tr.Id,
                            CarriageNumber = i + 1,
                            CarriageType = carriageTypes[i],
                            TotalSeats = carriageTypes[i].Contains("seat") ? 64 : (carriageTypes[i].Contains("6") ? 42 : 28)
                        };
                        if (c.CarriageType == "vip") c.TotalSeats = 16;
                        context.Carriages.Add(c);
                        context.SaveChanges();

                        var seats = new List<Seat>();
                        for (int s = 1; s <= c.TotalSeats; s++)
                        {
                            seats.Add(new Seat
                            {
                                CarriageId = c.Id,
                                SeatNumber = $"{i + 1}-{(c.CarriageType.Contains("berth") ? "G" : "")}{s}",
                                Floor = c.CarriageType.Contains("berth") ? ((s - 1) % 2) + 1 : 1
                            });
                        }
                        context.Seats.AddRange(seats);
                    }
                }
                context.SaveChanges();
            }

            if (!context.Trips.Any())
            {
                var trainSE1 = context.Trains.FirstOrDefault(t => t.Code == "SE1");
                var trainSE2 = context.Trains.FirstOrDefault(t => t.Code == "SE2");
                var routeHnSg = context.Routes.FirstOrDefault(r => r.Code == "HN-SG");
                var routeSgHn = context.Routes.FirstOrDefault(r => r.Code == "SG-HN");
                
                if (trainSE1 != null && routeHnSg != null)
                {
                    for (int i = 0; i <= 10; i++)
                    {
                        var tripDate = DateTime.UtcNow.Date.AddDays(i);
                        context.Trips.Add(new Trip
                        {
                            TrainId = trainSE1.Id,
                            RouteId = routeHnSg.Id,
                            DepartureDate = tripDate,
                            DepartureTime = "19:30",
                            ArrivalTime = "04:30",
                            DurationMinutes = 1980,
                            BasePrice = 800000,
                            Status = "scheduled"
                        });
                    }

                    if (trainSE2 != null && routeSgHn != null)
                    {
                        for (int i = 0; i <= 10; i++)
                        {
                            var tripDate = DateTime.UtcNow.Date.AddDays(i);
                            context.Trips.Add(new Trip
                            {
                                TrainId = trainSE2.Id,
                                RouteId = routeSgHn.Id,
                                DepartureDate = tripDate,
                                DepartureTime = "20:00",
                                ArrivalTime = "05:00",
                                DurationMinutes = 1980,
                                BasePrice = 800000,
                                Status = "scheduled"
                            });
                        }
                    }
                    context.SaveChanges();
                }
            }

            if (!context.Bookings.Any())
            {
                var todayTrip = context.Trips.FirstOrDefault(t => t.DepartureDate.Date == DateTime.UtcNow.Date);
                if (todayTrip != null)
                {
                    var carriage = context.Carriages.Include(c => c.Seats).FirstOrDefault(c => c.TrainId == todayTrip.TrainId);
                    var hnStation = context.Stations.FirstOrDefault(s => s.Code == "HAN");
                    var sgStation = context.Stations.FirstOrDefault(s => s.Code == "SGN");
                    var adminUser = context.Users.FirstOrDefault(u => u.Role == "admin");

                    if (carriage != null && hnStation != null && sgStation != null && adminUser != null)
                    {
                        var seatsToBook = carriage.Seats.Take(3).ToList();
                        foreach (var seat in seatsToBook)
                        {
                            context.Bookings.Add(new Booking
                            {
                                BookingCode = "VT" + DateTime.Now.ToString("yyyyMMdd") + new Random().Next(100, 999).ToString(),
                                UserId = adminUser.Id,
                                TripId = todayTrip.Id,
                                FromStationId = hnStation.Id,
                                ToStationId = sgStation.Id,
                                SeatId = seat.Id,
                                CarriageId = carriage.Id,
                                PassengerName = "Nguyễn Văn Khách",
                                PassengerIdCard = "012345678912",
                                PassengerPhone = "0987654321",
                                PassengerEmail = "khach@gmail.com",
                                PassengerType = "adult",
                                BasePrice = todayTrip.BasePrice,
                                DiscountPercent = 0,
                                DiscountAmount = 0,
                                FinalPrice = todayTrip.BasePrice,
                                Status = "confirmed",
                                PaymentMethod = "qr_transfer",
                                PaymentDeadline = DateTime.UtcNow.AddMinutes(30),
                                PaidAt = DateTime.UtcNow,
                                QrCodeData = "dummy_qr_data",
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow
                            });
                        }
                        context.SaveChanges();
                    }
                }
            }
        }
    }
}
