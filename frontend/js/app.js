/**
 * SQL Query Executor - Frontend Application
 * Xử lý giao diện và giao tiếp với Backend API
 */

// ===== Sample Queries Data =====
const SAMPLE_QUERIES = {
    basic: [
        {
            title: 'Danh sách Khoa/Phòng',
            desc: 'SELECT * FROM Department',
            sql: 'SELECT * FROM Department ORDER BY deptName'
        },
        {
            title: 'Danh sách Nhân viên',
            desc: 'SELECT TOP 20 * FROM Staff',
            sql: 'SELECT TOP 20 * FROM Staff ORDER BY fullName'
        },
        {
            title: 'Danh sách Bệnh nhân',
            desc: 'SELECT TOP 20 * FROM Patient',
            sql: 'SELECT TOP 20 * FROM Patient ORDER BY fullName'
        },
        {
            title: 'Tài khoản hệ thống',
            desc: 'SELECT * FROM UserAccount',
            sql: 'SELECT accountId, username, createdAt, isActive FROM UserAccount ORDER BY createdAt DESC'
        },
        {
            title: 'Vai trò & Quyền hạn',
            desc: 'SELECT * FROM Role',
            sql: 'SELECT * FROM Role ORDER BY roleName'
        }
    ],
    clinical: [
        {
            title: 'Lượt khám gần đây',
            desc: 'SELECT TOP 20 * FROM MedicalVisit',
            sql: 'SELECT TOP 20 * FROM MedicalVisit ORDER BY startTime DESC'
        },
        {
            title: 'Sinh hiệu bệnh nhân',
            desc: 'SELECT TOP 20 * FROM VitalSign',
            sql: 'SELECT TOP 20 * FROM VitalSign'
        },
        {
            title: 'Chẩn đoán',
            desc: 'SELECT TOP 20 * FROM Diagnosis',
            sql: 'SELECT TOP 20 * FROM Diagnosis ORDER BY diagnosedDate DESC'
        },
        {
            title: 'Dịch vụ kỹ thuật',
            desc: 'SELECT * FROM TechnicalService',
            sql: 'SELECT * FROM TechnicalService ORDER BY serviceName'
        },
        {
            title: 'Phiếu chỉ định xét nghiệm',
            desc: 'SELECT TOP 20 * FROM ServiceOrder',
            sql: 'SELECT TOP 20 * FROM ServiceOrder ORDER BY orderTime DESC'
        },
        {
            title: 'Kết quả xét nghiệm',
            desc: 'SELECT TOP 30 * FROM LabResult',
            sql: 'SELECT TOP 30 * FROM LabResult ORDER BY resultTime DESC'
        }
    ],
    pharmacy: [
        {
            title: 'Danh mục Thuốc',
            desc: 'SELECT TOP 20 * FROM Medicine',
            sql: 'SELECT TOP 20 * FROM Medicine ORDER BY medicineName'
        },
        {
            title: 'Danh sách Kho',
            desc: 'SELECT * FROM Warehouse',
            sql: 'SELECT * FROM Warehouse ORDER BY warehouseName'
        },
        {
            title: 'Đơn thuốc',
            desc: 'SELECT TOP 20 * FROM Prescription',
            sql: 'SELECT TOP 20 * FROM Prescription ORDER BY date DESC'
        },
        {
            title: 'Phiếu nhập kho',
            desc: 'SELECT TOP 20 * FROM GoodsReceipt',
            sql: 'SELECT TOP 20 * FROM GoodsReceipt ORDER BY date DESC'
        },
        {
            title: 'Phiếu xuất kho',
            desc: 'SELECT TOP 20 * FROM GoodsIssue',
            sql: 'SELECT TOP 20 * FROM GoodsIssue ORDER BY date DESC'
        }
    ],
    finance: [
        {
            title: 'Hóa đơn thanh toán',
            desc: 'SELECT TOP 20 * FROM Invoice',
            sql: 'SELECT TOP 20 * FROM Invoice ORDER BY createdDate DESC'
        },
        {
            title: 'Hóa đơn chưa thanh toán',
            desc: 'SELECT ... WHERE status = \'Chưa thu tiền\'',
            sql: "SELECT TOP 20 * FROM Invoice WHERE status = N'Chưa thu tiền' ORDER BY createdDate DESC"
        },
        {
            title: 'Doanh thu theo phương thức',
            desc: 'GROUP BY paymentMethod',
            sql: 'SELECT paymentMethod, COUNT(*) AS soHoaDon, SUM(finalAmount) AS tongThu\nFROM Invoice\nWHERE status = N\'Đã thanh toán\'\nGROUP BY paymentMethod\nORDER BY tongThu DESC'
        }
    ],
    joins: [
        {
            title: 'Nhân viên & Khoa',
            desc: 'Staff JOIN Department',
            sql: 'SELECT TOP 20\n    s.staffId, s.fullName, s.specialty, s.gender,\n    d.deptName, d.deptType\nFROM Staff s\nJOIN Department d ON s.deptId = d.deptId\nORDER BY d.deptName, s.fullName'
        },
        {
            title: 'Bệnh nhân & Lượt khám',
            desc: 'Patient JOIN MedicalVisit',
            sql: 'SELECT TOP 20\n    p.patientId, p.fullName, p.gender,\n    mv.visitId, mv.startTime, mv.status, mv.symptoms\nFROM Patient p\nJOIN MedicalVisit mv ON p.patientId = mv.patientId\nORDER BY mv.startTime DESC'
        },
        {
            title: 'Lượt khám & Chẩn đoán',
            desc: 'MedicalVisit JOIN Diagnosis',
            sql: 'SELECT TOP 20\n    mv.visitId, mv.startTime, mv.status,\n    dg.diagType, dg.diagnosedDate, dg.notes\nFROM MedicalVisit mv\nJOIN Diagnosis dg ON mv.visitId = dg.visitId\nORDER BY dg.diagnosedDate DESC'
        },
        {
            title: 'Phiếu chỉ định & Kết quả',
            desc: 'ServiceOrder JOIN LabResult',
            sql: 'SELECT TOP 20\n    so.orderId, so.orderTime, so.status AS orderStatus,\n    ts.serviceName,\n    lr.indexName, lr.value, lr.unit, lr.referenceRange\nFROM ServiceOrder so\nJOIN TechnicalService ts ON so.serviceCode = ts.serviceCode\nJOIN LabResult lr ON so.orderId = lr.orderId\nORDER BY so.orderTime DESC'
        },
        {
            title: 'Đơn thuốc & Chi tiết thuốc',
            desc: 'Prescription JOIN Medicine',
            sql: 'SELECT TOP 20\n    pr.prescriptionId, pr.date, pr.status AS prescStatus,\n    m.medicineName, m.activeIngredient, m.unit\nFROM Prescription pr\nJOIN PrescriptionDetail pd ON pr.prescriptionId = pd.prescriptionId\nJOIN Medicine m ON pd.medicineId = m.medicineId\nORDER BY pr.date DESC'
        },
        {
            title: 'Hóa đơn & Bệnh nhân',
            desc: 'Invoice JOIN Patient via MedicalVisit',
            sql: 'SELECT TOP 20\n    inv.invoiceId, inv.createdDate, inv.paymentMethod,\n    inv.totalAmount, inv.insuranceAmount, inv.finalAmount, inv.status,\n    p.fullName AS benhNhan\nFROM Invoice inv\nJOIN MedicalVisit mv ON inv.visitId = mv.visitId\nJOIN Patient p ON mv.patientId = p.patientId\nORDER BY inv.createdDate DESC'
        }
    ]
};

