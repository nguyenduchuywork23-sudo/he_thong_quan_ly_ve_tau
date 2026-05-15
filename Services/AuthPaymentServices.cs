using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using VetauBackend.Data;
using VetauBackend.DTOs;
using VetauBackend.Models;
using Net.Codecrete.QrCodeGenerator;

namespace VetauBackend.Services
{
    public interface IAuthService
    {
        Task<AuthResponse?> LoginAsync(LoginRequest request);
        Task<AuthResponse?> RegisterAsync(RegisterRequest request);
    }

    public class AuthService : IAuthService
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public AuthService(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        public async Task<AuthResponse?> LoginAsync(LoginRequest request)
        {
            var user = await _context.Users.SingleOrDefaultAsync(u => u.Email == request.Email && u.IsActive);
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return null;

            return GenerateAuthResponse(user);
        }

        public async Task<AuthResponse?> RegisterAsync(RegisterRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new Exception("Email đã được sử dụng.");

            var user = new User
            {
                Email = request.Email,
                FullName = request.FullName,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = "customer",
                IsActive = true
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return GenerateAuthResponse(user);
        }

        private AuthResponse GenerateAuthResponse(User user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_config["JwtSettings:Secret"] ?? "2f913d7e6c4a8b5024a19c5b8e97f06d");
            var expiresDays = _config.GetValue<int>("JwtSettings:ExpiryDays", 7);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Email, user.Email),
                    new Claim(ClaimTypes.Role, user.Role)
                }),
                Expires = DateTime.UtcNow.AddDays(expiresDays),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return new AuthResponse
            {
                Token = tokenHandler.WriteToken(token),
                User = new { user.Id, user.Email, user.FullName, user.Role }
            };
        }
    }

    public interface IPaymentService
    {
        string GenerateVietQr(string bankId, string accountNo, double amount, string info);
    }

    public class PaymentService : IPaymentService
    {
        public string GenerateVietQr(string bankId, string accountNo, double amount, string info)
        {
            // Định dạng VietQR chuỗi tĩnh cơ bản:
            // (Thực tế VietQR có chuẩn TLV phức tạp, để rút gọn dùng chuỗi QR dạng đơn giản hoặc text hiển thị)
            // Chuỗi ví dụ mẫu (không hoàn toàn chuẩn VietQR xịn nhưng frontend có thể parse)
            string payload = $"VIETQR|{bankId}|{accountNo}|{amount}|{info}";
            
            var qr = QrCode.EncodeText(payload, QrCode.Ecc.Medium);
            var svg = qr.ToSvgString(4);
            return svg; // Trả về dạng SVG chuỗi để FE render hoặc parse. 
            // Nếu dùng dạng Base64 PNG cần dùng thư viện khác hoặc viết helper cho Net.Codecrete
            // Để đơn giản, ta trả về data uri dạng svg: "data:image/svg+xml;utf8," + ...
        }
    }
}
