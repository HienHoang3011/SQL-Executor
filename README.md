# Hệ Thống Quản Lý Bệnh Viện Tư - Frontend

Giao diện web hiển thị cấu trúc cơ sở dữ liệu bệnh viện và cho phép thực thi câu lệnh SQL SELECT.

## 🌐 Cách hiển thị Frontend lên trình duyệt

### Cách 1: Sử dụng Python HTTP Server (Khuyến nghị)

**Bước 1:** Mở PowerShell/Terminal

**Bước 2:** Di chuyển vào thư mục frontend:
```bash
cd d:\HQTCSDL\frontend
```

**Bước 3:** Chạy HTTP server:
```bash
python -m http.server 8080
```

**Bước 4:** Mở trình duyệt và truy cập:
```
http://localhost:8080
```

**Dừng server:** Nhấn `Ctrl + C` trong terminal

---

### Cách 2: Sử dụng VS Code Live Server

1. Cài đặt extension **"Live Server"** trong VS Code
2. Chuột phải vào file `index.html`
3. Chọn **"Open with Live Server"**
4. Giao diện sẽ tự động mở tại `http://127.0.0.1:5500`
