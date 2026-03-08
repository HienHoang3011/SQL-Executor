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
    unit                  VARCHAR(50),
    referenceRange        VARCHAR(100),
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
    unit            VARCHAR(50),
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
    patientId       VARCHAR(20)   NOT NULL,
    createdDate     DATETIME      DEFAULT GETDATE(),
    paymentMethod   VARCHAR(50),
    totalAmount     DECIMAL(18,2) NOT NULL,
    insuranceAmount DECIMAL(18,2) DEFAULT 0,
    finalAmount     DECIMAL(18,2) NOT NULL,
    status          VARCHAR(20)   DEFAULT 'UNPAID',
    CONSTRAINT FK_Inv_Visit    FOREIGN KEY (visitId)   REFERENCES MedicalVisit(visitId),
    CONSTRAINT FK_Inv_Patient  FOREIGN KEY (patientId) REFERENCES Patient(patientId),
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
-- ============================================================

-- 2.1. Master Data: Departments
IF NOT EXISTS (SELECT 1 FROM Department)
BEGIN
    INSERT INTO Department (deptId, deptName, deptType, location, hotline) VALUES 
    ('KHOA_KHAM',  N'Khoa Khám Bệnh',              N'Lâm sàng',        N'Tầng 1 - Tòa A', '1900-0001'),
    ('KHOA_XN',    N'Khoa Xét Nghiệm',             N'Cận lâm sàng',    N'Tầng 2 - Tòa A', '1900-0002'),
    ('KHOA_DUOC',  N'Khoa Dược',                   N'Dược',            N'Tầng 1 - Tòa B', '1900-0003'),
    ('KHOA_NOI',   N'Khoa Nội Tổng Hợp',           N'Lâm sàng',        N'Tầng 3 - Tòa A', '1900-0004'),
    ('KHOA_NGOAI', N'Khoa Ngoại',                  N'Lâm sàng',        N'Tầng 4 - Tòa A', '1900-0005'),
    ('KHOA_NHI',   N'Khoa Nhi',                    N'Lâm sàng',        N'Tầng 2 - Tòa B', '1900-0006'),
    ('KHOA_SAN',   N'Khoa Sản',                    N'Lâm sàng',        N'Tầng 5 - Tòa A', '1900-0007'),
    ('KHOA_MAT',   N'Khoa Mắt',                    N'Lâm sàng',        N'Tầng 3 - Tòa B', '1900-0008'),
    ('KHOA_TMH',   N'Khoa Tai Mũi Họng',           N'Lâm sàng',        N'Tầng 4 - Tòa B', '1900-0009'),
    ('KHOA_RHM',   N'Khoa Răng Hàm Mặt',           N'Lâm sàng',        N'Tầng 5 - Tòa B', '1900-0010'),
    ('KHOA_DALIEU',N'Khoa Da Liễu',                N'Lâm sàng',        N'Tầng 6 - Tòa A', '1900-0011'),
    ('KHOA_CC',    N'Khoa Cấp Cứu',                N'Lâm sàng',        N'Tầng 1 - Tòa C', '1900-0012'),
    ('KHOA_HSTC',  N'Khoa Hồi Sức Tích Cực',      N'Lâm sàng',        N'Tầng 2 - Tòa C', '1900-0013'),
    ('KHOA_CDHA',  N'Khoa Chẩn Đoán Hình Ảnh',    N'Cận lâm sàng',    N'Tầng 1 - Tòa D', '1900-0014'),
    ('KHOA_PHCN',  N'Khoa Phục Hồi Chức Năng',    N'Lâm sàng',        N'Tầng 3 - Tòa C', '1900-0015'),
    ('KHOA_YHCT',  N'Khoa Y Học Cổ Truyền',        N'Lâm sàng',        N'Tầng 4 - Tòa C', '1900-0016'),
    ('KHOA_GMHS',  N'Khoa Gây Mê Hồi Sức',         N'Lâm sàng',        N'Tầng 5 - Tòa C', '1900-0017'),
    ('KHOA_KSNK',  N'Khoa Kiểm Soát Nhiễm Khuẩn', N'Hành chính',      N'Tầng 6 - Tòa C', '1900-0018'),
    ('KHOA_DD',    N'Khoa Dinh Dưỡng',             N'Cận lâm sàng',    N'Tầng 2 - Tòa D', '1900-0019'),
    ('KHOA_TH',    N'Khoa Tiêu Hóa',               N'Lâm sàng',        N'Tầng 7 - Tòa A', '1900-0020');
END
GO

