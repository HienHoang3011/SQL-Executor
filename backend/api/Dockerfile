# ─────────────────────────────────────────────────────────────────────────────
# FastAPI service  (uv project workflow)
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.12-slim

# Copy uv binary từ image chính thức
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# pymssql cần FreeTDS và gcc để build
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        gcc \
        freetds-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy metadata trước để tận dụng Docker layer cache
COPY pyproject.toml .python-version ./

# Cài lần đầu để cache layer (không có source)
RUN uv sync --no-install-project

# Copy source code
COPY main.py .

# Sync lần cuối (cài project nếu cần)
RUN uv sync

EXPOSE 8000

# Chạy qua uv run để dùng đúng venv của project
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
