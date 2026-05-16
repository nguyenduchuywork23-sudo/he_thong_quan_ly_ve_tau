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

            // 1. Seed Admin
            if (!context.Users.Any(u => u.Role == "admin"))
            {
                // Mật khẩu hash tạm (bạn có thể thay bằng BCrypt.Net sau)
                // Vì không có thư viện Bcrypt mặc định, tạm dùng MD5 hoặc chuỗi giả.
                // Ở đây tôi giả định sẽ dùng BCrypt.Net-Next (cần cài thêm) hoặc viết hàm hash. 
                // Tạm thời để plain hoặc chuỗi đơn giản.
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

            // Seed Staff account
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

            // 2. Price Multipliers
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

            // 3. Stations
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

            // 4. Routes
            if (!context.Routes.Any())
            {
                var hnSg = new VetauBackend.Models.Route { Name = "Hà Nội - Sài Gòn", Code = "HN-SG", Description = "Tuyến Thống Nhất Bắc Nam" };
                context.Routes.Add(hnSg);
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
                        DistanceKm = (order - 1) * 100 // Giả lập khoảng cách
                    });
                }
                context.SaveChanges();
            }

            // 5. Trains & Carriages & Seats
            if (!context.Trains.Any())
            {
                var se1 = new Train { Name = "SE1", Code = "SE1", TrainType = "express", TotalCarriages = 5 };
                context.Trains.Add(se1);
                context.SaveChanges();

                // Tạo toa
                var carriageTypes = new[] { "soft_seat", "soft_seat", "hard_berth_6", "soft_berth_4", "vip" };
                for (int i = 0; i < carriageTypes.Length; i++)
                {
                    var c = new Carriage
                    {
                        TrainId = se1.Id,
                        CarriageNumber = i + 1,
                        CarriageType = carriageTypes[i],
                        TotalSeats = carriageTypes[i].Contains("seat") ? 64 : (carriageTypes[i].Contains("6") ? 42 : 28)
                    };
                    if (c.CarriageType == "vip") c.TotalSeats = 16;
                    context.Carriages.Add(c);
                    context.SaveChanges();

                    // Tạo ghế cho toa này
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
                context.SaveChanges();
            }

            // 6. Trips
            if (!context.Trips.Any())
            {
                var train = context.Trains.FirstOrDefault(t => t.Code == "SE1");
                var route = context.Routes.FirstOrDefault(r => r.Code == "HN-SG");
                if (train != null && route != null)
                {
                    for (int i = 1; i <= 10; i++)
                    {
                        var tripDate = DateTime.UtcNow.Date.AddDays(i);
                        context.Trips.Add(new Trip
                        {
                            TrainId = train.Id,
                            RouteId = route.Id,
                            DepartureDate = tripDate,
                            DepartureTime = "19:30",
                            ArrivalTime = "04:30",
                            DurationMinutes = 1980,
                            BasePrice = 800000,
                            Status = "scheduled"
                        });
                    }
                    context.SaveChanges();
                }
            }
        }
    }
}