-- Staff
IF NOT EXISTS (SELECT 1 FROM Staff)
BEGIN
    INSERT INTO Staff (staffId, deptId, fullName, specialty, gender, dob, phone, email) VALUES 
    ('NV001', 'KHOA_KHAM',   N'Nguyễn Văn A',  N'Nội Tổng Quát',      'MALE',   '1985-05-10', '0901234561', 'nva@hosp.com'),
    ('NV002', 'KHOA_XN',     N'Trần Thị B',    N'Huyết Học',          'FEMALE', '1990-08-20', '0901234562', 'ttb@hosp.com'),
    ('NV003', 'KHOA_DUOC',   N'Lê Văn C',      N'Dược Lâm Sàng',      'MALE',   '1988-11-15', '0901234563', 'lvc@hosp.com'),
    ('NV004', 'KHOA_NOI',    N'Phạm Thị D',    N'Nội Tiêu Hóa',       'FEMALE', '1982-02-28', '0901234564', 'ptd@hosp.com'),
    ('NV005', 'KHOA_NGOAI',  N'Hoàng Văn E',   N'Ngoại Thần Kinh',    'MALE',   '1979-07-11', '0901234565', 'hve@hosp.com'),
    ('NV006', 'KHOA_NHI',    N'Vũ Thị F',      N'Nhi Khoa',           'FEMALE', '1993-04-05', '0901234566', 'vtf@hosp.com'),
    ('NV007', 'KHOA_SAN',    N'Đặng Văn G',    N'Sản Khoa',           'MALE',   '1980-09-19', '0901234567', 'dvg@hosp.com'),
    ('NV008', 'KHOA_MAT',    N'Bùi Thị H',     N'Nhãn Khoa',          'FEMALE', '1987-12-25', '0901234568', 'bth@hosp.com'),
    ('NV009', 'KHOA_TMH',    N'Đỗ Văn I',      N'Tai Mũi Họng',       'MALE',   '1991-03-30', '0901234569', 'dvi@hosp.com'),
    ('NV010', 'KHOA_RHM',    N'Hồ Thị J',      N'Răng Hàm Mặt',       'FEMALE', '1986-06-14', '0901234570', 'htj@hosp.com'),
    ('NV011', 'KHOA_DALIEU', N'Ngô Văn K',     N'Da Liễu',            'MALE',   '1992-01-08', '0901234571', 'nvk@hosp.com'),
    ('NV012', 'KHOA_CC',     N'Dương Thị L',   N'Cấp Cứu',            'FEMALE', '1989-10-22', '0901234572', 'dtl@hosp.com'),
    ('NV013', 'KHOA_HSTC',   N'Lý Văn M',      N'Hồi Sức',            'MALE',   '1984-05-05', '0901234573', 'lvm@hosp.com'),
    ('NV014', 'KHOA_CDHA',   N'Mai Thị N',     N'Chẩn Đoán HA',       'FEMALE', '1994-08-18', '0901234574', 'mtn@hosp.com'),
    ('NV015', 'KHOA_PHCN',   N'Trịnh Văn O',   N'Vật Lý Trị Liệu',   'MALE',   '1981-11-30', '0901234575', 'tvo@hosp.com'),
    ('NV016', 'KHOA_YHCT',   N'Đinh Thị P',    N'Châm Cứu',           'FEMALE', '1983-04-12', '0901234576', 'dtp@hosp.com'),
    ('NV017', 'KHOA_GMHS',   N'Vương Văn Q',   N'Gây Mê',             'MALE',   '1978-02-14', '0901234577', 'vvq@hosp.com'),
    ('NV018', 'KHOA_KSNK',   N'Tạ Thị R',      N'Kiểm Soát Khuẩn',   'FEMALE', '1995-09-09', '0901234578', 'ttr@hosp.com'),
    ('NV019', 'KHOA_DD',     N'Châu Văn S',    N'Dinh Dưỡng',         'MALE',   '1988-12-01', '0901234579', 'cvs@hosp.com'),
    ('NV020', 'KHOA_TH',     N'Lâm Thị T',     N'Nội Soi Tiêu Hóa',  'FEMALE', '1991-07-25', '0901234580', 'ltt@hosp.com');
END
GO

