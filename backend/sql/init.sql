-- ============================================================
-- Hospital Integrated DB - Initialization Script
-- SQL Server (T-SQL)
-- ============================================================

-- 1.1. Create Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Hospital_Integrated_DB')
BEGIN
    CREATE DATABASE Hospital_Integrated_DB;
END
GO

USE Hospital_Integrated_DB;
GO

-- ============================================================
-- 1.2. Subsystem 1: Administration & Master Data
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Department')
CREATE TABLE Department (
    deptId   VARCHAR(20)    PRIMARY KEY,
    deptName NVARCHAR(255)  NOT NULL,
    deptType NVARCHAR(50),
    location NVARCHAR(255),
    hotline  VARCHAR(20)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Staff')
CREATE TABLE Staff (
    staffId   VARCHAR(20)   PRIMARY KEY,
    deptId    VARCHAR(20)   NOT NULL,
    fullName  NVARCHAR(255) NOT NULL,
    specialty NVARCHAR(255),
    gender    VARCHAR(10),
    dob       DATE,
    phone     VARCHAR(20)   NOT NULL UNIQUE,
    email     VARCHAR(100)  UNIQUE,
    CONSTRAINT FK_Staff_Dept   FOREIGN KEY (deptId) REFERENCES Department(deptId),
    CONSTRAINT CHK_StaffGender CHECK (gender IN ('MALE', 'FEMALE', 'OTHER'))
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Role')
CREATE TABLE Role (
    roleId      VARCHAR(20)   PRIMARY KEY,
    roleName    NVARCHAR(100) NOT NULL UNIQUE,
    description NVARCHAR(500)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserAccount')
CREATE TABLE UserAccount (
    accountId VARCHAR(20)  PRIMARY KEY,
    staffId   VARCHAR(20)  NOT NULL,
    roleId    VARCHAR(20)  NOT NULL,
    username  VARCHAR(50)  NOT NULL UNIQUE,
    password  VARCHAR(255) NOT NULL,
    createdAt DATETIME     DEFAULT GETDATE(),
    isActive  BIT          DEFAULT 1,
    CONSTRAINT FK_User_Staff FOREIGN KEY (staffId) REFERENCES Staff(staffId),
    CONSTRAINT FK_User_Role  FOREIGN KEY (roleId)  REFERENCES Role(roleId)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Permission')
CREATE TABLE Permission (
    permissionId   VARCHAR(20)   PRIMARY KEY,
    permissionName NVARCHAR(100) NOT NULL,
    moduleName     NVARCHAR(100)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolePermission')
CREATE TABLE RolePermission (
    roleId       VARCHAR(20) NOT NULL,
    permissionId VARCHAR(20) NOT NULL,
    PRIMARY KEY (roleId, permissionId),
    CONSTRAINT FK_RP_Role FOREIGN KEY (roleId)       REFERENCES Role(roleId)       ON DELETE CASCADE,
    CONSTRAINT FK_RP_Perm FOREIGN KEY (permissionId) REFERENCES Permission(permissionId) ON DELETE CASCADE
);
GO

-- ============================================================
-- 1.3. Subsystem 2: Clinical Examination (EMR)
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Patient')
CREATE TABLE Patient (
    patientId        VARCHAR(20)   PRIMARY KEY,
    fullName         NVARCHAR(255) NOT NULL,
    phone            VARCHAR(20),
    insuranceNo      VARCHAR(50)   UNIQUE,
    gender           VARCHAR(10),
    dob              DATE          NOT NULL,
    address          NVARCHAR(500),
    emergencyContact VARCHAR(20),
    CONSTRAINT CHK_PatientGender CHECK (gender IN ('MALE', 'FEMALE', 'OTHER'))
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MedicalVisit')
CREATE TABLE MedicalVisit (
    visitId         VARCHAR(20)  PRIMARY KEY,
    patientId       VARCHAR(20)  NOT NULL,
    doctorAccountId VARCHAR(20)  NOT NULL,
    deptId          VARCHAR(20)  NOT NULL,
    startTime       DATETIME     NOT NULL DEFAULT GETDATE(),
    endTime         DATETIME,
    symptoms        NVARCHAR(MAX),
    notes           NVARCHAR(MAX),
    status          VARCHAR(20)  DEFAULT 'PENDING',
    CONSTRAINT FK_Visit_Patient FOREIGN KEY (patientId)       REFERENCES Patient(patientId)     ON DELETE NO ACTION,
    CONSTRAINT FK_Visit_Doctor  FOREIGN KEY (doctorAccountId) REFERENCES UserAccount(accountId) ON DELETE NO ACTION,
    CONSTRAINT FK_Visit_Dept    FOREIGN KEY (deptId)          REFERENCES Department(deptId),
    CONSTRAINT CHK_VisitStatus  CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'))
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VitalSign')
CREATE TABLE VitalSign (
    vitalId         VARCHAR(20)   PRIMARY KEY,
    visitId         VARCHAR(20)   NOT NULL,
    bloodPressure   VARCHAR(20),
    heartRate       INT,
    temperature     DECIMAL(4,2),
    respiratoryRate INT,
    weight          DECIMAL(5,2),
    height          DECIMAL(5,2),
    CONSTRAINT FK_Vital_Visit FOREIGN KEY (visitId) REFERENCES MedicalVisit(visitId) ON DELETE CASCADE,
    CONSTRAINT CHK_HeartRate  CHECK (heartRate > 0),
    CONSTRAINT CHK_Temp       CHECK (temperature BETWEEN 20 AND 50)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Icd10Dictionary')
CREATE TABLE Icd10Dictionary (
    icd10Code   VARCHAR(20)   PRIMARY KEY,
    diseaseName NVARCHAR(500) NOT NULL UNIQUE
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Diagnosis')
CREATE TABLE Diagnosis (
    diagnosisId   VARCHAR(20)  PRIMARY KEY,
    visitId       VARCHAR(20)  NOT NULL,
    icd10Code     VARCHAR(20)  NOT NULL,
    diagType      VARCHAR(20),
    diagnosedDate DATETIME     DEFAULT GETDATE(),
    notes         NVARCHAR(MAX),
    CONSTRAINT FK_Diag_Visit FOREIGN KEY (visitId)   REFERENCES MedicalVisit(visitId)    ON DELETE CASCADE,
    CONSTRAINT FK_Diag_ICD   FOREIGN KEY (icd10Code) REFERENCES Icd10Dictionary(icd10Code),
    CONSTRAINT CHK_DiagType  CHECK (diagType IN ('PRIMARY', 'SECONDARY'))
);
GO

-- ============================================================
-- 1.4. Subsystem 3: Paraclinical (LIS/RIS)
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TechnicalService')
CREATE TABLE TechnicalService (
    serviceCode  VARCHAR(20)   PRIMARY KEY,
    serviceName  NVARCHAR(255) NOT NULL,
    description  NVARCHAR(MAX),
    durationEst  INT,
    unitPrice    DECIMAL(18,2) NOT NULL,
    CONSTRAINT CHK_ServicePrice CHECK (unitPrice >= 0)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ServiceOrder')
CREATE TABLE ServiceOrder (
    orderId     VARCHAR(20)  PRIMARY KEY,
    visitId     VARCHAR(20)  NOT NULL,
    serviceCode VARCHAR(20)  NOT NULL,
    orderTime   DATETIME     DEFAULT GETDATE(),
    doctorNotes NVARCHAR(MAX),
    status      VARCHAR(20)  DEFAULT 'PENDING',
    CONSTRAINT FK_Order_Visit    FOREIGN KEY (visitId)     REFERENCES MedicalVisit(visitId)      ON DELETE NO ACTION,
    CONSTRAINT FK_Order_Service  FOREIGN KEY (serviceCode) REFERENCES TechnicalService(serviceCode) ON DELETE NO ACTION
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LabResult')
CREATE TABLE LabResult (
    resultId              VARCHAR(20)  PRIMARY KEY,
    orderId               VARCHAR(20)  NOT NULL,
    performedByAccountId  VARCHAR(20)  NOT NULL,
    approvedByAccountId   VARCHAR(20),
    indexName             NVARCHAR(100),
    value                 NVARCHAR(100),
    unit                  NVARCHAR(50),
    referenceRange        NVARCHAR(100),
    resultTime            DATETIME     DEFAULT GETDATE(),
    CONSTRAINT FK_Result_Order    FOREIGN KEY (orderId)              REFERENCES ServiceOrder(orderId),
    CONSTRAINT FK_Result_Performer FOREIGN KEY (performedByAccountId) REFERENCES UserAccount(accountId),
    CONSTRAINT FK_Result_Approver  FOREIGN KEY (approvedByAccountId)  REFERENCES UserAccount(accountId)
);
GO

-- ============================================================
-- 1.5. Subsystem 4: Pharmacy Warehouse
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Medicine')
CREATE TABLE Medicine (
    medicineId      VARCHAR(20)   PRIMARY KEY,
    medicineName    NVARCHAR(255) NOT NULL,
    activeIngredient NVARCHAR(255),
    unit            NVARCHAR(50),
    manufacturer    NVARCHAR(255),
    sellPrice       DECIMAL(18,2) NOT NULL,
    minStock        INT           DEFAULT 0,
    CONSTRAINT CHK_MedPrice CHECK (sellPrice >= 0)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Warehouse')
CREATE TABLE Warehouse (
    warehouseId      VARCHAR(20)   PRIMARY KEY,
    managerAccountId VARCHAR(20)   NOT NULL,
    warehouseName    NVARCHAR(255) NOT NULL,
    location         NVARCHAR(255),
    CONSTRAINT FK_Ware_Manager FOREIGN KEY (managerAccountId) REFERENCES UserAccount(accountId)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Prescription')
CREATE TABLE Prescription (
    prescriptionId VARCHAR(20)  PRIMARY KEY,
    visitId        VARCHAR(20)  NOT NULL,
    doctorAccountId VARCHAR(20) NOT NULL,
    prescribedDate DATETIME     DEFAULT GETDATE(),
    doctorNotes    NVARCHAR(MAX),
    status         VARCHAR(20)  DEFAULT 'PENDING',
    CONSTRAINT FK_Presc_Visit   FOREIGN KEY (visitId)         REFERENCES MedicalVisit(visitId),
    CONSTRAINT FK_Presc_Doctor  FOREIGN KEY (doctorAccountId) REFERENCES UserAccount(accountId)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PrescriptionDetail')
CREATE TABLE PrescriptionDetail (
    prescriptionDetailId VARCHAR(20)  PRIMARY KEY,
    prescriptionId       VARCHAR(20)  NOT NULL,
    medicineId           VARCHAR(20)  NOT NULL,
    dosage               NVARCHAR(100),
    quantity             INT          NOT NULL,
    durationDays         INT,
    CONSTRAINT FK_PD_Presc FOREIGN KEY (prescriptionId) REFERENCES Prescription(prescriptionId) ON DELETE CASCADE,
    CONSTRAINT FK_PD_Med   FOREIGN KEY (medicineId)     REFERENCES Medicine(medicineId)          ON DELETE NO ACTION,
    CONSTRAINT CHK_PDQty   CHECK (quantity > 0)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GoodsReceipt')
CREATE TABLE GoodsReceipt (
    receiptId    VARCHAR(20)   PRIMARY KEY,
    warehouseId  VARCHAR(20)   NOT NULL,
    receiptDate  DATETIME      DEFAULT GETDATE(),
    supplierName NVARCHAR(255),
    totalValue   DECIMAL(18,2),
    status       VARCHAR(20),
    CONSTRAINT FK_Receipt_Ware FOREIGN KEY (warehouseId) REFERENCES Warehouse(warehouseId),
    CONSTRAINT CHK_ReceiptVal  CHECK (totalValue >= 0)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReceiptDetail')
CREATE TABLE ReceiptDetail (
    receiptDetailId VARCHAR(20)   PRIMARY KEY,
    receiptId       VARCHAR(20)   NOT NULL,
    medicineId      VARCHAR(20)   NOT NULL,
    batchNo         VARCHAR(50),
    expiryDate      DATE,
    quantity        INT           NOT NULL,
    importPrice     DECIMAL(18,2),
    CONSTRAINT FK_RD_Receipt FOREIGN KEY (receiptId)   REFERENCES GoodsReceipt(receiptId) ON DELETE CASCADE,
    CONSTRAINT FK_RD_Med     FOREIGN KEY (medicineId)  REFERENCES Medicine(medicineId),
    CONSTRAINT CHK_RDQty     CHECK (quantity > 0),
    CONSTRAINT CHK_RDPrice   CHECK (importPrice >= 0)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GoodsIssue')
CREATE TABLE GoodsIssue (
    issueId        VARCHAR(20)  PRIMARY KEY,
    prescriptionId VARCHAR(20),
    warehouseId    VARCHAR(20)  NOT NULL,
    issueDate      DATETIME     DEFAULT GETDATE(),
    reason         NVARCHAR(255),
    status       VARCHAR(20),
    CONSTRAINT FK_Issue_Presc FOREIGN KEY (prescriptionId) REFERENCES Prescription(prescriptionId),
    CONSTRAINT FK_Issue_Ware  FOREIGN KEY (warehouseId)    REFERENCES Warehouse(warehouseId)
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'IssueDetail')
CREATE TABLE IssueDetail (
    issueDetailId VARCHAR(20) PRIMARY KEY,
    issueId       VARCHAR(20) NOT NULL,
    medicineId    VARCHAR(20) NOT NULL,
    batchNo       VARCHAR(50),
    quantity      INT         NOT NULL,
    CONSTRAINT FK_ID_Issue FOREIGN KEY (issueId)    REFERENCES GoodsIssue(issueId) ON DELETE CASCADE,
    CONSTRAINT FK_ID_Med   FOREIGN KEY (medicineId) REFERENCES Medicine(medicineId),
    CONSTRAINT CHK_IDQty   CHECK (quantity > 0)
);
GO

-- ============================================================
-- 1.6. Subsystem 5: Hospital Billing
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Invoice')
CREATE TABLE Invoice (
    invoiceId       VARCHAR(20)   PRIMARY KEY,
    visitId         VARCHAR(20)   NOT NULL,
    createdDate     DATETIME      DEFAULT GETDATE(),
    paymentMethod   VARCHAR(50),
    totalAmount     DECIMAL(18,2) NOT NULL,
    insuranceAmount DECIMAL(18,2) DEFAULT 0,
    finalAmount     DECIMAL(18,2) NOT NULL,
    status          VARCHAR(20)   DEFAULT 'UNPAID',
    CONSTRAINT FK_Inv_Visit    FOREIGN KEY (visitId)   REFERENCES MedicalVisit(visitId),
    CONSTRAINT CHK_InvTotal    CHECK (totalAmount >= 0),
    CONSTRAINT CHK_InvIns      CHECK (insuranceAmount >= 0),
    CONSTRAINT CHK_InvFinal    CHECK (finalAmount >= 0),
    CONSTRAINT CHK_InvStatus   CHECK (status IN ('UNPAID', 'PAID', 'REFUNDED'))
);
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InvoiceDetail')
CREATE TABLE InvoiceDetail (
    detailId  VARCHAR(20)   PRIMARY KEY,
    invoiceId VARCHAR(20)   NOT NULL,
    itemType  VARCHAR(50)   NOT NULL,
    itemName  NVARCHAR(255) NOT NULL,
    quantity  INT           NOT NULL,
    unitPrice DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_InvDet_Inv    FOREIGN KEY (invoiceId) REFERENCES Invoice(invoiceId) ON DELETE CASCADE,
    CONSTRAINT CHK_InvDetQty    CHECK (quantity > 0),
    CONSTRAINT CHK_InvDetPrice  CHECK (unitPrice >= 0)
);
GO

-- ============================================================
-- 2. DML - Seed Data
-- 2.1. Thêm bản ghi dữ liệu nền (Phòng ban, Nhân sự, Tài khoản, Quyền)
IF NOT EXISTS (SELECT 1 FROM Department)
BEGIN
    INSERT INTO Department (deptId, deptName, deptType, location, hotline) VALUES 
    ('KHOA_KHAM',  N'Khoa Khám Bệnh', N'Lâm sàng', N'Tầng 1 - Tòa A', '1900-0001'),
    ('KHOA_XN',    N'Khoa Xét Nghiệm', N'Cận lâm sàng', N'Tầng 2 - Tòa A', '1900-0002'),
    ('KHOA_DUOC',  N'Khoa Dược', N'Dược', N'Tầng 1 - Tòa B', '1900-0003'),
    ('KHOA_NOI',   N'Khoa Nội Tổng Hợp', N'Lâm sàng', N'Tầng 3 - Tòa A', '1900-0004'),
    ('KHOA_NGOAI', N'Khoa Ngoại', N'Lâm sàng', N'Tầng 4 - Tòa A', '1900-0005'),
    ('KHOA_NHI',   N'Khoa Nhi', N'Lâm sàng', N'Tầng 2 - Tòa B', '1900-0006'),
    ('KHOA_SAN',   N'Khoa Sản', N'Lâm sàng', N'Tầng 5 - Tòa A', '1900-0007'),
    ('KHOA_MAT',   N'Khoa Mắt', N'Lâm sàng', N'Tầng 3 - Tòa B', '1900-0008'),
    ('KHOA_TMH',   N'Khoa Tai Mũi Họng', N'Lâm sàng', N'Tầng 4 - Tòa B', '1900-0009'),
    ('KHOA_RHM',   N'Khoa Răng Hàm Mặt', N'Lâm sàng', N'Tầng 5 - Tòa B', '1900-0010'),
    ('KHOA_DALIEU',N'Khoa Da Liễu', N'Lâm sàng', N'Tầng 6 - Tòa A', '1900-0011'),
    ('KHOA_CC',    N'Khoa Cấp Cứu', N'Lâm sàng', N'Tầng 1 - Tòa C', '1900-0012'),
    ('KHOA_HSTC',  N'Khoa Hồi Sức Tích Cực', N'Lâm sàng', N'Tầng 2 - Tòa C', '1900-0013'),
    ('KHOA_CDHA',  N'Khoa Chẩn Đoán Hình Ảnh', N'Cận lâm sàng', N'Tầng 1 - Tòa D', '1900-0014'),
    ('KHOA_PHCN',  N'Khoa Phục Hồi Chức Năng', N'Lâm sàng', N'Tầng 3 - Tòa C', '1900-0015'),
    ('KHOA_YHCT',  N'Khoa Y Học Cổ Truyền', N'Lâm sàng', N'Tầng 4 - Tòa C', '1900-0016'),
    ('KHOA_GMHS',  N'Khoa Gây Mê Hồi Sức', N'Lâm sàng', N'Tầng 5 - Tòa C', '1900-0017'),
    ('KHOA_KSNK',  N'Khoa Kiểm Soát Nhiễm Khuẩn', N'Hành chính', N'Tầng 6 - Tòa C', '1900-0018'),
    ('KHOA_DD',    N'Khoa Dinh Dưỡng', N'Cận lâm sàng', N'Tầng 2 - Tòa D', '1900-0019'),
    ('KHOA_TH',    N'Khoa Tiêu Hóa', N'Lâm sàng', N'Tầng 7 - Tòa A', '1900-0020');
END
GO

IF NOT EXISTS (SELECT 1 FROM Staff)
BEGIN
    INSERT INTO Staff (staffId, deptId, fullName, specialty, gender, dob, phone, email) VALUES 
    ('NV001', 'KHOA_KHAM', N'Nguyễn Văn A', N'Nội Tổng Quát', 'MALE', '1985-05-10', '0901234561', 'nva@hosp.com'),
    ('NV002', 'KHOA_XN', N'Trần Thị B', N'Huyết Học', 'FEMALE', '1990-08-20', '0901234562', 'ttb@hosp.com'),
    ('NV003', 'KHOA_DUOC', N'Lê Văn C', N'Dược Lâm Sàng', 'MALE', '1988-11-15', '0901234563', 'lvc@hosp.com'),
    ('NV004', 'KHOA_NOI', N'Phạm Thị D', N'Nội Tiêu Hóa', 'FEMALE', '1982-02-28', '0901234564', 'ptd@hosp.com'),
    ('NV005', 'KHOA_NGOAI', N'Hoàng Văn E', N'Ngoại Thần Kinh', 'MALE', '1979-07-11', '0901234565', 'hve@hosp.com'),
    ('NV006', 'KHOA_NHI', N'Vũ Thị F', N'Nhi Khoa', 'FEMALE', '1993-04-05', '0901234566', 'vtf@hosp.com'),
    ('NV007', 'KHOA_SAN', N'Đặng Văn G', N'Sản Khoa', 'MALE', '1980-09-19', '0901234567', 'dvg@hosp.com'),
    ('NV008', 'KHOA_MAT', N'Bùi Thị H', N'Nhãn Khoa', 'FEMALE', '1987-12-25', '0901234568', 'bth@hosp.com'),
    ('NV009', 'KHOA_TMH', N'Đỗ Văn I', N'Tai Mũi Họng', 'MALE', '1991-03-30', '0901234569', 'dvi@hosp.com'),
    ('NV010', 'KHOA_RHM', N'Hồ Thị J', N'Răng Hàm Mặt', 'FEMALE', '1986-06-14', '0901234570', 'htj@hosp.com'),
    ('NV011', 'KHOA_DALIEU', N'Ngô Văn K', N'Da Liễu', 'MALE', '1992-01-08', '0901234571', 'nvk@hosp.com'),
    ('NV012', 'KHOA_CC', N'Dương Thị L', N'Cấp Cứu', 'FEMALE', '1989-10-22', '0901234572', 'dtl@hosp.com'),
    ('NV013', 'KHOA_HSTC', N'Lý Văn M', N'Hồi Sức', 'MALE', '1984-05-05', '0901234573', 'lvm@hosp.com'),
    ('NV014', 'KHOA_CDHA', N'Mai Thị N', N'Chẩn Đoán HA', 'FEMALE', '1994-08-18', '0901234574', 'mtn@hosp.com'),
    ('NV015', 'KHOA_PHCN', N'Trịnh Văn O', N'Vật Lý Trị Liệu', 'MALE', '1981-11-30', '0901234575', 'tvo@hosp.com'),
    ('NV016', 'KHOA_YHCT', N'Đinh Thị P', N'Châm Cứu', 'FEMALE', '1983-04-12', '0901234576', 'dtp@hosp.com'),
    ('NV017', 'KHOA_GMHS', N'Vương Văn Q', N'Gây Mê', 'MALE', '1978-02-14', '0901234577', 'vvq@hosp.com'),
    ('NV018', 'KHOA_KSNK', N'Tạ Thị R', N'Kiểm Soát Khuẩn', 'FEMALE', '1995-09-09', '0901234578', 'ttr@hosp.com'),
    ('NV019', 'KHOA_DD', N'Châu Văn S', N'Dinh Dưỡng', 'MALE', '1988-12-01', '0901234579', 'cvs@hosp.com'),
    ('NV020', 'KHOA_TH', N'Lâm Thị T', N'Nội Soi Tiêu Hóa', 'FEMALE', '1991-07-25', '0901234580', 'ltt@hosp.com');
END
GO

IF NOT EXISTS (SELECT 1 FROM Role)
BEGIN
    INSERT INTO Role (roleId, roleName, description) VALUES 
    ('R01', N'Bác sĩ Khám', N'Khám bệnh'), ('R02', N'Bác sĩ Ngoại', N'Phẫu thuật'),
    ('R03', N'Bác sĩ Nhi', N'Khám nhi'), ('R04', N'Bác sĩ Sản', N'Khám sản'),
    ('R05', N'Bác sĩ Cấp cứu', N'Trực cấp cứu'), ('R06', N'KTV Xét nghiệm', N'Chạy máy XN'),
    ('R07', N'KTV X-Quang', N'Chụp X-Quang'), ('R08', N'KTV Siêu âm', N'Siêu âm'),
    ('R09', N'Dược sĩ kho', N'Quản lý kho'), ('R10', N'Dược sĩ bán', N'Bán thuốc'),
    ('R11', N'Thu ngân 1', N'Thu tiền sảnh'), ('R12', N'Thu ngân 2', N'Thu tiền cấp cứu'),
    ('R13', N'Lễ tân', N'Tiếp đón'), ('R14', N'Điều dưỡng', N'Chăm sóc'),
    ('R15', N'Admin', N'Quản trị IT'), ('R16', N'Bác sĩ YHCT', N'Bác sĩ đông y'),
    ('R17', N'Bác sĩ Gây Mê', N'Gây mê phẫu thuật'), ('R18', N'Chuyên viên KSNK', N'Kiểm soát nhiễm khuẩn'),
    ('R19', N'Chuyên viên DD', N'Lên thực đơn bệnh lý'), ('R20', N'Bác sĩ Nội soi', N'Nội soi tiêu hóa');
END
GO

IF NOT EXISTS (SELECT 1 FROM UserAccount)
BEGIN
    INSERT INTO UserAccount (accountId, staffId, roleId, username, password) VALUES 
    ('A001', 'NV001', 'R01', 'bs_nva', 'pw1'), ('A002', 'NV002', 'R06', 'ktv_ttb', 'pw2'),
    ('A003', 'NV003', 'R09', 'ds_lvc', 'pw3'), ('A004', 'NV004', 'R01', 'bs_ptd', 'pw4'),
    ('A005', 'NV005', 'R02', 'bs_hve', 'pw5'), ('A006', 'NV006', 'R03', 'bs_vtf', 'pw6'),
    ('A007', 'NV007', 'R04', 'bs_dvg', 'pw7'), ('A008', 'NV008', 'R01', 'bs_bth', 'pw8'),
    ('A009', 'NV009', 'R01', 'bs_dvi', 'pw9'), ('A010', 'NV010', 'R01', 'bs_htj', 'pw10'),
    ('A011', 'NV011', 'R01', 'bs_nvk', 'pw11'), ('A012', 'NV012', 'R05', 'bs_dtl', 'pw12'),
    ('A013', 'NV013', 'R05', 'bs_lvm', 'pw13'), ('A014', 'NV014', 'R07', 'ktv_mtn', 'pw14'),
    ('A015', 'NV015', 'R14', 'dd_tvo', 'pw15'), ('A016', 'NV016', 'R16', 'bs_dtp', 'pw16'),
    ('A017', 'NV017', 'R17', 'bs_vvq', 'pw17'), ('A018', 'NV018', 'R18', 'cv_ttr', 'pw18'),
    ('A019', 'NV019', 'R19', 'cv_cvs', 'pw19'), ('A020', 'NV020', 'R20', 'bs_ltt', 'pw20');
END
GO

IF NOT EXISTS (SELECT 1 FROM Permission)
BEGIN
    INSERT INTO Permission (permissionId, permissionName, moduleName) VALUES 
    ('P01', N'Toàn quyền xuất nhập kho', N'Kho Dược'), ('P02', N'Chỉnh sửa kết quả máy XN', N'Cận Lâm Sàng'),
    ('P03', N'Xem hóa đơn', N'Viện phí'), ('P04', N'Thanh toán', N'Viện phí'),
    ('P05', N'Quản lý kho', N'Kho Dược'), ('P06', N'Tạo y lệnh', N'Cận Lâm Sàng'),
    ('P07', N'Xem bệnh án', N'EMR'), ('P08', N'Sửa bệnh án', N'EMR'),
    ('P09', N'Quản lý nhân sự', N'Quản trị'), ('P10', N'Phân quyền', N'Quản trị'),
    ('P11', N'Nhập kho', N'Kho Dược'), ('P12', N'Xuất kho', N'Kho Dược'),
    ('P13', N'Hủy hóa đơn', N'Viện phí'), ('P14', N'Sửa sinh hiệu', N'EMR'),
    ('P15', N'Xem báo cáo', N'Báo cáo'), ('P16', N'Xuất Excel', N'Báo cáo'),
    ('P17', N'Quản lý khoa', N'Quản trị'), ('P18', N'Duyệt kết quả', N'Cận Lâm Sàng'),
    ('P19', N'Sửa danh mục thuốc', N'Kho Dược'), ('P20', N'Quản lý tài khoản', N'Quản trị');
END
GO

IF NOT EXISTS (SELECT 1 FROM RolePermission)
BEGIN
    INSERT INTO RolePermission (roleId, permissionId) VALUES 
    ('R01', 'P06'), ('R01', 'P07'), ('R01', 'P08'), ('R06', 'P02'), 
    ('R06', 'P18'), ('R09', 'P01'), ('R09', 'P05'), ('R09', 'P11'), 
    ('R09', 'P12'), ('R09', 'P19'), ('R11', 'P03'), ('R11', 'P04'), 
    ('R11', 'P13'), ('R15', 'P09'), ('R15', 'P10'), ('R15', 'P15'), 
    ('R15', 'P16'), ('R15', 'P17'), ('R15', 'P20'), ('R14', 'P14');
END
GO

-- 2.2. Thêm bản ghi quy trình Khám bệnh
IF NOT EXISTS (SELECT 1 FROM Patient)
BEGIN
    INSERT INTO Patient (patientId, fullName, phone, insuranceNo, gender, dob, address, emergencyContact) VALUES 
    ('BN001', N'Hoàng Trọng 1', '0987654301', 'BHYT001', 'MALE', '1995-02-28', N'Hà Nội', '0900111221'),
    ('BN002', N'Hoàng Trọng 2', '0987654302', 'BHYT002', 'FEMALE', '1996-03-15', N'Hà Nội', '0900111222'),
    ('BN003', N'Hoàng Trọng 3', '0987654303', 'BHYT003', 'MALE', '1997-04-20', N'Hà Nội', '0900111223'),
    ('BN004', N'Hoàng Trọng 4', '0987654304', 'BHYT004', 'FEMALE', '1998-05-10', N'Hà Nội', '0900111224'),
    ('BN005', N'Hoàng Trọng 5', '0987654305', 'BHYT005', 'MALE', '1999-06-05', N'Hà Nội', '0900111225'),
    ('BN006', N'Hoàng Trọng 6', '0987654306', 'BHYT006', 'FEMALE', '2000-07-12', N'Hà Nội', '0900111226'),
    ('BN007', N'Hoàng Trọng 7', '0987654307', 'BHYT007', 'MALE', '2001-08-18', N'Hà Nội', '0900111227'),
    ('BN008', N'Hoàng Trọng 8', '0987654308', 'BHYT008', 'FEMALE', '2002-09-22', N'Hà Nội', '0900111228'),
    ('BN009', N'Hoàng Trọng 9', '0987654309', 'BHYT009', 'MALE', '2003-10-30', N'Hà Nội', '0900111229'),
    ('BN010', N'Hoàng Trọng 10', '0987654310', 'BHYT010', 'FEMALE', '2004-11-05', N'Hà Nội', '0900111230'),
    ('BN011', N'Hoàng Trọng 11', '0987654311', 'BHYT011', 'MALE', '1985-12-11', N'Hà Nội', '0900111231'),
    ('BN012', N'Hoàng Trọng 12', '0987654312', 'BHYT012', 'FEMALE', '1986-01-14', N'Hà Nội', '0900111232'),
    ('BN013', N'Hoàng Trọng 13', '0987654313', 'BHYT013', 'MALE', '1987-02-19', N'Hà Nội', '0900111233'),
    ('BN014', N'Hoàng Trọng 14', '0987654314', 'BHYT014', 'FEMALE', '1988-03-25', N'Hà Nội', '0900111234'),
    ('BN015', N'Hoàng Trọng 15', '0987654315', 'BHYT015', 'MALE', '1989-04-01', N'Hà Nội', '0900111235'),
    ('BN016', N'Hoàng Trọng 16', '0987654316', 'BHYT016', 'FEMALE', '1990-05-08', N'Hà Nội', '0900111236'),
    ('BN017', N'Hoàng Trọng 17', '0987654317', 'BHYT017', 'MALE', '1991-06-12', N'Hà Nội', '0900111237'),
    ('BN018', N'Hoàng Trọng 18', '0987654318', 'BHYT018', 'FEMALE', '1992-07-16', N'Hà Nội', '0900111238'),
    ('BN019', N'Hoàng Trọng 19', '0987654319', 'BHYT019', 'MALE', '1993-08-21', N'Hà Nội', '0900111239'),
    ('BN020', N'Hoàng Trọng 20', '0987654320', 'BHYT020', 'FEMALE', '1994-09-29', N'Hà Nội', '0900111240');
END
GO

IF NOT EXISTS (SELECT 1 FROM Icd10Dictionary)
BEGIN
    INSERT INTO Icd10Dictionary (icd10Code, diseaseName) VALUES 
    ('J00', N'Viêm mũi họng cấp'), ('E11', N'Tiểu đường type 2'), ('I10', N'Tăng huyết áp'),
    ('K21', N'Trào ngược dạ dày'), ('M54', N'Đau lưng'), ('A09', N'Tiêu chảy'),
    ('J20', N'Viêm phế quản cấp'), ('N20', N'Sỏi thận'), ('H10', N'Viêm kết mạc'),
    ('L50', N'Mề đay'), ('S02', N'Vỡ xương sọ'), ('O20', N'Động thai'),
    ('K02', N'Sâu răng'), ('R50', N'Sốt không rõ nguyên nhân'), ('Z00', N'Khám sức khỏe tổng quát'),
    ('M53', N'Bệnh lý cột sống cổ'), ('Z01', N'Khám trước phẫu thuật'), ('R53', N'Khó chịu và mệt mỏi'),
    ('E46', N'Suy dinh dưỡng thiếu protein-năng lượng'), ('K29', N'Viêm dạ dày và tá tràng');
END
GO

IF NOT EXISTS (SELECT 1 FROM MedicalVisit)
BEGIN
    INSERT INTO MedicalVisit (visitId, patientId, doctorAccountId, deptId, status, symptoms) VALUES 
    ('V001', 'BN001', 'A001', 'KHOA_KHAM', 'COMPLETED', N'Đau đầu'),
    ('V002', 'BN002', 'A004', 'KHOA_NOI', 'COMPLETED', N'Đau bụng'),
    ('V003', 'BN003', 'A005', 'KHOA_NGOAI', 'COMPLETED', N'Gãy tay'),
    ('V004', 'BN004', 'A006', 'KHOA_NHI', 'COMPLETED', N'Sốt cao'),
    ('V005', 'BN005', 'A007', 'KHOA_SAN', 'COMPLETED', N'Khám thai'),
    ('V006', 'BN006', 'A008', 'KHOA_MAT', 'COMPLETED', N'Mờ mắt'),
    ('V007', 'BN007', 'A009', 'KHOA_TMH', 'COMPLETED', N'Đau họng'),
    ('V008', 'BN008', 'A010', 'KHOA_RHM', 'COMPLETED', N'Sâu răng'),
    ('V009', 'BN009', 'A011', 'KHOA_DALIEU', 'COMPLETED', N'Nổi mẩn đỏ'),
    ('V010', 'BN010', 'A012', 'KHOA_CC', 'COMPLETED', N'Khó thở'),
    ('V011', 'BN011', 'A001', 'KHOA_KHAM', 'COMPLETED', N'Chóng mặt'),
    ('V012', 'BN012', 'A004', 'KHOA_NOI', 'COMPLETED', N'Buồn nôn'),
    ('V013', 'BN013', 'A005', 'KHOA_NGOAI', 'COMPLETED', N'Chấn thương'),
    ('V014', 'BN014', 'A006', 'KHOA_NHI', 'COMPLETED', N'Ho khan'),
    ('V015', 'BN015', 'A001', 'KHOA_KHAM', 'PENDING', N'Khám tổng quát'),
    ('V016', 'BN016', 'A016', 'KHOA_YHCT', 'COMPLETED', N'Đau mỏi vai gáy'),
    ('V017', 'BN017', 'A017', 'KHOA_GMHS', 'COMPLETED', N'Tư vấn tiền mê'),
    ('V018', 'BN018', 'A001', 'KHOA_KHAM', 'COMPLETED', N'Mệt mỏi'),
    ('V019', 'BN019', 'A019', 'KHOA_DD', 'COMPLETED', N'Suy nhược cơ thể'),
    ('V020', 'BN020', 'A020', 'KHOA_TH', 'COMPLETED', N'Nội soi kiểm tra'), ('V022', 'BN002', 'A001', 'KHOA_KHAM', 'CANCELLED', N'Bệnh nhân hủy lịch phút chót');
END
GO

IF NOT EXISTS (SELECT 1 FROM VitalSign)
BEGIN
    INSERT INTO VitalSign (vitalId, visitId, bloodPressure, heartRate, temperature, respiratoryRate, weight, height) VALUES 
    ('VS01', 'V001', '120/80', 80, 37.0, 18, 65.0, 1.70), ('VS02', 'V002', '130/85', 85, 37.5, 20, 70.0, 1.65),
    ('VS03', 'V003', '110/70', 90, 36.8, 16, 60.0, 1.58), ('VS04', 'V004', '100/60', 100, 39.2, 24, 25.0, 1.20),
    ('VS05', 'V005', '115/75', 82, 37.1, 18, 55.0, 1.62), ('VS06', 'V006', '125/80', 78, 36.9, 16, 68.0, 1.75),
    ('VS07', 'V007', '120/80', 88, 38.0, 22, 75.0, 1.80), ('VS08', 'V008', '118/78', 80, 37.0, 18, 50.0, 1.55),
    ('VS09', 'V009', '122/82', 84, 37.2, 20, 62.0, 1.68), ('VS10', 'V010', '140/90', 110, 37.4, 26, 80.0, 1.72),
    ('VS11', 'V011', '110/75', 76, 36.8, 16, 58.0, 1.60), ('VS12', 'V012', '125/85', 86, 37.5, 20, 72.0, 1.78),
    ('VS13', 'V013', '130/80', 95, 37.1, 18, 66.0, 1.64), ('VS14', 'V014', '105/65', 92, 38.5, 24, 30.0, 1.30),
    ('VS15', 'V015', '120/80', 75, 36.9, 16, 64.0, 1.70), ('VS16', 'V016', '115/75', 79, 37.0, 18, 59.0, 1.60),
    ('VS17', 'V017', '125/80', 81, 37.1, 18, 71.0, 1.74), ('VS18', 'V018', '110/70', 74, 36.7, 16, 54.0, 1.62),
    ('VS19', 'V019', '100/60', 65, 36.5, 16, 45.0, 1.50), ('VS20', 'V020', '120/80', 82, 37.2, 18, 69.0, 1.66);
END
GO

IF NOT EXISTS (SELECT 1 FROM Diagnosis)
BEGIN
    INSERT INTO Diagnosis (diagnosisId, visitId, icd10Code, diagType) VALUES 
    ('D001', 'V001', 'J00', 'PRIMARY'), ('D002', 'V002', 'K21', 'PRIMARY'),
    ('D003', 'V003', 'S02', 'PRIMARY'), ('D004', 'V004', 'J20', 'PRIMARY'),
    ('D005', 'V005', 'O20', 'PRIMARY'), ('D006', 'V006', 'H10', 'PRIMARY'),
    ('D007', 'V007', 'J00', 'PRIMARY'), ('D008', 'V008', 'K02', 'PRIMARY'),
    ('D009', 'V009', 'L50', 'PRIMARY'), ('D010', 'V010', 'I10', 'PRIMARY'),
    ('D011', 'V011', 'I10', 'PRIMARY'), ('D012', 'V012', 'A09', 'PRIMARY'),
    ('D013', 'V013', 'M54', 'PRIMARY'), ('D014', 'V014', 'J20', 'PRIMARY'),
    ('D015', 'V015', 'Z00', 'PRIMARY'), ('D016', 'V016', 'M53', 'PRIMARY'),
    ('D017', 'V017', 'Z01', 'PRIMARY'), ('D018', 'V018', 'R53', 'PRIMARY'),
    ('D019', 'V019', 'E46', 'PRIMARY'), ('D020', 'V020', 'K29', 'PRIMARY');
END
GO

-- 2.3. Thêm bản ghi Cận lâm sàng và Kho Dược
IF NOT EXISTS (SELECT 1 FROM TechnicalService)
BEGIN
    INSERT INTO TechnicalService (serviceCode, serviceName, description, durationEst, unitPrice) VALUES 
    ('S01', N'Xét nghiệm máu tổng quát', N'Phân tích các chỉ số máu cơ bản (WBC, RBC, PLT, Hb)', 15, 150000),
    ('S02', N'Siêu âm ổ bụng', N'Siêu âm kiểm tra tổng quát các tạng trong ổ bụng', 20, 200000),
    ('S03', N'Chụp X-Quang ngực', N'Chụp X-Quang ngực thẳng kỹ thuật số', 10, 180000),
    ('S04', N'Chụp MRI', N'Chụp cộng hưởng từ độ phân giải cao', 45, 2500000),
    ('S05', N'Nội soi dạ dày', N'Nội soi thực quản, dạ dày, tá tràng ống mềm', 30, 800000),
    ('S06', N'Xét nghiệm nước tiểu', N'Phân tích sinh hóa 10 thông số nước tiểu', 10, 50000),
    ('S07', N'Điện tâm đồ (ECG)', N'Ghi điện tâm đồ 12 chuyển đạo', 15, 120000),
    ('S08', N'Đo loãng xương', N'Đo mật độ xương bằng phương pháp tia X (DEXA)', 20, 250000),
    ('S09', N'Siêu âm thai', N'Siêu âm hình thái thai nhi 4D', 30, 300000),
    ('S10', N'Chụp CT Scanner', N'Chụp cắt lớp vi tính không tiêm thuốc cản quang', 30, 1500000),
    ('S11', N'Xét nghiệm chức năng gan', N'Định lượng các men gan AST, ALT, GGT', 15, 200000),
    ('S12', N'Xét nghiệm chức năng thận', N'Định lượng Ure, Creatinin trong máu', 15, 200000),
    ('S13', N'Nội soi đại tràng', N'Nội soi đại trực tràng toàn bộ ống mềm', 40, 1000000),
    ('S14', N'Đo nhãn áp', N'Đo nhãn áp bằng nhãn áp kế không tiếp xúc', 10, 80000),
    ('S15', N'Lấy cao răng', N'Lấy cao răng và đánh bóng hai hàm', 30, 150000),
    ('S16', N'Châm cứu', N'Châm cứu điều trị đau nhức, phục hồi chức năng', 30, 100000),
    ('S17', N'Đo chức năng hô hấp', N'Đo hô hấp ký, đánh giá dung tích phổi', 20, 180000),
    ('S18', N'Xét nghiệm mỡ máu', N'Định lượng bộ mỡ máu: Cholesterol, Triglycerid, HDL, LDL', 15, 120000),
    ('S19', N'Tư vấn dinh dưỡng chuyên sâu', N'Khám, đánh giá thể trạng và lên thực đơn cá thể hóa', 45, 200000),
    ('S20', N'Test vi khuẩn HP', N'Kiểm tra vi khuẩn Helicobacter pylori qua hơi thở (C13)', 20, 150000);
END
GO

IF NOT EXISTS (SELECT 1 FROM Medicine)
BEGIN
    INSERT INTO Medicine (medicineId, medicineName, activeIngredient, unit, manufacturer, sellPrice, minStock) VALUES 
    ('M01', N'Paracetamol 500mg', N'Paracetamol', N'Viên', N'Dược Hậu Giang', 2000, 1000), 
    ('M02', N'Amoxicillin 250mg', N'Amoxicillin', N'Viên', N'Dược Trung Ương', 5000, 500),
    ('M03', N'Ibuprofen 400mg', N'Ibuprofen', N'Viên', N'Traphaco', 3000, 800), 
    ('M04', N'Omeprazole 20mg', N'Omeprazole', N'Viên', N'OPV Pharma', 4000, 600),
    ('M05', N'Vitamin C 500mg', N'Ascorbic Acid', N'Viên', N'Dược Hậu Giang', 1500, 2000), 
    ('M06', N'Loratadine 10mg', N'Loratadine', N'Viên', N'Medical JSC', 2500, 400),
    ('M07', N'Salbutamol 2mg', N'Salbutamol', N'Viên', N'Traphaco', 1000, 300), 
    ('M08', N'Metformin 500mg', N'Metformin', N'Viên', N'Dược Trung Ương', 3500, 1000),
    ('M09', N'Losartan 50mg', N'Losartan', N'Viên', N'Vimedimex', 4500, 700), 
    ('M10', N'Aspirin 81mg', N'Acetylsalicylic Acid', N'Viên', N'OPV Pharma', 1200, 1500),
    ('M11', N'Diazepam 5mg', N'Diazepam', N'Viên', N'Dược Trung Ương', 5500, 200), 
    ('M12', N'Oresol', N'Electrolytes', N'Gói', N'Traphaco', 3000, 3000),
    ('M13', N'Berberin', N'Berberine chloride', N'Lọ', N'Đông Dược VN', 25000, 100), 
    ('M14', N'Nước muối sinh lý', N'Sodium Chloride 0.9%', N'Chai', N'Vimedimex', 10000, 500),
    ('M15', N'Cồn y tế 70 độ', N'Ethanol', N'Chai', N'Hóa Chất Sinh Hóa', 15000, 200), 
    ('M16', N'Cao dán giảm đau', N'Methyl Salicylate', N'Miếng', N'Thiết Bị Y Tế VN', 5000, 800),
    ('M17', N'Thuốc ho Bổ Phế', N'Herbal Extract', N'Chai', N'Đông Dược VN', 35000, 150), 
    ('M18', N'Sữa dinh dưỡng', N'Nutrition Supplement', N'Hộp', N'Medical JSC', 450000, 50),
    ('M19', N'Men vi sinh', N'Probiotics', N'Ống', N'OPV Pharma', 8000, 1000), 
    ('M20', N'Gaviscon', N'Sodium Alginate', N'Gói', N'Dược Hậu Giang', 7000, 600);
END
GO

IF NOT EXISTS (SELECT 1 FROM ServiceOrder)
BEGIN
    INSERT INTO ServiceOrder (orderId, visitId, serviceCode, status) VALUES 
    ('ORD_01', 'V001', 'S01', 'COMPLETED'), ('ORD_02', 'V002', 'S05', 'COMPLETED'),
    ('ORD_03', 'V003', 'S03', 'COMPLETED'), ('ORD_04', 'V005', 'S09', 'COMPLETED'),
    ('ORD_05', 'V007', 'S07', 'COMPLETED'), ('ORD_06', 'V008', 'S15', 'COMPLETED'),
    ('ORD_07', 'V010', 'S10', 'COMPLETED'), ('ORD_08', 'V012', 'S02', 'COMPLETED'),
    ('ORD_09', 'V014', 'S06', 'COMPLETED'), ('ORD_10', 'V016', 'S16', 'COMPLETED'),
    ('ORD_11', 'V017', 'S17', 'COMPLETED'), ('ORD_12', 'V019', 'S19', 'COMPLETED'),
    ('ORD_13', 'V020', 'S20', 'COMPLETED'), ('ORD_14', 'V001', 'S06', 'COMPLETED'),
    ('ORD_15', 'V002', 'S11', 'PENDING'), ('ORD_16', 'V004', 'S08', 'PENDING'), 
    ('ORD_17', 'V006', 'S14', 'COMPLETED'), ('ORD_18', 'V009', 'S18', 'COMPLETED'), 
    ('ORD_19', 'V011', 'S01', 'COMPLETED'), ('ORD_20', 'V015', 'S06', 'PENDING');
END
GO

IF NOT EXISTS (SELECT 1 FROM LabResult)
BEGIN
    INSERT INTO LabResult (resultId, orderId, performedByAccountId, approvedByAccountId, indexName, value, unit, referenceRange) VALUES 
    ('RES_01', 'ORD_01', 'A002', 'A004', N'Bạch cầu (WBC)', '11.5', '10^9/L', '4.0 - 10.0'), 
    ('RES_02', 'ORD_01', 'A002', 'A004', N'Hồng cầu (RBC)', '4.2', '10^12/L', '4.0 - 5.8'), 
    ('RES_03', 'ORD_01', 'A002', 'A004', N'Tiểu cầu (PLT)', '250', '10^9/L', '150 - 400'), 
    ('RES_04', 'ORD_01', 'A002', 'A004', N'Hemoglobin (Hb)', '135', 'g/L', '120 - 160'), 
    ('RES_05', 'ORD_02', 'A020', 'A004', N'Kết luận Nội soi', N'Viêm loét hang vị', N'Văn bản', N'Bình thường'), 
    ('RES_06', 'ORD_02', 'A020', 'A004', N'Test HP', N'Dương tính (+)', N'Chỉ số', N'Âm tính (-)'), 
    ('RES_07', 'ORD_03', 'A014', 'A005', N'X-Quang Phổi', N'Bóng tim to nhẹ', N'Văn bản', N'Bình thường'), 
    ('RES_08', 'ORD_04', 'A007', 'A007', N'Tim thai', '140', N'lần/phút', '120 - 160'), 
    ('RES_09', 'ORD_04', 'A007', 'A007', N'Cân nặng thai nhi', '3200', 'gram', '2500 - 4000'), 
    ('RES_10', 'ORD_05', 'A001', 'A004', N'Nhịp tim (ECG)', '85', 'bpm', '60 - 100'), 
    ('RES_11', 'ORD_06', 'A010', 'A010', N'Tình trạng răng', N'Nhiều mảng bám', N'Văn bản', N'Bình thường'), 
    ('RES_12', 'ORD_07', 'A014', 'A012', N'CT Sọ não', N'Không phát hiện xuất huyết', N'Văn bản', N'Bình thường'), 
    ('RES_13', 'ORD_08', 'A014', 'A004', N'Siêu âm Gan', N'Gan nhiễm mỡ độ 1', N'Văn bản', N'Bình thường'), 
    ('RES_14', 'ORD_09', 'A002', 'A006', N'Glucose (Nước tiểu)', 'Negative', 'mmol/L', 'Negative'), 
    ('RES_15', 'ORD_09', 'A002', 'A006', N'Protein (Nước tiểu)', 'Trace', 'g/L', 'Negative'), 
    ('RES_16', 'ORD_10', 'A016', 'A016', N'Phác đồ châm cứu', N'Lưu kim 20 phút', N'Văn bản', N'Tiêu chuẩn'), 
    ('RES_17', 'ORD_11', 'A001', 'A017', N'FEV1', '2.5', N'Lít', '> 2.0'), 
    ('RES_18', 'ORD_12', 'A019', 'A019', N'Chỉ số BMI', '17.5', 'kg/m2', '18.5 - 24.9'), 
    ('RES_19', 'ORD_13', 'A020', 'A020', N'Kết quả HP', N'Âm tính (-)', N'Chỉ số', N'Âm tính (-)'), 
    ('RES_20', 'ORD_14', 'A002', 'A001', N'Bạch cầu (Nước tiểu)', '500', 'Cell/uL', '< 10');
END
GO

IF NOT EXISTS (SELECT 1 FROM Warehouse)
BEGIN
    INSERT INTO Warehouse (warehouseId, managerAccountId, warehouseName, location) VALUES 
    ('WH_01', 'A003', N'Kho Thuốc Nội Trú', N'Tầng 1 - Tòa B'),
    ('WH_02', 'A003', N'Kho Thuốc Ngoại Trú', N'Tầng 1 - Tòa A'),
    ('WH_03', 'A003', N'Kho Cấp Cứu', N'Tầng 1 - Tòa C'),
    ('WH_04', 'A003', N'Kho Vật Tư Y Tế', N'Tầng 2 - Tòa B'),
    ('WH_05', 'A003', N'Kho Hóa Chất', N'Tầng 2 - Tòa A'),
    ('WH_06', 'A003', N'Kho Dược Liệu YHCT', N'Tầng 4 - Tòa C'),
    ('WH_07', 'A003', N'Kho Gây Mê', N'Tầng 5 - Tòa C'),
    ('WH_08', 'A003', N'Kho Dinh Dưỡng', N'Tầng 2 - Tòa D'),
    ('WH_09', 'A003', N'Kho Nội Tiêu Hóa', N'Tầng 3 - Tòa A'),
    ('WH_10', 'A003', N'Kho Ngoại', N'Tầng 4 - Tòa A'),
    ('WH_11', 'A003', N'Kho Nhi', N'Tầng 2 - Tòa B'),
    ('WH_12', 'A003', N'Kho Sản', N'Tầng 5 - Tòa A'),
    ('WH_13', 'A003', N'Kho Mắt', N'Tầng 3 - Tòa B'),
    ('WH_14', 'A003', N'Kho TMH', N'Tầng 4 - Tòa B'),
    ('WH_15', 'A003', N'Kho RHM', N'Tầng 5 - Tòa B'),
    ('WH_16', 'A003', N'Kho Da Liễu', N'Tầng 6 - Tòa A'),
    ('WH_17', 'A003', N'Kho HSTC', N'Tầng 2 - Tòa C'),
    ('WH_18', 'A003', N'Kho CDHA', N'Tầng 1 - Tòa D'),
    ('WH_19', 'A003', N'Kho PHCN', N'Tầng 3 - Tòa C'),
    ('WH_20', 'A003', N'Kho Tổng Trữ Dự Phòng', N'Tầng hầm');
END
GO

IF NOT EXISTS (SELECT 1 FROM Prescription)
BEGIN
    INSERT INTO Prescription (prescriptionId, visitId, doctorAccountId, status) VALUES 
    ('PRES_01', 'V001', 'A001', 'COMPLETED'), ('PRES_02', 'V002', 'A004', 'COMPLETED'), 
    ('PRES_03', 'V004', 'A006', 'COMPLETED'), ('PRES_04', 'V006', 'A008', 'COMPLETED'), 
    ('PRES_05', 'V009', 'A011', 'COMPLETED'), ('PRES_06', 'V011', 'A001', 'COMPLETED'), 
    ('PRES_07', 'V013', 'A005', 'COMPLETED'), ('PRES_08', 'V015', 'A001', 'PENDING'), 
    ('PRES_09', 'V018', 'A001', 'COMPLETED'), ('PRES_10', 'V020', 'A020', 'COMPLETED'),
    ('PRES_11', 'V003', 'A005', 'COMPLETED'), ('PRES_12', 'V005', 'A007', 'COMPLETED'),
    ('PRES_13', 'V007', 'A009', 'COMPLETED'), ('PRES_14', 'V008', 'A010', 'COMPLETED'),
    ('PRES_15', 'V010', 'A012', 'COMPLETED'), ('PRES_16', 'V012', 'A004', 'COMPLETED'),
    ('PRES_17', 'V014', 'A006', 'COMPLETED'), ('PRES_18', 'V016', 'A016', 'COMPLETED'),
    ('PRES_19', 'V017', 'A017', 'COMPLETED'), ('PRES_20', 'V019', 'A019', 'COMPLETED');
END
GO

IF NOT EXISTS (SELECT 1 FROM PrescriptionDetail)
BEGIN
    INSERT INTO PrescriptionDetail (prescriptionDetailId, prescriptionId, medicineId, quantity, durationDays, dosage) VALUES 
    ('PD_01', 'PRES_01', 'M01', 10, 5, N'Sáng 1 viên, Tối 1 viên sau ăn'), 
    ('PD_02', 'PRES_01', 'M05', 20, 20, N'Sáng 1 viên hòa nước'), 
    ('PD_03', 'PRES_02', 'M04', 14, 14, N'Sáng 1 viên trước ăn 30 phút'), 
    ('PD_04', 'PRES_02', 'M02', 20, 10, N'Sáng 1 viên, Tối 1 viên'), 
    ('PD_05', 'PRES_03', 'M01', 5, 5, N'Uống nửa viên khi sốt > 38.5'), 
    ('PD_06', 'PRES_03', 'M12', 10, 5, N'Pha 1 gói với 200ml nước'), 
    ('PD_07', 'PRES_04', 'M14', 2, 10, N'Nhỏ mắt ngày 3 lần'), 
    ('PD_08', 'PRES_05', 'M06', 10, 10, N'Tối 1 viên trước khi ngủ'), 
    ('PD_09', 'PRES_05', 'M05', 10, 10, N'Sáng 1 viên'), 
    ('PD_10', 'PRES_06', 'M11', 5, 5, N'Tối 1 viên (Thuốc an thần)'), 
    ('PD_11', 'PRES_07', 'M03', 15, 7, N'Sáng 1 viên, Tối 1 viên giảm đau'), 
    ('PD_12', 'PRES_07', 'M16', 5, 5, N'Dán vùng đau ngày 1 lần'), 
    ('PD_13', 'PRES_07', 'M15', 1, 30, N'Rửa vết thương ngoài da'), 
    ('PD_14', 'PRES_08', 'M05', 30, 30, N'Ngày 1 viên tăng đề kháng'), 
    ('PD_15', 'PRES_08', 'M19', 20, 10, N'Ngày 2 ống sau ăn'), 
    ('PD_16', 'PRES_09', 'M01', 10, 5, N'Uống khi đau đầu'), 
    ('PD_17', 'PRES_09', 'M18', 2, 7, N'Uống bổ sung dinh dưỡng'), 
    ('PD_18', 'PRES_10', 'M04', 28, 28, N'Sáng 1 viên trước ăn'), 
    ('PD_19', 'PRES_10', 'M20', 14, 7, N'Uống 1 gói khi ợ nóng'), 
    ('PD_20', 'PRES_10', 'M19', 14, 7, N'Sáng 1 ống, Tối 1 ống');
END
GO

IF NOT EXISTS (SELECT 1 FROM GoodsReceipt)
BEGIN
    INSERT INTO GoodsReceipt (receiptId, warehouseId, supplierName, totalValue, status) VALUES 
    ('GR_01', 'WH_01', N'Cty Dược Hậu Giang', 19500000, 'COMPLETED'),
    ('GR_02', 'WH_02', N'Cty Dược Trung Ương', 6400000, 'COMPLETED'),
    ('GR_03', 'WH_03', N'Cty Thiết Bị Y Tế VN', 4000000, 'COMPLETED'),
    ('GR_04', 'WH_04', N'Dược Phẩm Traphaco', 2000000, 'COMPLETED'),
    ('GR_05', 'WH_05', N'Hóa Chất Sinh Hóa', 1200000, 'COMPLETED'),
    ('GR_06', 'WH_06', N'Đông Dược VN', 6250000, 'COMPLETED'),
    ('GR_07', 'WH_01', N'Cty Dược Hậu Giang', 13300000, 'COMPLETED'),
    ('GR_08', 'WH_02', N'Dược Phẩm OPV', 4500000, 'COMPLETED'),
    ('GR_09', 'WH_03', N'Medical JSC', 2250000, 'COMPLETED'),
    ('GR_10', 'WH_04', N'Vimedimex', 16000000, 'COMPLETED'),
    ('GR_11', 'WH_05', N'Cty Hóa Dược', 12000000, 'COMPLETED'),
    ('GR_12', 'WH_01', N'Cty Dược Trung Ương', 9600000, 'COMPLETED'),
    ('GR_13', 'WH_02', N'Traphaco', 10800000, 'COMPLETED'),
    ('GR_14', 'WH_03', N'Hậu Giang Pharma', 8000000, 'COMPLETED'),
    ('GR_15', 'WH_04', N'Vimedimex', 11200000, 'COMPLETED'),
    ('GR_16', 'WH_05', N'Medical JSC', 40000000, 'COMPLETED'),
    ('GR_17', 'WH_01', N'OPV Pharma', 18000000, 'COMPLETED'),
    ('GR_18', 'WH_02', N'Cty Thiết Bị Y Tế VN', 7500000, 'PENDING'),
    ('GR_19', 'WH_03', N'Đông Dược VN', 7500000, 'PENDING'),
    ('GR_20', 'WH_04', N'Hóa Chất Sinh Hóa', 0, 'PENDING');
END
GO

IF NOT EXISTS (SELECT 1 FROM ReceiptDetail)
BEGIN
    INSERT INTO ReceiptDetail (receiptDetailId, receiptId, medicineId, batchNo, expiryDate, quantity, importPrice) VALUES 
    ('RD_01', 'GR_01', 'M01', 'B2026-01', '2028-12-31', 5000, 1500),
    ('RD_02', 'GR_01', 'M02', 'B2026-02', '2028-10-15', 3000, 4000),
    ('RD_03', 'GR_02', 'M04', 'B2026-03', '2029-01-20', 2000, 3200),
    ('RD_04', 'GR_03', 'M05', 'B2026-04', '2027-06-30', 4000, 1000),
    ('RD_05', 'GR_04', 'M06', 'B2026-05', '2028-05-11', 1000, 2000),
    ('RD_06', 'GR_05', 'M07', 'B2026-06', '2028-11-22', 1500, 800),
    ('RD_07', 'GR_06', 'M08', 'B2026-07', '2029-03-10', 2500, 2500),
    ('RD_08', 'GR_07', 'M09', 'B2026-08', '2028-09-09', 3500, 3800),
    ('RD_09', 'GR_08', 'M10', 'B2026-09', '2027-12-01', 4500, 1000),
    ('RD_10', 'GR_09', 'M11', 'B2026-10', '2028-02-14', 500, 4500),
    ('RD_11', 'GR_10', 'M12', 'B2026-11', '2029-07-20', 8000, 2000),
    ('RD_12', 'GR_11', 'M13', 'B2026-12', '2028-04-18', 600, 20000),
    ('RD_13', 'GR_12', 'M14', 'B2026-13', '2029-08-08', 1200, 8000),
    ('RD_14', 'GR_13', 'M15', 'B2026-14', '2027-11-11', 900, 12000),
    ('RD_15', 'GR_14', 'M16', 'B2026-15', '2028-01-30', 2000, 4000),
    ('RD_16', 'GR_15', 'M17', 'B2026-16', '2029-05-05', 400, 28000),
    ('RD_17', 'GR_16', 'M18', 'B2026-17', '2027-10-10', 100, 400000),
    ('RD_18', 'GR_17', 'M19', 'B2026-18', '2028-12-12', 3000, 6000),
    ('RD_19', 'GR_18', 'M20', 'B2026-19', '2029-02-28', 1500, 5000),
    ('RD_20', 'GR_19', 'M01', 'B2026-20', '2028-12-31', 5000, 1500);
END
GO

IF NOT EXISTS (SELECT 1 FROM GoodsIssue)
BEGIN
    INSERT INTO GoodsIssue (issueId, prescriptionId, warehouseId, reason, status) VALUES 
    ('GI_01', 'PRES_01', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_02', 'PRES_02', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_03', NULL,      'WH_01', N'Xuất thuốc nội bộ Khoa Cấp Cứu', 'COMPLETED'),
    ('GI_04', 'PRES_03', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_05', 'PRES_04', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_06', NULL,      'WH_04', N'Cấp phát vật tư phòng mổ', 'COMPLETED'),
    ('GI_07', 'PRES_05', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_08', 'PRES_06', 'WH_01', N'Xuất thuốc bệnh nhân nội trú', 'COMPLETED'),
    ('GI_09', NULL,      'WH_05', N'Cấp hóa chất cho phòng Lab', 'COMPLETED'),
    ('GI_10', 'PRES_07', 'WH_01', N'Xuất thuốc bệnh nhân nội trú', 'COMPLETED'),
    ('GI_11', 'PRES_09', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_12', NULL,      'WH_08', N'Cấp phát sữa dinh dưỡng', 'COMPLETED'),
    ('GI_13', 'PRES_10', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_14', 'PRES_11', 'WH_01', N'Xuất thuốc bệnh nhân nội trú', 'COMPLETED'),
    ('GI_15', NULL,      'WH_03', N'Bổ sung tủ trực cấp cứu', 'COMPLETED'),
    ('GI_16', 'PRES_12', 'WH_01', N'Xuất thuốc bệnh nhân nội trú', 'COMPLETED'),
    ('GI_17', 'PRES_13', 'WH_02', N'Xuất thuốc theo đơn', 'COMPLETED'),
    ('GI_18', NULL,      'WH_06', N'Cấp phát dược liệu', 'PENDING'),
    ('GI_19', 'PRES_14', 'WH_02', N'Xuất thuốc theo đơn', 'PENDING'),
    ('GI_20', 'PRES_15', 'WH_01', N'Xuất thuốc bệnh nhân nội trú', 'PENDING');
END
GO

IF NOT EXISTS (SELECT 1 FROM IssueDetail)
BEGIN
    INSERT INTO IssueDetail (issueDetailId, issueId, medicineId, batchNo, quantity) VALUES 
    ('ISD_01', 'GI_01', 'M01', 'B2026-01', 10),
    ('ISD_02', 'GI_01', 'M05', 'B2026-04', 20),
    ('ISD_03', 'GI_02', 'M04', 'B2026-03', 14),
    ('ISD_04', 'GI_03', 'M11', 'B2026-10', 50),
    ('ISD_05', 'GI_04', 'M01', 'B2026-01', 5),
    ('ISD_06', 'GI_04', 'M12', 'B2026-11', 10),
    ('ISD_07', 'GI_05', 'M14', 'B2026-13', 2),
    ('ISD_08', 'GI_06', 'M15', 'B2026-14', 50),
    ('ISD_09', 'GI_07', 'M06', 'B2026-05', 10),
    ('ISD_10', 'GI_08', 'M11', 'B2026-10', 5),
    ('ISD_11', 'GI_09', 'M14', 'B2026-13', 100),
    ('ISD_12', 'GI_10', 'M03', 'B2026-02', 15),
    ('ISD_13', 'GI_11', 'M01', 'B2026-01', 10),
    ('ISD_14', 'GI_12', 'M18', 'B2026-17', 10),
    ('ISD_15', 'GI_13', 'M04', 'B2026-03', 28),
    ('ISD_16', 'GI_14', 'M02', 'B2026-02', 20),
    ('ISD_17', 'GI_15', 'M07', 'B2026-06', 30),
    ('ISD_18', 'GI_16', 'M09', 'B2026-08', 14),
    ('ISD_19', 'GI_17', 'M10', 'B2026-09', 30),
    ('ISD_20', 'GI_20', 'M08', 'B2026-07', 60);
END
GO

-- 2.4. Thêm bản ghi Viện phí (Hóa đơn)
IF NOT EXISTS (SELECT 1 FROM Invoice)
BEGIN
    INSERT INTO Invoice (invoiceId, visitId, paymentMethod, totalAmount, insuranceAmount, finalAmount, status) VALUES 
    ('INV_01', 'V001', 'CASH', 150000, 50000, 100000, 'PAID'),
    ('INV_02', 'V002', 'CARD', 800000, 150000, 650000, 'PAID'),
    ('INV_03', 'V003', 'TRANSFER', 180000, 80000, 100000, 'PAID'),
    ('INV_04', 'V004', 'CASH', 20000, 0, 20000, 'UNPAID'),
    ('INV_05', 'V005', 'CARD', 300000, 100000, 200000, 'PAID'),
    ('INV_06', 'V006', 'CASH', 12500, 0, 12500, 'PAID'),
    ('INV_07', 'V007', 'TRANSFER', 120000, 0, 120000, 'UNPAID'),
    ('INV_08', 'V008', 'CARD', 150000, 50000, 100000, 'PAID'),
    ('INV_09', 'V009', 'CASH', 56000, 0, 56000, 'PAID'),
    ('INV_10', 'V010', 'TRANSFER', 1500000, 500000, 1000000, 'UNPAID'),
    ('INV_11', 'V011', 'CASH', 15000, 0, 15000, 'PAID'),
    ('INV_12', 'V012', 'CARD', 200000, 100000, 100000, 'PAID'),
    ('INV_13', 'V013', 'TRANSFER', 100000, 50000, 50000, 'PAID'),
    ('INV_14', 'V014', 'CASH', 50000, 0, 50000, 'UNPAID'),
    ('INV_15', 'V015', 'CARD', 45000, 0, 45000, 'PAID'),
    ('INV_16', 'V016', 'CASH', 100000, 25000, 75000, 'PAID'),
    ('INV_17', 'V017', 'TRANSFER', 180000, 0, 180000, 'UNPAID'),
    ('INV_18', 'V018', 'CARD', 80000, 0, 80000, 'PAID'),
    ('INV_19', 'V019', 'CASH', 200000, 50000, 150000, 'PAID'),
    ('INV_20', 'V020', 'TRANSFER', 1000000, 250000, 750000, 'PAID');
END
GO

IF NOT EXISTS (SELECT 1 FROM InvoiceDetail)
BEGIN
    INSERT INTO InvoiceDetail (detailId, invoiceId, itemType, itemName, quantity, unitPrice) VALUES 
    ('ID01', 'INV_01', 'SERVICE', N'Xét nghiệm máu tổng quát', 1, 150000),
    ('ID02', 'INV_02', 'SERVICE', N'Nội soi dạ dày', 1, 800000),
    ('ID03', 'INV_03', 'SERVICE', N'Chụp X-Quang ngực', 1, 180000),
    ('ID04', 'INV_04', 'MEDICINE', N'Paracetamol 500mg', 10, 2000),
    ('ID05', 'INV_05', 'SERVICE', N'Siêu âm thai', 1, 300000),
    ('ID06', 'INV_06', 'MEDICINE', N'Loratadine 10mg', 5, 2500),
    ('ID07', 'INV_07', 'SERVICE', N'Điện tâm đồ (ECG)', 1, 120000),
    ('ID08', 'INV_08', 'SERVICE', N'Lấy cao răng', 1, 150000),
    ('ID09', 'INV_09', 'MEDICINE', N'Omeprazole 20mg', 14, 4000),
    ('ID10', 'INV_10', 'SERVICE', N'Chụp CT Scanner', 1, 1500000),
    ('ID11', 'INV_11', 'MEDICINE', N'Oresol', 5, 3000),
    ('ID12', 'INV_12', 'SERVICE', N'Siêu âm ổ bụng', 1, 200000),
    ('ID13', 'INV_13', 'MEDICINE', N'Amoxicillin 250mg', 20, 5000),
    ('ID14', 'INV_14', 'SERVICE', N'Xét nghiệm nước tiểu', 1, 50000),
    ('ID15', 'INV_15', 'MEDICINE', N'Vitamin C 500mg', 30, 1500),
    ('ID16', 'INV_16', 'SERVICE', N'Châm cứu', 1, 100000),
    ('ID17', 'INV_17', 'SERVICE', N'Đo chức năng hô hấp', 1, 180000),
    ('ID18', 'INV_18', 'MEDICINE', N'Men vi sinh', 10, 8000),
    ('ID19', 'INV_19', 'SERVICE', N'Tư vấn dinh dưỡng chuyên sâu', 1, 200000),
    ('ID20', 'INV_20', 'SERVICE', N'Nội soi đại tràng', 1, 1000000);
END
GO


-- 3. Thử nghiệm và truy vấn
-- 3.1. Truy xuất danh sách bệnh nhân đã được kê đơn thuốc 'Paracetamol 500mg'
-- SELECT DISTINCT p.fullName, p.phone, p.dob 
-- FROM Patient p
-- JOIN MedicalVisit v ON p.patientId = v.patientId
-- JOIN Prescription pr ON v.visitId = pr.visitId
-- JOIN PrescriptionDetail pd ON pr.prescriptionId = pd.prescriptionId
-- JOIN Medicine m ON pd.medicineId = m.medicineId
-- WHERE m.medicineName = 'Paracetamol 500mg';

-- 3.2. Liệt kê danh sách bệnh nhân và chẩn đoán bệnh lý chính 
-- SELECT DISTINCT p.fullName, icd.diseaseName 
-- FROM Patient p
-- JOIN MedicalVisit v ON p.patientId = v.patientId
-- JOIN Diagnosis d ON v.visitId = d.visitId
-- JOIN Icd10Dictionary icd ON d.icd10Code = icd.icd10Code
-- WHERE d.diagType = 'PRIMARY';

-- 3.3. Lọc danh mục thuốc tồn kho chưa từng được kê đơn 
-- SELECT medicineName 
-- FROM Medicine 
-- WHERE medicineId NOT IN (SELECT medicineId FROM PrescriptionDetail);

-- 3.4. Danh sách bệnh nhân đang chờ kết quả xét nghiệm
-- SELECT DISTINCT p.fullName, ts.serviceName 
-- FROM Patient p
-- JOIN MedicalVisit v ON p.patientId = v.patientId
-- JOIN ServiceOrder so ON v.visitId = so.visitId
-- JOIN TechnicalService ts ON so.serviceCode = ts.serviceCode
-- WHERE so.status = 'PENDING';

-- 3.5. Danh sách bệnh nhân đang nợ viện phí 
-- SELECT DISTINCT p.fullName, p.phone, i.finalAmount 
-- FROM Patient p
-- JOIN MedicalVisit v ON p.patientId = v.patientId
-- JOIN Invoice i ON v.visitId = i.visitId
-- WHERE i.status = 'UNPAID';

-- 3.6. Tiếp nhận bệnh nhân mới
-- INSERT INTO Patient (patientId, fullName, phone, insuranceNo, gender, dob, address) 
-- VALUES ('BN021', N'Trần Văn Thử Nghiệm', '0911222333', 'BHYT021', 'MALE', '1990-01-01', N'Hà Nội');

-- 3.7. Tạo mới một lượt khám bệnh (Medical Visit)
-- INSERT INTO MedicalVisit (visitId, patientId, doctorAccountId, deptId, status, symptoms) 
-- VALUES ('V021', 'BN021', 'A001', 'KHOA_KHAM', 'PENDING', N'Ho kéo dài, rát họng');

-- 3.8. Ghi nhận chỉ số sinh tồn (Vital Sign) tại phòng khám
-- INSERT INTO VitalSign (vitalId, visitId, bloodPressure, heartRate, temperature, respiratoryRate, weight, height) 
-- VALUES ('VS21', 'V021', '120/80', 85, 37.5, 18, 65.5, 1.70);

-- 3.9. Thêm mới một dịch vụ Cận lâm sàng vào danh mục
-- INSERT INTO TechnicalService (serviceCode, serviceName, description, durationEst, unitPrice) 
-- VALUES ('S21', N'Xét nghiệm PCR Cúm A/B', N'Phát hiện virus Cúm A/B bằng sinh học phân tử', 45, 250000);

-- 3.10. Khởi tạo phiếu chỉ định dịch vụ (Service Order)
-- INSERT INTO ServiceOrder (orderId, visitId, serviceCode, status) 
-- VALUES ('ORD_21', 'V021', 'S21', 'PENDING');

-- 3.11. Cập nhật thôngত্তি liên lạc của bệnh nhân
-- UPDATE Patient 
-- SET phone = '0999888777', address = N'Hồ Chí Minh' 
-- WHERE patientId = 'BN001';

-- 3.12. Đóng ca khám bệnh (Hoàn tất)
-- UPDATE MedicalVisit 
-- SET status = 'COMPLETED', endTime = GETDATE(), notes = N'Bệnh nhân đáp ứng tốt, cho về theo dõi' 
-- WHERE visitId = 'V015';

-- 3.13. Điều chỉnh giá bán lẻ thuốc trong Kho Dược
-- UPDATE Medicine 
-- SET sellPrice = sellPrice * 1.1 
-- WHERE medicineId = 'M01';

-- 3.14. Thanh toán hóa đơn viện phí
-- UPDATE Invoice 
-- SET status = 'PAID', paymentMethod = 'TRANSFER' 
-- WHERE invoiceId = 'INV_04';

-- 3.15. Cập nhật kết quả phiếu chỉ định Cận lâm sàng
-- UPDATE ServiceOrder 
-- SET status = 'COMPLETED', doctorNotes = N'Đã lấy đủ mẫu máu' 
-- WHERE orderId = 'ORD_15';

-- 3.16. Hủy bỏ một chi tiết thuốc trong Đơn thuốc
-- DELETE FROM PrescriptionDetail 
-- WHERE prescriptionDetailId = 'PD_01';

-- 3.17. Xóa bỏ bản ghi sinh hiệu (Vital Sign) nhập sai
-- DELETE FROM VitalSign 
-- WHERE vitalId = 'VS20';

-- 3.18. Hủy phiếu chỉ định xét nghiệm (Chưa thực hiện)
-- DELETE FROM ServiceOrder 
-- WHERE orderId = 'ORD_16';

-- 3.19. Xóa một mã chẩn đoán phụ (Diagnosis)
-- DELETE FROM Diagnosis 
-- WHERE diagnosisId = 'D015';

-- 3.20. Xóa một hạng mục bị tính nhầm trong Hóa đơn
-- DELETE FROM InvoiceDetail 
-- WHERE detailId = 'ID14';

-- 3.21. Cập nhật hàng loạt mã bệnh lý mới (Bulk Insert)
-- INSERT INTO Icd10Dictionary (icd10Code, diseaseName) VALUES 
-- ('A00', N'Bệnh tả (Cholera)'),
-- ('A01', N'Thương hàn và phó thương hàn'),
-- ('A03', N'Bệnh lỵ trực trùng (Shigellosis)');

-- 3.22. Khởi tạo một kho dược phẩm mới
-- INSERT INTO Warehouse (warehouseId, managerAccountId, warehouseName, location) 
-- VALUES ('WH_21', 'A003', N'Kho Y Tế Dự Phòng', N'Tầng 2 - Tòa D');

-- 3.23. Khai báo hệ thống phân quyền mới 
-- INSERT INTO Permission (permissionId, permissionName, moduleName) VALUES 
-- ('P21', N'Xuất báo cáo kho', N'Kho Dược'),
-- ('P22', N'In kết quả xét nghiệm', N'Cận Lâm Sàng');

-- 3.24. Cấp quyền truy cập cho chức danh
-- INSERT INTO RolePermission (roleId, permissionId) VALUES 
-- ('R09', 'P21'), 
-- ('R06', 'P22');

-- 3.25. Di dời và cập nhật thông tin Khoa Cấp Cứu
-- UPDATE Department 
-- SET location = N'Tầng 1 - Tòa Nhà D (Khu Mới)', hotline = '1900-8888' 
-- WHERE deptId = 'KHOA_CC';

-- 3.26. Khóa tài khoản nhân viên nghi ngờ vi phạm bảo mật
-- UPDATE UserAccount 
-- SET isActive = 0, password = 'LOCKED_BY_ADMIN' 
-- WHERE accountId = 'A010';

-- 3.27. Cập nhật chiến lược giá và tồn kho toàn viện
-- UPDATE Medicine 
-- SET minStock = 2000, sellPrice = sellPrice * 1.05 
-- WHERE unit = N'Viên';

-- 3.28. Thu hồi và xóa bỏ một kết quả xét nghiệm sai lệch
-- DELETE FROM LabResult 
-- WHERE resultId = 'RES_20';

-- 3.29. Dọn dẹp các chi tiết hóa đơn giá trị 0 đồng
-- DELETE FROM InvoiceDetail 
-- WHERE unitPrice = 0;

-- 3.30. Thu gom rác dữ liệu (Garbage Collection): Xóa lịch hẹn bị hủy
-- DELETE FROM MedicalVisit 
-- WHERE status = 'CANCELLED';

