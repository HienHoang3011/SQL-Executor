/**
 * SQL Query Executor - Frontend Application
 * Xử lý giao diện và giao tiếp với Backend API
 */

// ===== Configuration =====
const CONFIG = {
    // Cấu hình URL của Backend API
    // Thay đổi URL này theo đúng địa chỉ backend của bạn
    API_URL: 'http://localhost:3000/api/query',
    
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
    
    console.log('SQL Query Executor initialized');
});

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
 * Validate câu lệnh SQL
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
    
    // Chỉ cho phép SELECT (không phân biệt hoa thường)
    const trimmedQuery = query.trim().toUpperCase();
    if (!trimmedQuery.startsWith('SELECT')) {
        return 'Chỉ cho phép thực thi câu lệnh SELECT. Các câu lệnh INSERT, UPDATE, DELETE, DROP không được phép.';
    }
    
    // Kiểm tra các từ khóa nguy hiểm (double check)
    const dangerousKeywords = ['DROP', 'DELETE', 'INSERT', 'UPDATE', 'TRUNCATE', 'ALTER', 'CREATE', 'EXEC', 'EXECUTE'];
    for (const keyword of dangerousKeywords) {
        const regex = new RegExp(`\\b${keyword}\\b`, 'i');
        if (regex.test(query)) {
            return `Phát hiện từ khóa không được phép: ${keyword}. Chỉ cho phép câu lệnh SELECT.`;
        }
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