-- Roles
IF NOT EXISTS (SELECT 1 FROM Role)
BEGIN
    INSERT INTO Role (roleId, roleName, description) VALUES 
    ('R01', N'Bác sĩ Khám',       N'Khám bệnh'),
    ('R02', N'Bác sĩ Ngoại',      N'Phẫu thuật'),
    ('R03', N'Bác sĩ Nhi',        N'Khám nhi'),
    ('R04', N'Bác sĩ Sản',        N'Khám sản'),
    ('R05', N'Bác sĩ Cấp cứu',    N'Trực cấp cứu'),
    ('R06', N'KTV Xét nghiệm',    N'Chạy máy XN'),
    ('R07', N'KTV X-Quang',       N'Chụp X-Quang'),
    ('R08', N'KTV Siêu âm',       N'Siêu âm'),
    ('R09', N'Dược sĩ kho',       N'Quản lý kho'),
    ('R10', N'Dược sĩ bán',       N'Bán thuốc'),
    ('R11', N'Thu ngân 1',        N'Thu tiền sảnh'),
    ('R12', N'Thu ngân 2',        N'Thu tiền cấp cứu'),
    ('R13', N'Lễ tân',            N'Tiếp đón'),
    ('R14', N'Điều dưỡng',        N'Chăm sóc'),
    ('R15', N'Admin',             N'Quản trị IT'),
    ('R16', N'Bác sĩ YHCT',       N'Bác sĩ đông y'),
    ('R17', N'Bác sĩ Gây Mê',     N'Gây mê phẫu thuật'),
    ('R18', N'Chuyên viên KSNK',  N'Kiểm soát nhiễm khuẩn'),
    ('R19', N'Chuyên viên DD',    N'Lên thực đơn bệnh lý'),
    ('R20', N'Bác sĩ Nội soi',    N'Nội soi tiêu hóa');
END
GO

-- User Accounts
IF NOT EXISTS (SELECT 1 FROM UserAccount)
BEGIN
    INSERT INTO UserAccount (accountId, staffId, roleId, username, password) VALUES 
    ('A001', 'NV001', 'R01', 'bs_nva',  'pw1'),  ('A002', 'NV002', 'R06', 'ktv_ttb', 'pw2'),
    ('A003', 'NV003', 'R09', 'ds_lvc',  'pw3'),  ('A004', 'NV004', 'R01', 'bs_ptd',  'pw4'),
    ('A005', 'NV005', 'R02', 'bs_hve',  'pw5'),  ('A006', 'NV006', 'R03', 'bs_vtf',  'pw6'),
    ('A007', 'NV007', 'R04', 'bs_dvg',  'pw7'),  ('A008', 'NV008', 'R01', 'bs_bth',  'pw8'),
    ('A009', 'NV009', 'R01', 'bs_dvi',  'pw9'),  ('A010', 'NV010', 'R01', 'bs_htj',  'pw10'),
    ('A011', 'NV011', 'R01', 'bs_nvk',  'pw11'), ('A012', 'NV012', 'R05', 'bs_dtl',  'pw12'),
    ('A013', 'NV013', 'R05', 'bs_lvm',  'pw13'), ('A014', 'NV014', 'R07', 'ktv_mtn', 'pw14'),
    ('A015', 'NV015', 'R14', 'dd_tvo',  'pw15'), ('A016', 'NV016', 'R16', 'bs_dtp',  'pw16'),
    ('A017', 'NV017', 'R17', 'bs_vvq',  'pw17'), ('A018', 'NV018', 'R18', 'cv_ttr',  'pw18'),
    ('A019', 'NV019', 'R19', 'cv_cvs',  'pw19'), ('A020', 'NV020', 'R20', 'bs_ltt',  'pw20');
END
GO