// ===== Configuration =====
const CONFIG = {
    // URL FastAPI backend (chạy qua Docker: http://localhost:8000)
    API_URL: 'http://localhost:8000/api/query',
    
    // Timeout cho request (ms)
    REQUEST_TIMEOUT: 30000,
    
    // Số dòng tối đa hiển thị cảnh báo
    MAX_ROWS_WARNING: 1000
};

// ===== DOM Elements =====
const elements = {
    sqlQuery: document.getElementById('sqlQuery'),
    executeBtn: document.getElementById('executeBtn'),
    clearBtn: document.getElementById('clearBtn'),
    resultsContainer: document.getElementById('resultsContainer'),
    loadingIndicator: document.getElementById('loadingIndicator'),
    errorMessage: document.getElementById('errorMessage'),
    resultCount: document.getElementById('resultCount')
};

// ===== Event Listeners =====
document.addEventListener('DOMContentLoaded', () => {
    // Execute button click
    elements.executeBtn.addEventListener('click', handleExecuteQuery);
    
    // Clear button click
    elements.clearBtn.addEventListener('click', handleClearQuery);
    
    // Enter key trong textarea (Ctrl+Enter để execute)
    elements.sqlQuery.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.key === 'Enter') {
            e.preventDefault();
            handleExecuteQuery();
        }
    });

    // Sample queries: render default tab
    renderSampleQueries('basic');

    // Tab switching
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderSampleQueries(btn.dataset.tab);
        });
    });
    
    console.log('SQL Query Executor initialized');
});

// ===== Sample Queries Functions =====

/**
 * Render sample query cards vào grid
 * @param {string} tab - Key trong SAMPLE_QUERIES
 */
