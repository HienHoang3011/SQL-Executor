"""
SQL Executor - FastAPI Backend
Nhận câu lệnh SELECT từ frontend, thực thi trên SQL Server, trả về kết quả.
"""

import os
import re
import decimal
import datetime
from typing import Any

import pymssql
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ─────────────────────────────────────────────────────────────────────────────
# App setup
# ─────────────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="SQL Executor API",
    description="Chỉ cho phép thực thi câu lệnh SELECT trên Hospital_Integrated_DB",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Cho phép mọi origin (frontend static / localhost)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────────────────────────────────────
# Config từ environment variables
# ─────────────────────────────────────────────────────────────────────────────
DB_HOST     = os.getenv("DB_HOST",     "sqlserver")
DB_USER     = os.getenv("DB_USER",     "sa")
DB_PASSWORD = os.getenv("DB_PASSWORD", "YourStrong!Passw0rd")
DB_NAME     = os.getenv("DB_NAME",     "Hospital_Integrated_DB")
DB_PORT     = int(os.getenv("DB_PORT", "1433"))


# ─────────────────────────────────────────────────────────────────────────────
# Schema
# ─────────────────────────────────────────────────────────────────────────────
class QueryRequest(BaseModel):
    query: str


class QueryResponse(BaseModel):
    data: list[dict[str, Any]]
    row_count: int
    columns: list[str]


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
def get_connection() -> pymssql.Connection:
    """Tạo kết nối tới SQL Server."""
    return pymssql.connect(
        server=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset="UTF-8",
        login_timeout=10,
    )


def is_select_only(query: str) -> bool:
    """
    Kiểm tra câu lệnh có phải chỉ là SELECT không.
    Loại bỏ comment trước khi kiểm tra để tránh bypass.
    """
    # Xóa block comments  /* ... */
    cleaned = re.sub(r"/\*.*?\*/", "", query, flags=re.DOTALL)
    # Xóa line comments  -- ...
    cleaned = re.sub(r"--[^\n]*", "", cleaned)
    # Lấy token đầu tiên (không phân biệt hoa thường)
    tokens = cleaned.strip().split()
    if not tokens:
        return False
    return tokens[0].upper() == "SELECT"


def serialize_row(row: dict) -> dict[str, Any]:
    """Chuyển đổi kiểu dữ liệu đặc biệt sang JSON-serializable."""
    result = {}
    for key, value in row.items():
        if value is None:
            result[key] = None
        elif isinstance(value, (datetime.datetime, datetime.date, datetime.time)):
            result[key] = value.isoformat()
        elif isinstance(value, decimal.Decimal):
            result[key] = float(value)
        elif isinstance(value, bytes):
            result[key] = value.hex()
        else:
            result[key] = value
    return result


# ─────────────────────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────────────────────
@app.get("/", summary="Health check")
def root():
    return {"status": "ok", "message": "SQL Executor API đang hoạt động"}


@app.get("/health", summary="Health check chi tiết")
def health():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1 AS ping")
        conn.close()
        return {"status": "ok", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Không thể kết nối DB: {str(e)}")


@app.post("/api/query", response_model=QueryResponse, summary="Thực thi câu lệnh SELECT")
def execute_query(request: QueryRequest):
    """
    Nhận câu lệnh SQL từ frontend.
    - Chỉ cho phép câu lệnh **SELECT**.
    - Trả về danh sách bản ghi dạng JSON.
    - Từ chối INSERT / UPDATE / DELETE / DROP / EXEC và các lệnh nguy hiểm khác.
    """
    query = request.query.strip()

    # 1. Kiểm tra rỗng
    if not query:
        raise HTTPException(
            status_code=400,
            detail="Câu lệnh SQL không được để trống.",
        )

    # 2. Chỉ cho phép SELECT
    if not is_select_only(query):
        raise HTTPException(
            status_code=400,
            detail=(
                "Chỉ hỗ trợ câu lệnh SELECT. "
                "Các lệnh INSERT, UPDATE, DELETE, DROP, EXEC, CREATE... "
                "không được phép thực thi qua giao diện này."
            ),
        )

    # 3. Thực thi truy vấn
    try:
        conn = get_connection()
        cursor = conn.cursor(as_dict=True)
        cursor.execute(query)
        rows = cursor.fetchall()
        conn.close()
    except pymssql.OperationalError as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Không thể kết nối đến SQL Server: {exc}",
        )
    except pymssql.ProgrammingError as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Lỗi cú pháp SQL: {exc}",
        )
    except pymssql.DatabaseError as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Lỗi cơ sở dữ liệu: {exc}",
        )
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Lỗi không xác định: {exc}",
        )

    # 4. Serialize & trả về
    data = [serialize_row(row) for row in rows]
    columns = list(data[0].keys()) if data else []

    return QueryResponse(
        data=data,
        row_count=len(data),
        columns=columns,
    )