-- 2.2. Patients, Visits, Vitals, Diagnoses
IF NOT EXISTS (SELECT 1 FROM Patient)
BEGIN
    INSERT INTO Patient (patientId, fullName, phone, insuranceNo, gender, dob, address) VALUES 
    ('BN001', N'Hoàng Trọng 1',  '0987654301', 'BHYT001', 'MALE',   '1995-02-28', N'Hà Nội'),
    ('BN002', N'Hoàng Trọng 2',  '0987654302', 'BHYT002', 'FEMALE', '1996-03-15', N'Hà Nội'),
    ('BN003', N'Hoàng Trọng 3',  '0987654303', 'BHYT003', 'MALE',   '1997-04-20', N'Hà Nội'),
    ('BN004', N'Hoàng Trọng 4',  '0987654304', 'BHYT004', 'FEMALE', '1998-05-10', N'Hà Nội'),
    ('BN005', N'Hoàng Trọng 5',  '0987654305', 'BHYT005', 'MALE',   '1999-06-05', N'Hà Nội'),
    ('BN006', N'Hoàng Trọng 6',  '0987654306', 'BHYT006', 'FEMALE', '2000-07-12', N'Hà Nội'),
    ('BN007', N'Hoàng Trọng 7',  '0987654307', 'BHYT007', 'MALE',   '2001-08-18', N'Hà Nội'),
    ('BN008', N'Hoàng Trọng 8',  '0987654308', 'BHYT008', 'FEMALE', '2002-09-22', N'Hà Nội'),
    ('BN009', N'Hoàng Trọng 9',  '0987654309', 'BHYT009', 'MALE',   '2003-10-30', N'Hà Nội'),
    ('BN010', N'Hoàng Trọng 10', '0987654310', 'BHYT010', 'FEMALE', '2004-11-05', N'Hà Nội'),
    ('BN011', N'Hoàng Trọng 11', '0987654311', 'BHYT011', 'MALE',   '1985-12-11', N'Hà Nội'),
    ('BN012', N'Hoàng Trọng 12', '0987654312', 'BHYT012', 'FEMALE', '1986-01-14', N'Hà Nội'),
    ('BN013', N'Hoàng Trọng 13', '0987654313', 'BHYT013', 'MALE',   '1987-02-19', N'Hà Nội'),
    ('BN014', N'Hoàng Trọng 14', '0987654314', 'BHYT014', 'FEMALE', '1988-03-25', N'Hà Nội'),
    ('BN015', N'Hoàng Trọng 15', '0987654315', 'BHYT015', 'MALE',   '1989-04-01', N'Hà Nội'),
    ('BN016', N'Hoàng Trọng 16', '0987654316', 'BHYT016', 'FEMALE', '1990-05-08', N'Hà Nội'),
    ('BN017', N'Hoàng Trọng 17', '0987654317', 'BHYT017', 'MALE',   '1991-06-12', N'Hà Nội'),
    ('BN018', N'Hoàng Trọng 18', '0987654318', 'BHYT018', 'FEMALE', '1992-07-16', N'Hà Nội'),
    ('BN019', N'Hoàng Trọng 19', '0987654319', 'BHYT019', 'MALE',   '1993-08-21', N'Hà Nội'),
    ('BN020', N'Hoàng Trọng 20', '0987654320', 'BHYT020', 'FEMALE', '1994-09-29', N'Hà Nội');
END
GO

IF NOT EXISTS (SELECT 1 FROM Icd10Dictionary)
BEGIN
    INSERT INTO Icd10Dictionary (icd10Code, diseaseName) VALUES 
    ('J00', N'Viêm mũi họng cấp'),              ('E11', N'Tiểu đường type 2'),
    ('I10', N'Tăng huyết áp'),                  ('K21', N'Trào ngược dạ dày'),
    ('M54', N'Đau lưng'),                        ('A09', N'Tiêu chảy'),
    ('J20', N'Viêm phế quản cấp'),               ('N20', N'Sỏi thận'),
    ('H10', N'Viêm kết mạc'),                   ('L50', N'Mề đay'),
    ('S02', N'Vỡ xương sọ'),                    ('O20', N'Động thai'),
    ('K02', N'Sâu răng'),                        ('R50', N'Sốt không rõ nguyên nhân'),
    ('Z00', N'Khám sức khỏe tổng quát'),         ('M53', N'Bệnh lý cột sống cổ'),
    ('Z01', N'Khám trước phẫu thuật'),           ('R53', N'Khó chịu và mệt mỏi'),
    ('E46', N'Suy dinh dưỡng thiếu protein-năng lượng'), ('K29', N'Viêm dạ dày và tá tràng');
END
GO

