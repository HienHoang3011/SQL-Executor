# Hệ Thống Quản Lý Bệnh Viện Tích Hợp — SQL Executor

Giao diện web cho phép chạy câu lệnh `SELECT` trực tiếp trên database bệnh viện (`Hospital_Integrated_DB`).

## Kiến trúc

```
frontend/          → Static HTML/CSS/JS (SQL Executor UI)
backend/
  Dockerfile       → SQL Server 2022 + auto-init schema
  sql/init.sql     → Script tạo bảng & dữ liệu mẫu
  api/             → FastAPI (Python 3.12 + uv)
docker-compose.yml → Khởi động toàn bộ hệ thống
```

| Service    | Port  | URL                        |
|------------|-------|----------------------------|
| SQL Server | 1433  | `localhost:1433`           |
| FastAPI    | 8000  | `http://localhost:8000`    |
| Frontend   | 8080* | `http://localhost:8080`    |

---

## 🐳 Cách 1 — Docker (khuyến nghị)

> Yêu cầu: [Docker Desktop](https://www.docker.com/products/docker-desktop/) đang chạy.

```bash
# Clone / mở thư mục dự án, sau đó:
docker compose up --build
```

- Lần đầu build mất ~2–5 phút (pull image SQL Server + cài dependencies Python).
- API sẽ tự chờ SQL Server sẵn sàng (`depends_on: service_healthy`).

**macOS (Apple Silicon):** SQL Server chạy qua Rosetta emulation `amd64` → khởi động chậm ~60–90s, chờ log `Database initialized successfully`.

**Windows:** Docker Desktop cần bật **WSL 2 backend** (Settings → General → *Use the WSL 2 based engine*). Sau đó lệnh `docker compose` chạy giống nhau trong PowerShell, CMD, hoặc Windows Terminal.

**Kiểm tra API:**
```
http://localhost:8000/health
```

**Dừng:**
```bash
docker compose down
```

**Xóa luôn data volume (reset DB):**
```bash
docker compose down -v
```

---

## 🐍 Cách 2 — Chạy Backend cục bộ (không Docker)

> Yêu cầu: Python ≥ 3.12, [uv](https://docs.astral.sh/uv/), SQL Server đang chạy riêng.

```bash
cd backend/api
uv sync
```

**macOS / Linux:**
```bash
export DB_HOST=localhost
export DB_PORT=1433
export DB_USER=sa
export DB_PASSWORD="YourStrong!Passw0rd"
export DB_NAME=Hospital_Integrated_DB

uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Windows — PowerShell:**
```powershell
$env:DB_HOST="localhost"
$env:DB_PORT="1433"
$env:DB_USER="sa"
$env:DB_PASSWORD="YourStrong!Passw0rd"
$env:DB_NAME="Hospital_Integrated_DB"

uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Windows — CMD:**
```cmd
set DB_HOST=localhost
set DB_PORT=1433
set DB_USER=sa
set DB_PASSWORD=YourStrong!Passw0rd
set DB_NAME=Hospital_Integrated_DB

uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

API docs (Swagger): `http://localhost:8000/docs`

---

## 🌐 Cách 3 — Chạy Frontend

Frontend là static files, không cần build. Cần **backend đang chạy** ở `http://localhost:8000`.

### Cách 3a — Python HTTP Server

**macOS / Linux:**
```bash
cd frontend
python3 -m http.server 8080
```

**Windows (PowerShell / CMD):**
```powershell
cd frontend
python -m http.server 8080
```

Mở trình duyệt: `http://localhost:8080`

### Cách 3b — VS Code Live Server

1. Cài extension **Live Server** trong VS Code
2. Chuột phải vào `frontend/index.html` → **Open with Live Server**
3. Truy cập `http://127.0.0.1:5500`

> **Lưu ý:** Nếu frontend chạy ở port khác `8000`, API URL được cấu hình trong `frontend/js/app.js`:
> ```js
> API_URL: 'http://localhost:8000/api/query'
> ```

---

## 🔑 Thông tin kết nối mặc định

| Thông số    | Giá trị              |
|-------------|----------------------|
| Host        | `localhost`          |
| Port        | `1433`               |
| User        | `sa`                 |
| Password    | `YourStrong!Passw0rd`|
| Database    | `Hospital_Integrated_DB` |

> ⚠️ Đổi `SA_PASSWORD` trong `docker-compose.yml` trước khi deploy production.
