# Hướng dẫn cài đặt Frontend Hệ Thống Quản Lý Vé Tàu (App)

Đây là ứng dụng di động/ứng dụng web dành cho Hệ thống quản lý vé tàu, được phát triển bằng framework **Flutter**. Ứng dụng giao tiếp với backend thông qua RESTful API.

## 1. Yêu cầu hệ thống (Prerequisites)

Để chạy được dự án này, bạn cần cài đặt:
- **Flutter SDK** (Phiên bản `>=3.3.0`).
- **Dart SDK** (Đi kèm với Flutter).
- Công cụ phát triển (IDE): **Visual Studio Code**, **Android Studio**, hoặc **IntelliJ IDEA** có cài đặt plugin Flutter & Dart.
- **Android SDK** (nếu build cho Android) / **Xcode** (nếu build cho iOS) / Trình duyệt Chrome (nếu chạy bản Web).

## 2. Kiểm tra môi trường Flutter

Mở terminal và chạy lệnh sau để đảm bảo môi trường Flutter của bạn đã được thiết lập đúng cách và không có lỗi:
```bash
flutter doctor
```
Hãy chắc chắn rằng không có dấu `X` đỏ nào ở các phần quan trọng (đặc biệt là công cụ build nền tảng bạn muốn chạy).

## 3. Cài đặt các thư viện (Dependencies)

Mở Terminal (hoặc Command Prompt, PowerShell) và di chuyển vào thư mục chứa mã nguồn frontend (`vetau_app`):

```bash
cd vetau_app
```

Khôi phục và tải về tất cả các package/thư viện đã được định nghĩa trong file `pubspec.yaml`:
```bash
flutter pub get
```

## 4. Kết nối API Backend

Ứng dụng Flutter cần gọi tới API của Backend. 
- Mặc định, base URL thường được cấu hình trong source code (ví dụ như trong thư mục `lib/core/network` hoặc một file config/constants). 
- Đảm bảo Backend (ASP.NET Core) đang chạy tại local.
- **Lưu ý quan trọng cho Android Emulator:** Nếu bạn chạy app trên máy ảo Android và Backend chạy ở localhost máy thật, bạn cần đổi `localhost` hoặc `127.0.0.1` trong app Flutter thành `10.0.2.2` để máy ảo có thể gọi được API tới máy chủ local.

## 5. Chạy dự án (Run the App)

Bạn có thể chạy dự án trực tiếp trên thiết bị thật, máy ảo giả lập hoặc trình duyệt web.

1. Liệt kê các thiết bị đang có sẵn:
   ```bash
   flutter devices
   ```
2. Chạy ứng dụng:
   ```bash
   flutter run
   ```
   Hoặc có thể chỉ định chính xác thiết bị bằng tham số `-d` (ví dụ: `flutter run -d chrome` hoặc `flutter run -d emulator-5554`).

## Các công nghệ sử dụng chính

- **Provider:** Quản lý state (State Management).
- **GoRouter:** Xử lý điều hướng và định tuyến.
- **Dio:** Gọi HTTP request tới Backend.
- **Shared Preferences:** Lưu trữ dữ liệu cục bộ (như token, trạng thái đăng nhập).