IF NOT EXISTS (SELECT 1 FROM MedicalVisit)
BEGIN
    INSERT INTO MedicalVisit (visitId, patientId, doctorAccountId, deptId, status, symptoms) VALUES 
    ('V001', 'BN001', 'A001', 'KHOA_KHAM',   'COMPLETED', N'Đau đầu'),
    ('V002', 'BN002', 'A004', 'KHOA_NOI',    'COMPLETED', N'Đau bụng'),
    ('V003', 'BN003', 'A005', 'KHOA_NGOAI',  'COMPLETED', N'Gãy tay'),
    ('V004', 'BN004', 'A006', 'KHOA_NHI',    'COMPLETED', N'Sốt cao'),
    ('V005', 'BN005', 'A007', 'KHOA_SAN',    'COMPLETED', N'Khám thai'),
    ('V006', 'BN006', 'A008', 'KHOA_MAT',    'COMPLETED', N'Mờ mắt'),
    ('V007', 'BN007', 'A009', 'KHOA_TMH',    'COMPLETED', N'Đau họng'),
    ('V008', 'BN008', 'A010', 'KHOA_RHM',    'COMPLETED', N'Sâu răng'),
    ('V009', 'BN009', 'A011', 'KHOA_DALIEU', 'COMPLETED', N'Nổi mẩn đỏ'),
    ('V010', 'BN010', 'A012', 'KHOA_CC',     'COMPLETED', N'Khó thở'),
    ('V011', 'BN011', 'A001', 'KHOA_KHAM',   'COMPLETED', N'Chóng mặt'),
    ('V012', 'BN012', 'A004', 'KHOA_NOI',    'COMPLETED', N'Buồn nôn'),
    ('V013', 'BN013', 'A005', 'KHOA_NGOAI',  'COMPLETED', N'Chấn thương'),
    ('V014', 'BN014', 'A006', 'KHOA_NHI',    'COMPLETED', N'Ho khan'),
    ('V015', 'BN015', 'A001', 'KHOA_KHAM',   'PENDING',   N'Khám tổng quát'),
    ('V016', 'BN016', 'A016', 'KHOA_YHCT',   'COMPLETED', N'Đau mỏi vai gáy'),
    ('V017', 'BN017', 'A017', 'KHOA_GMHS',   'COMPLETED', N'Tư vấn tiền mê'),
    ('V018', 'BN018', 'A001', 'KHOA_KHAM',   'COMPLETED', N'Mệt mỏi'),
    ('V019', 'BN019', 'A019', 'KHOA_DD',     'COMPLETED', N'Suy nhược cơ thể'),
    ('V020', 'BN020', 'A020', 'KHOA_TH',     'COMPLETED', N'Nội soi kiểm tra');
END
GO

IF NOT EXISTS (SELECT 1 FROM VitalSign)
BEGIN
    INSERT INTO VitalSign (vitalId, visitId, bloodPressure, heartRate, temperature, weight) VALUES 
    ('VS01', 'V001', '120/80', 80,  37.0, 65.0), ('VS02', 'V002', '130/85', 85,  37.5, 70.0),
    ('VS03', 'V003', '110/70', 90,  36.8, 60.0), ('VS04', 'V004', '100/60', 100, 39.2, 25.0),
    ('VS05', 'V005', '115/75', 82,  37.1, 55.0), ('VS06', 'V006', '125/80', 78,  36.9, 68.0),
    ('VS07', 'V007', '120/80', 88,  38.0, 75.0), ('VS08', 'V008', '118/78', 80,  37.0, 50.0),
    ('VS09', 'V009', '122/82', 84,  37.2, 62.0), ('VS10', 'V010', '140/90', 110, 37.4, 80.0),
    ('VS11', 'V011', '110/75', 76,  36.8, 58.0), ('VS12', 'V012', '125/85', 86,  37.5, 72.0),
    ('VS13', 'V013', '130/80', 95,  37.1, 66.0), ('VS14', 'V014', '105/65', 92,  38.5, 30.0),
    ('VS15', 'V015', '120/80', 75,  36.9, 64.0), ('VS16', 'V016', '115/75', 79,  37.0, 59.0),
    ('VS17', 'V017', '125/80', 81,  37.1, 71.0), ('VS18', 'V018', '110/70', 74,  36.7, 54.0),
    ('VS19', 'V019', '100/60', 65,  36.5, 45.0), ('VS20', 'V020', '120/80', 82,  37.2, 69.0);
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

-- 2.3. Paraclinical & Pharmacy
IF NOT EXISTS (SELECT 1 FROM TechnicalService)
BEGIN
    INSERT INTO TechnicalService (serviceCode, serviceName, unitPrice) VALUES 
    ('S01', N'Xét nghiệm máu tổng quát',    150000), ('S02', N'Siêu âm ổ bụng',            200000),
    ('S03', N'Chụp X-Quang ngực',           180000), ('S04', N'Chụp MRI',                 2500000),
    ('S05', N'Nội soi dạ dày',              800000), ('S06', N'Xét nghiệm nước tiểu',       50000),
    ('S07', N'Điện tâm đồ (ECG)',           120000), ('S08', N'Đo loãng xương',            250000),
    ('S09', N'Siêu âm thai',               300000), ('S10', N'Chụp CT Scanner',          1500000),
    ('S11', N'Xét nghiệm chức năng gan',   200000), ('S12', N'Xét nghiệm chức năng thận', 200000),
    ('S13', N'Nội soi đại tràng',         1000000), ('S14', N'Đo nhãn áp',                80000),
    ('S15', N'Lấy cao răng',               150000), ('S16', N'Châm cứu',                 100000),
    ('S17', N'Đo chức năng hô hấp',       180000), ('S18', N'Xét nghiệm mỡ máu',        120000),
    ('S19', N'Tư vấn dinh dưỡng chuyên sâu', 200000), ('S20', N'Test vi khuẩn HP',      150000);