function renderSampleQueries(tab) {
    const grid = document.getElementById('samplesGrid');
    const queries = SAMPLE_QUERIES[tab] || [];
    
    grid.innerHTML = queries.map((q, i) => `
        <button class="sample-card" onclick="loadSample('${tab}', ${i})">
            <span class="sample-card-title">${escapeHtml(q.title)}</span>
            <span class="sample-card-desc">${escapeHtml(q.desc)}</span>
        </button>
    `).join('');
}

/**
 * Tải câu lệnh mẫu vào textarea
 * @param {string} tab
 * @param {number} index
 */
function loadSample(tab, index) {
    const q = SAMPLE_QUERIES[tab]?.[index];
    if (!q) return;
    elements.sqlQuery.value = q.sql;
    elements.sqlQuery.focus();
    hideError();
    // Scroll đến textarea
    elements.sqlQuery.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

// ===== Main Functions =====

/**
 * Xử lý khi người dùng nhấn Execute
 */
async function handleExecuteQuery() {
    try {
        // Lấy giá trị SQL từ textarea
        const sqlQuery = elements.sqlQuery.value.trim();
        
        // Validate input
        const validationError = validateQuery(sqlQuery);
        if (validationError) {
            showError(validationError);
            return;
        }
        
        // Hiển thị loading state
        showLoading(true);
        hideError();
        
        // Gửi request đến backend
        const result = await executeQuery(sqlQuery);
        
        // Hiển thị kết quả
        displayResults(result);
        
    } catch (error) {
        showError(error.message || 'Đã xảy ra lỗi không xác định');
    } finally {
        showLoading(false);
    }
}

/**
 * Xử lý khi người dùng nhấn Clear
 */
function handleClearQuery() {
    elements.sqlQuery.value = '';
    elements.resultsContainer.innerHTML = `
        <div class="empty-state">
            <p>Kết quả sẽ hiển thị ở đây sau khi bạn thực thi câu lệnh SQL</p>
        </div>
    `;
    elements.resultCount.textContent = '';
    hideError();
    elements.sqlQuery.focus();
}

// ===== Validation Functions =====

/**
 * Validate câu lệnh SQL (Basic validation only - Backend handles security checks)
 * @param {string} query - Câu lệnh SQL cần validate
 * @returns {string|null} - Trả về thông báo lỗi hoặc null nếu hợp lệ
 */
function validateQuery(query) {
    // Kiểm tra rỗng
    if (!query) {
        return 'Vui lòng nhập câu lệnh SQL';
    }

    // Kiểm tra độ dài tối thiểu
    if (query.length < 6) {
        return 'Câu lệnh SQL quá ngắn';
    }

    // Loại bỏ comments để tránh bị bypass  /* ... */  và  -- ...
    const stripped = query
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/--[^\n]*/g, '')
        .trim();

    // Lấy từ đầu tiên
    const firstWord = (stripped.split(/\s+/)[0] || '').toUpperCase();

    if (firstWord !== 'SELECT') {
        return `Chỉ cho phép câu lệnh SELECT.\n"${firstWord}" không được phép thực thi.`;
    }

    return null; // Validation passed
}

// ===== API Functions =====

/**
 * Gửi request đến Backend API để thực thi SQL
 * @param {string} sqlQuery - Câu lệnh SQL cần thực thi
 * @returns {Promise<Object>} - Promise chứa kết quả từ backend
 */
async function executeQuery(sqlQuery) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), CONFIG.REQUEST_TIMEOUT);
    
    try {
        const response = await fetch(CONFIG.API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ 
                query: sqlQuery 
            }),
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        // Parse JSON response
        const data = await response.json();
        
        // Kiểm tra HTTP status
        if (!response.ok) {
            // Backend trả về lỗi
            throw new Error(data.error || data.message || `HTTP Error: ${response.status}`);
        }
        
        // Kiểm tra cấu trúc response
        if (!data || typeof data !== 'object') {
            throw new Error('Response không hợp lệ từ server');
        }
        
        return data;
        
    } catch (error) {
        clearTimeout(timeoutId);
        
        // Xử lý các loại lỗi khác nhau
        if (error.name === 'AbortError') {
            throw new Error(`Request timeout sau ${CONFIG.REQUEST_TIMEOUT / 1000} giây. Vui lòng thử lại.`);
        }
        
        if (error.message.includes('Failed to fetch')) {
            throw new Error('Không thể kết nối đến Backend API. Vui lòng kiểm tra:\n• Backend server đã chạy chưa?\n• URL API có đúng không? (Hiện tại: ' + CONFIG.API_URL + ')');
        }
        
        throw error;
    }
}

// ===== Display Functions =====

/**
 * Hiển thị kết quả truy vấn dưới dạng bảng HTML
 * @param {Object} result - Kết quả từ backend
 */
