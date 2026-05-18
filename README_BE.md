# Hướng dẫn cài đặt Backend Hệ Thống Quản Lý Vé Tàu

Đây là dự án Backend được xây dựng bằng **ASP.NET Core (.NET 10.0)** và sử dụng cơ sở dữ liệu **MySQL** thông qua Entity Framework Core (Pomelo).

## 1. Yêu cầu hệ thống (Prerequisites)

Để chạy được dự án này, bạn cần cài đặt các công cụ sau:
- **.NET SDK 10.0** (hoặc phiên bản tương thích).
- **MySQL Server** (phiên bản 8.0 trở lên).
- IDE khuyên dùng: **Visual Studio 2022**, **JetBrains Rider**, hoặc **Visual Studio Code** với C# Dev Kit.

## 2. Cấu hình Cơ sở dữ liệu (Database Setup)

Dự án yêu cầu kết nối tới MySQL. Bạn cần đảm bảo MySQL đang chạy ở local.

1. Khởi động dịch vụ MySQL trên máy của bạn (Port mặc định `3306`).
2. Thông tin kết nối mặc định được cấu hình trong file `appsettings.json` như sau:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=localhost;Port=3306;Database=vetau_db;Uid=root;Pwd=123456;"
   }
   ```
3. Nếu cấu hình MySQL của bạn khác (User, Password, Port), vui lòng cập nhật lại file `appsettings.json` hoặc `appsettings.Development.json` cho phù hợp.

## 3. Khôi phục thư viện và Cập nhật Database

Mở Terminal (hoặc Command Prompt, PowerShell) tại thư mục gốc của dự án backend (nơi chứa file `VetauBackend.csproj`):

1. **Khôi phục các thư viện NuGet:**
   ```bash
   dotnet restore
   ```

2. **Khởi tạo và cập nhật cấu trúc cơ sở dữ liệu (Migration):**
   Chạy lệnh sau để Entity Framework Core tự động tạo database `vetau_db` và các bảng cần thiết:
   ```bash
   dotnet ef database update
   ```
   *(Lưu ý: Nếu bạn chưa cài đặt EF Core tools, hãy chạy lệnh: `dotnet tool install --global dotnet-ef`)*

## 4. Chạy dự án (Run the Backend)

Sau khi thiết lập xong database, bạn có thể chạy dự án bằng lệnh:
```bash
dotnet run
```
Hoặc nếu bạn dùng IDE như Visual Studio, chỉ cần bấm nút **Run (F5)** hoặc **Start Without Debugging (Ctrl+F5)**.

Khi ứng dụng khởi động thành công, API sẽ lắng nghe trên cổng mặc định (ví dụ: `http://localhost:5000` hoặc `https://localhost:5001`). Bạn có thể truy cập vào **Swagger UI** để xem danh sách các API và test trực tiếp:
```
http://localhost:<port>/swagger
```

## 5. Các cấu hình quan trọng khác

- **JWT Settings:** Secret key và thời gian hết hạn của token được cấu hình trong `appsettings.json` tại mục `JwtSettings`.
- **AppConfig:** Các cấu hình nghiệp vụ như thời gian giữ chỗ vé (`SeatLockMinutes`) và thời hạn thanh toán (`PaymentDeadlineMinutes`) cũng nằm trong `appsettings.json`.