END
GO

IF NOT EXISTS (SELECT 1 FROM Medicine)
BEGIN
    INSERT INTO Medicine (medicineId, medicineName, unit, sellPrice, minStock) VALUES 
    ('M01', N'Paracetamol 500mg',  N'Viên', 2000,   1000), ('M02', N'Amoxicillin 250mg',  N'Viên',  5000,  500),
    ('M03', N'Ibuprofen 400mg',    N'Viên', 3000,    800), ('M04', N'Omeprazole 20mg',    N'Viên',  4000,  600),
    ('M05', N'Vitamin C 500mg',    N'Viên', 1500,   2000), ('M06', N'Loratadine 10mg',    N'Viên',  2500,  400),
    ('M07', N'Salbutamol 2mg',     N'Viên', 1000,    300), ('M08', N'Metformin 500mg',    N'Viên',  3500, 1000),
    ('M09', N'Losartan 50mg',      N'Viên', 4500,    700), ('M10', N'Aspirin 81mg',       N'Viên',  1200, 1500),
    ('M11', N'Diazepam 5mg',       N'Viên', 5500,    200), ('M12', N'Oresol',             N'Gói',   3000, 3000),
    ('M13', N'Berberin',           N'Lọ',  25000,    100), ('M14', N'Nước muối sinh lý',  N'Chai', 10000,  500),
    ('M15', N'Cồn y tế 70 độ',    N'Chai',15000,    200), ('M16', N'Cao dán giảm đau',   N'Miếng', 5000,  800),
    ('M17', N'Thuốc ho Bổ Phế',   N'Chai',35000,    150), ('M18', N'Sữa dinh dưỡng',     N'Hộp', 450000,   50),
    ('M19', N'Men vi sinh',        N'Ống',  8000,   1000), ('M20', N'Gaviscon',           N'Gói',   7000,  600);
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
    ('ORD_15', 'V002', 'S11', 'PENDING');
END
GO

IF NOT EXISTS (SELECT 1 FROM LabResult)
BEGIN
    INSERT INTO LabResult (resultId, orderId, performedByAccountId, indexName, value, unit) VALUES 
    ('RES_01', 'ORD_01', 'A002', N'Bạch cầu (WBC)',            '11.5',                    '10^9/L'),
    ('RES_02', 'ORD_01', 'A002', N'Hồng cầu (RBC)',            '4.2',                     '10^12/L'),
    ('RES_03', 'ORD_01', 'A002', N'Tiểu cầu (PLT)',            '250',                     '10^9/L'),
    ('RES_04', 'ORD_01', 'A002', N'Hemoglobin (Hb)',           '135',                     'g/L'),
    ('RES_05', 'ORD_02', 'A020', N'Kết luận Nội soi',          N'Viêm loét hang vị',      N'Văn bản'),
    ('RES_06', 'ORD_02', 'A020', N'Test HP',                   N'Dương tính (+)',          N'Chỉ số'),
    ('RES_07', 'ORD_03', 'A014', N'X-Quang Phổi',              N'Bóng tim to nhẹ',        N'Văn bản'),
    ('RES_08', 'ORD_04', 'A007', N'Tim thai',                  '140',                     'lần/phút'),
    ('RES_09', 'ORD_04', 'A007', N'Cân nặng thai nhi',         '3200',                    'gram'),
    ('RES_10', 'ORD_05', 'A001', N'Nhịp tim (ECG)',            '85',                      'bpm'),
    ('RES_11', 'ORD_06', 'A010', N'Tình trạng răng',           N'Nhiều mảng bám',         N'Văn bản'),
    ('RES_12', 'ORD_07', 'A014', N'CT Sọ não',                 N'Không phát hiện xuất huyết', N'Văn bản'),
    ('RES_13', 'ORD_08', 'A014', N'Siêu âm Gan',               N'Gan nhiễm mỡ độ 1',     N'Văn bản'),
    ('RES_14', 'ORD_09', 'A002', N'Glucose (Nước tiểu)',       'Negative',                'mmol/L'),
    ('RES_15', 'ORD_09', 'A002', N'Protein (Nước tiểu)',       'Trace',                   'g/L'),
    ('RES_16', 'ORD_10', 'A016', N'Phác đồ châm cứu',          N'Lưu kim 20 phút',        N'Văn bản'),
    ('RES_17', 'ORD_11', 'A001', N'FEV1',                      '2.5',                     'Lít'),
    ('RES_18', 'ORD_12', 'A019', N'Chỉ số BMI',                '17.5',                    'kg/m2'),
    ('RES_19', 'ORD_13', 'A020', N'Kết quả HP',                N'Âm tính (-)',            N'Chỉ số'),
    ('RES_20', 'ORD_14', 'A002', N'Bạch cầu (Nước tiểu)',      '500',                     'Cell/uL');