function displayResults(result) {
    // Kiểm tra cấu trúc dữ liệu
    if (!result.data || !Array.isArray(result.data)) {
        showError('Cấu trúc dữ liệu không hợp lệ từ server');
        return;
    }
    
    const data = result.data;
    
    // Trường hợp không có dữ liệu
    if (data.length === 0) {
        elements.resultsContainer.innerHTML = `
            <div class="empty-state">
                <p>Truy vấn thành công nhưng không có dữ liệu</p>
                <p style="font-size: 0.9rem; margin-top: 8px; color: #64748b;">Query trả về 0 dòng</p>
            </div>
        `;
        elements.resultCount.textContent = '0 rows';
        return;
    }
    
    // Cảnh báo nếu có quá nhiều dòng
    if (data.length > CONFIG.MAX_ROWS_WARNING) {
        console.warn(`Query trả về ${data.length} dòng, có thể ảnh hưởng hiệu suất hiển thị`);
    }
    
    // Lấy danh sách columns từ object đầu tiên
    const columns = Object.keys(data[0]);
    
    // Tạo bảng HTML
    const table = createTable(columns, data);
    
    // Hiển thị bảng
    elements.resultsContainer.innerHTML = '';
    elements.resultsContainer.appendChild(table);
    
    // Hiển thị số lượng rows
    elements.resultCount.textContent = `${data.length} row${data.length !== 1 ? 's' : ''}`;
    
    // Add animation
    elements.resultsContainer.classList.add('fade-in');
    setTimeout(() => {
        elements.resultsContainer.classList.remove('fade-in');
    }, 300);
}

/**
 * Tạo bảng HTML từ dữ liệu
 * @param {Array<string>} columns - Danh sách tên cột
 * @param {Array<Object>} data - Dữ liệu dạng array of objects
 * @returns {HTMLTableElement} - Table element
 */
function createTable(columns, data) {
    const table = document.createElement('table');
    table.className = 'results-table';
    
    // Tạo thead
    const thead = document.createElement('thead');
    const headerRow = document.createElement('tr');
    
    columns.forEach(column => {
        const th = document.createElement('th');
        th.textContent = column;
        th.title = column; // Tooltip cho column name dài
        headerRow.appendChild(th);
    });
    
    thead.appendChild(headerRow);
    table.appendChild(thead);
    
    // Tạo tbody
    const tbody = document.createElement('tbody');
    
    data.forEach(row => {
        const tr = document.createElement('tr');
        
        columns.forEach(column => {
            const td = document.createElement('td');
            const value = row[column];
            
            // Xử lý các giá trị đặc biệt
            if (value === null || value === undefined) {
                td.innerHTML = '<span class="null-value">NULL</span>';
            } else if (typeof value === 'boolean') {
                td.textContent = value ? 'TRUE' : 'FALSE';
            } else if (typeof value === 'object') {
                // Nếu là object hoặc array, chuyển thành JSON string
                td.textContent = JSON.stringify(value);
            } else {
                td.textContent = String(value);
            }
            
            tr.appendChild(td);
        });
        
        tbody.appendChild(tr);
    });
    
    table.appendChild(tbody);
    
    return table;
}

/**
 * Hiển thị/ẩn loading indicator
 * @param {boolean} show - true để hiển thị, false để ẩn
 */
function showLoading(show) {
    elements.loadingIndicator.style.display = show ? 'block' : 'none';
    elements.executeBtn.disabled = show;
    
    if (show) {
        // Xóa kết quả cũ khi bắt đầu loading
        elements.resultsContainer.innerHTML = '';
        elements.resultCount.textContent = '';
    }
}

/**
 * Hiển thị thông báo lỗi
 * @param {string} message - Nội dung lỗi
 */
function showError(message) {
    elements.errorMessage.style.display = 'block';
    elements.errorMessage.innerHTML = `
        <div style="white-space: pre-line;">${escapeHtml(message)}</div>
    `;
    
    // Scroll đến error message
    elements.errorMessage.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

/**
 * Ẩn thông báo lỗi
 */
function hideError() {
    elements.errorMessage.style.display = 'none';
    elements.errorMessage.innerHTML = '';
}

// ===== Utility Functions =====

/**
 * Escape HTML để tránh XSS
 * @param {string} text - Text cần escape
 * @returns {string} - Text đã escape
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Log thông tin cho debugging
 * @param {string} message - Message
 * @param {*} data - Dữ liệu kèm theo
 */
function log(message, data) {
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        console.log(`[SQL Executor] ${message}`, data || '');
    }
}

// ===== Export cho testing (optional) =====
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        validateQuery,
        CONFIG
    };
}