END
GO

IF NOT EXISTS (SELECT 1 FROM Prescription)
BEGIN
    INSERT INTO Prescription (prescriptionId, visitId, doctorAccountId, status) VALUES 
    ('PRES_01', 'V001', 'A001', 'COMPLETED'), ('PRES_02', 'V002', 'A004', 'COMPLETED'),
    ('PRES_03', 'V004', 'A006', 'COMPLETED'), ('PRES_04', 'V006', 'A008', 'COMPLETED'),
    ('PRES_05', 'V009', 'A011', 'COMPLETED'), ('PRES_06', 'V011', 'A001', 'COMPLETED'),
    ('PRES_07', 'V013', 'A005', 'COMPLETED'), ('PRES_08', 'V015', 'A001', 'PENDING'),
    ('PRES_09', 'V018', 'A001', 'COMPLETED'), ('PRES_10', 'V020', 'A020', 'COMPLETED');
END
GO

IF NOT EXISTS (SELECT 1 FROM PrescriptionDetail)
BEGIN
    INSERT INTO PrescriptionDetail (prescriptionDetailId, prescriptionId, medicineId, quantity, dosage) VALUES 
    ('PD_01', 'PRES_01', 'M01', 10, N'Sáng 1 viên, Tối 1 viên sau ăn'),
    ('PD_02', 'PRES_01', 'M05', 20, N'Sáng 1 viên hòa nước'),
    ('PD_03', 'PRES_02', 'M04', 14, N'Sáng 1 viên trước ăn 30 phút'),
    ('PD_04', 'PRES_02', 'M02', 20, N'Sáng 1 viên, Tối 1 viên'),
    ('PD_05', 'PRES_03', 'M01',  5, N'Uống nửa viên khi sốt > 38.5'),
    ('PD_06', 'PRES_03', 'M12', 10, N'Pha 1 gói với 200ml nước'),
    ('PD_07', 'PRES_04', 'M14',  2, N'Nhỏ mắt ngày 3 lần'),
    ('PD_08', 'PRES_05', 'M06', 10, N'Tối 1 viên trước khi ngủ'),
    ('PD_09', 'PRES_05', 'M05', 10, N'Sáng 1 viên'),
    ('PD_10', 'PRES_06', 'M11',  5, N'Tối 1 viên (Thuốc an thần)'),
    ('PD_11', 'PRES_07', 'M03', 15, N'Sáng 1 viên, Tối 1 viên giảm đau'),
    ('PD_12', 'PRES_07', 'M16',  5, N'Dán vùng đau ngày 1 lần'),
    ('PD_13', 'PRES_07', 'M15',  1, N'Rửa vết thương ngoài da'),
    ('PD_14', 'PRES_08', 'M05', 30, N'Ngày 1 viên tăng đề kháng'),
    ('PD_15', 'PRES_08', 'M19', 20, N'Ngày 2 ống sau ăn'),
    ('PD_16', 'PRES_09', 'M01', 10, N'Uống khi đau đầu'),
    ('PD_17', 'PRES_09', 'M18',  2, N'Uống bổ sung dinh dưỡng'),
    ('PD_18', 'PRES_10', 'M04', 28, N'Sáng 1 viên trước ăn'),
    ('PD_19', 'PRES_10', 'M20', 14, N'Uống 1 gói khi ợ nóng'),
    ('PD_20', 'PRES_10', 'M19', 14, N'Sáng 1 ống, Tối 1 ống');
END
GO

-- 2.4. Billing
IF NOT EXISTS (SELECT 1 FROM Invoice)
BEGIN
    INSERT INTO Invoice (invoiceId, visitId, patientId, paymentMethod, totalAmount, insuranceAmount, finalAmount, status) VALUES 
    ('INV_01', 'V001', 'BN001', 'CASH',     150000,  50000, 100000, 'PAID'),
    ('INV_02', 'V002', 'BN002', 'CARD',     800000, 150000, 650000, 'PAID'),
    ('INV_03', 'V003', 'BN003', 'TRANSFER', 180000,  80000, 100000, 'PAID'),
    ('INV_04', 'V004', 'BN004', 'CASH',      20000,      0,  20000, 'UNPAID'),
    ('INV_05', 'V005', 'BN005', 'CARD',     300000, 100000, 200000, 'PAID'),
    ('INV_06', 'V006', 'BN006', 'CASH',      12500,      0,  12500, 'PAID'),
    ('INV_07', 'V007', 'BN007', 'TRANSFER', 120000,      0, 120000, 'UNPAID'),
    ('INV_08', 'V008', 'BN008', 'CARD',     150000,  50000, 100000, 'PAID'),
    ('INV_09', 'V009', 'BN009', 'CASH',      56000,      0,  56000, 'PAID'),
    ('INV_10', 'V010', 'BN010', 'TRANSFER',1500000, 500000,1000000, 'UNPAID'),
    ('INV_11', 'V011', 'BN011', 'CASH',      15000,      0,  15000, 'PAID'),
    ('INV_12', 'V012', 'BN012', 'CARD',     200000, 100000, 100000, 'PAID'),
    ('INV_13', 'V013', 'BN013', 'TRANSFER', 100000,  50000,  50000, 'PAID'),
    ('INV_14', 'V014', 'BN014', 'CASH',      50000,      0,  50000, 'UNPAID'),
    ('INV_15', 'V015', 'BN015', 'CARD',      45000,      0,  45000, 'PAID'),
    ('INV_16', 'V016', 'BN016', 'CASH',     100000,  25000,  75000, 'PAID'),
    ('INV_17', 'V017', 'BN017', 'TRANSFER', 180000,      0, 180000, 'UNPAID'),
    ('INV_18', 'V018', 'BN018', 'CARD',      80000,      0,  80000, 'PAID'),
    ('INV_19', 'V019', 'BN019', 'CASH',     200000,  50000, 150000, 'PAID'),
    ('INV_20', 'V020', 'BN020', 'TRANSFER',1000000, 250000, 750000, 'PAID');
END
GO

IF NOT EXISTS (SELECT 1 FROM InvoiceDetail)
BEGIN
    INSERT INTO InvoiceDetail (detailId, invoiceId, itemType, itemName, quantity, unitPrice) VALUES 
    ('ID01', 'INV_01', 'SERVICE',  N'Xét nghiệm máu tổng quát', 1,  150000),
    ('ID02', 'INV_02', 'SERVICE',  N'Nội soi dạ dày',           1,  800000),
    ('ID03', 'INV_03', 'SERVICE',  N'Chụp X-Quang ngực',        1,  180000),
    ('ID04', 'INV_04', 'MEDICINE', N'Paracetamol 500mg',        10,   2000),
    ('ID05', 'INV_05', 'SERVICE',  N'Siêu âm thai',             1,  300000),
    ('ID06', 'INV_06', 'MEDICINE', N'Loratadine 10mg',           5,   2500),
    ('ID07', 'INV_07', 'SERVICE',  N'Điện tâm đồ (ECG)',        1,  120000),
    ('ID08', 'INV_08', 'SERVICE',  N'Lấy cao răng',             1,  150000),
    ('ID09', 'INV_09', 'MEDICINE', N'Omeprazole 20mg',          14,   4000),
    ('ID10', 'INV_10', 'SERVICE',  N'Chụp CT Scanner',          1, 1500000),
    ('ID11', 'INV_11', 'MEDICINE', N'Oresol',                    5,   3000),
    ('ID12', 'INV_12', 'SERVICE',  N'Siêu âm ổ bụng',           1,  200000),
    ('ID13', 'INV_13', 'MEDICINE', N'Amoxicillin 250mg',        20,   5000),
    ('ID14', 'INV_14', 'SERVICE',  N'Xét nghiệm nước tiểu',    1,   50000),
    ('ID15', 'INV_15', 'MEDICINE', N'Vitamin C 500mg',          30,   1500),
    ('ID16', 'INV_16', 'SERVICE',  N'Châm cứu',                 1,  100000),
    ('ID17', 'INV_17', 'SERVICE',  N'Đo chức năng hô hấp',     1,  180000),
    ('ID18', 'INV_18', 'MEDICINE', N'Men vi sinh',              10,   8000),
    ('ID19', 'INV_19', 'SERVICE',  N'Tư vấn dinh dưỡng chuyên sâu', 1, 200000),
    ('ID20', 'INV_20', 'SERVICE',  N'Nội soi đại tràng',        1, 1000000);
END
GO

PRINT 'Hospital_Integrated_DB initialized successfully.';
GO
