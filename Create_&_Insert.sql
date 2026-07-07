
-- ============================================================
-- TOLL PLAZA MANAGEMENT SYSTEM — DDL SCRIPT (CORRECTED)
-- Run this FIRST before inserts.sql
-- ============================================================

CREATE SCHEMA IF NOT EXISTS toll_management;
SET search_path TO toll_management;

-- ============================================================
-- Drop tables in reverse FK order (safe re-run)
-- ============================================================
DROP TABLE IF EXISTS Transaction_Rate    CASCADE;
DROP TABLE IF EXISTS Transaction_FASTag  CASCADE;
DROP TABLE IF EXISTS Transaction_Pass    CASCADE;
DROP TABLE IF EXISTS Operates            CASCADE;
DROP TABLE IF EXISTS Staff_Plaza         CASCADE;
DROP TABLE IF EXISTS Violation           CASCADE;
DROP TABLE IF EXISTS Transaction         CASCADE;
DROP TABLE IF EXISTS Monthly_Pass        CASCADE;
DROP TABLE IF EXISTS FASTag_Account      CASCADE;
DROP TABLE IF EXISTS Toll_Rate           CASCADE;
DROP TABLE IF EXISTS Staff               CASCADE;
DROP TABLE IF EXISTS Toll_Booth          CASCADE;
DROP TABLE IF EXISTS Vehicle             CASCADE;
DROP TABLE IF EXISTS Toll_Plaza          CASCADE;

-- ============================================================
-- 1. TOLL_PLAZA
-- ============================================================
CREATE TABLE Toll_Plaza (
    Plaza_ID         INT PRIMARY KEY,
    Plaza_Name       VARCHAR(100),
    Location         VARCHAR(100),
    Highway_Name     VARCHAR(100),
    Number_of_Lanes  INT,
    Contact_Number   VARCHAR(15)
);

-- ============================================================
-- 2. TOLL_BOOTH
-- ============================================================
CREATE TABLE Toll_Booth (
    Booth_ID      INT PRIMARY KEY,
    Booth_Number  INT,
    Status        VARCHAR(20),
    Plaza_ID      INT REFERENCES Toll_Plaza(Plaza_ID)
);

-- ============================================================
-- 3. STAFF
-- ============================================================
CREATE TABLE Staff (
    Staff_ID    INT PRIMARY KEY,
    Staff_Name  VARCHAR(100),
    Role        VARCHAR(50),
    Salary      DECIMAL(10,2),
    Booth_ID    INT REFERENCES Toll_Booth(Booth_ID),
    Shift_Start TIME,
    Shift_End   TIME
);

-- ============================================================
-- 4. VEHICLE
-- ============================================================
CREATE TABLE Vehicle (
    Vehicle_ID             INT PRIMARY KEY,
    Vehicle_Number         VARCHAR(20),
    Vehicle_Type           VARCHAR(50),
    Owner_Name             VARCHAR(100),
    Owner_Contact_Number   VARCHAR(15)
);

-- ============================================================
-- 5. FASTAG_ACCOUNT
-- ============================================================
CREATE TABLE FASTag_Account (
    Fastag_ID   INT PRIMARY KEY,
    Vehicle_ID  INT REFERENCES Vehicle(Vehicle_ID),
    Balance     DECIMAL(10,2),
    Bank_Name   VARCHAR(100)
);

-- ============================================================
-- 6. TOLL_RATE
-- ============================================================
CREATE TABLE Toll_Rate (
    Plaza_ID      INT,
    Vehicle_Type  VARCHAR(50),
    Toll_Amount   DECIMAL(10,2),
    PRIMARY KEY (Plaza_ID, Vehicle_Type),
    FOREIGN KEY (Plaza_ID) REFERENCES Toll_Plaza(Plaza_ID)
);

-- ============================================================
-- 7. MONTHLY_PASS
-- ============================================================
CREATE TABLE Monthly_Pass (
    Pass_ID     INT PRIMARY KEY,
    Vehicle_ID  INT REFERENCES Vehicle(Vehicle_ID),
    Plaza_ID    INT REFERENCES Toll_Plaza(Plaza_ID),
    Expiry_Date DATE,
    Pass_Fee    DECIMAL(10,2)
);

-- ============================================================
-- 8. TRANSACTION
-- ============================================================
CREATE TABLE Transaction (
    Transaction_ID    INT PRIMARY KEY,
    Vehicle_ID        INT REFERENCES Vehicle(Vehicle_ID),
    Booth_ID          INT REFERENCES Toll_Booth(Booth_ID),
    Transaction_Time  TIMESTAMP,
    Amount_Paid       DECIMAL(10,2),
    Payment_Mode      VARCHAR(50)
);

-- ============================================================
-- 9. VIOLATION
-- ============================================================
CREATE TABLE Violation (
    Violation_ID     INT PRIMARY KEY,
    Vehicle_ID       INT REFERENCES Vehicle(Vehicle_ID),
    Plaza_ID         INT REFERENCES Toll_Plaza(Plaza_ID),
    Violation_Type   VARCHAR(100),
    Violation_Date   DATE,
    Penalty_Amount   DECIMAL(10,2)
);

-- ============================================================
-- 10. STAFF_PLAZA (M:N junction)
-- ============================================================
CREATE TABLE Staff_Plaza (
    Staff_ID       INT,
    Plaza_ID       INT,
    Assigned_Date  DATE,
    PRIMARY KEY (Staff_ID, Plaza_ID),
    FOREIGN KEY (Staff_ID)  REFERENCES Staff(Staff_ID),
    FOREIGN KEY (Plaza_ID)  REFERENCES Toll_Plaza(Plaza_ID)
);

-- ============================================================
-- 11. OPERATES (Staff operates Booth with shift timing)
-- ============================================================
CREATE TABLE Operates (
    Staff_ID     INT,
    Booth_ID     INT,
    Shift_Start  TIMESTAMP,
    Shift_End    TIMESTAMP,
    PRIMARY KEY (Staff_ID, Booth_ID, Shift_Start),
    FOREIGN KEY (Staff_ID)  REFERENCES Staff(Staff_ID),
    FOREIGN KEY (Booth_ID)  REFERENCES Toll_Booth(Booth_ID)
);


-- ============================================================
-- TOLL PLAZA MANAGEMENT SYSTEM — SAMPLE DATA (INSERT SCRIPT)
-- Schema: toll_management
-- ============================================================


-- 1. TOLL_PLAZA

INSERT INTO Toll_Plaza (Plaza_ID, Plaza_Name, Location, Highway_Name, Number_of_Lanes, Contact_Number) VALUES
(1, 'Ahmedabad North Plaza',  'Ahmedabad, Gujarat',   'NH-48',  6, '9900011101'),
(2, 'Surat East Plaza',       'Surat, Gujarat',        'NH-53',  4, '9900011102'),
(3, 'Vadodara Central Plaza', 'Vadodara, Gujarat',     'NH-48',  8, '9900011103'),
(4, 'Rajkot West Plaza',      'Rajkot, Gujarat',       'NH-27',  4, '9900011104'),
(5, 'Gandhinagar Plaza',      'Gandhinagar, Gujarat',  'SH-71',  4, '9900011105');

-- ============================================================
-- 2. TOLL_BOOTH
-- ============================================================
INSERT INTO Toll_Booth (Booth_ID, Booth_Number, Status, Plaza_ID) VALUES
(101, 1, 'Active',    1),
(102, 2, 'Active',    1),
(103, 3, 'Inactive',  1),
(104, 1, 'Active',    2),
(105, 2, 'Active',    2),
(106, 1, 'Active',    3),
(107, 2, 'Active',    3),
(108, 3, 'Active',    3),
(109, 1, 'Active',    4),
(110, 1, 'Active',    5);

-- ============================================================
-- 3. STAFF
-- ============================================================
INSERT INTO Staff (Staff_ID, Staff_Name, Role, Salary, Booth_ID, Shift_Start, Shift_End) VALUES
(201, 'Ravi Sharma',    'Toll Collector',  22000.00, 101, '06:00:00', '14:00:00'),
(202, 'Priya Patel',    'Toll Collector',  22000.00, 101, '14:00:00', '22:00:00'),
(203, 'Arjun Mehta',    'Supervisor',      35000.00, 102, '06:00:00', '18:00:00'),
(204, 'Sunita Verma',   'Toll Collector',  22000.00, 104, '08:00:00', '16:00:00'),
(205, 'Deepak Joshi',   'Toll Collector',  22000.00, 105, '16:00:00', '00:00:00'),
(206, 'Kavya Nair',     'Supervisor',      35000.00, 106, '06:00:00', '18:00:00'),
(207, 'Ramesh Yadav',   'Toll Collector',  22000.00, 107, '06:00:00', '14:00:00'),
(208, 'Anita Singh',    'Toll Collector',  22000.00, 108, '14:00:00', '22:00:00'),
(209, 'Vikram Chauhan', 'Toll Collector',  22000.00, 109, '08:00:00', '16:00:00'),
(210, 'Neha Gupta',     'Supervisor',      35000.00, 110, '06:00:00', '18:00:00');

-- ============================================================
-- 4. STAFF_PLAZA (M:N — Staff assigned to plazas)
-- ============================================================
INSERT INTO Staff_Plaza (Staff_ID, Plaza_ID, Assigned_Date) VALUES
(201, 1, '2024-01-01'),
(202, 1, '2024-01-01'),
(203, 1, '2024-01-01'),
(203, 2, '2024-03-01'),  -- Supervisor covers two plazas
(204, 2, '2024-01-15'),
(205, 2, '2024-01-15'),
(206, 3, '2024-02-01'),
(207, 3, '2024-02-01'),
(208, 3, '2024-02-01'),
(209, 4, '2024-02-15'),
(210, 5, '2024-03-01'),
(210, 1, '2024-04-01');  -- Supervisor also covers Plaza 1

-- ============================================================
-- 5. VEHICLE
-- ============================================================
INSERT INTO Vehicle (Vehicle_ID, Vehicle_Number, Vehicle_Type, Owner_Name, Owner_Contact_Number) VALUES
(301, 'GJ01AB1234', 'Car',        'Amit Shah',       '9876500001'),
(302, 'GJ05CD5678', 'Truck',      'Rajesh Logistics', '9876500002'),
(303, 'GJ06EF9012', 'Motorcycle', 'Preethi Kumar',   '9876500003'),
(304, 'GJ01GH3456', 'Bus',        'City Transport',  '9876500004'),
(305, 'MH02IJ7890', 'Car',        'Sneha Patil',     '9876500005'),
(306, 'RJ14KL1122', 'Truck',      'Fast Freight Co', '9876500006'),
(307, 'GJ07MN3344', 'Car',        'Nikhil Desai',    '9876500007'),
(308, 'GJ09OP5566', 'SUV',        'Meera Iyer',      '9876500008'),
(309, 'DL01QR7788', 'Car',        'Rohan Kapoor',    '9876500009'),
(310, 'GJ01ST9900', 'Motorcycle', 'Farhan Sheikh',   '9876500010');

-- ============================================================
-- 6. FASTAG_ACCOUNT
-- ============================================================
INSERT INTO FASTag_Account (Fastag_ID, Vehicle_ID, Balance, Bank_Name) VALUES
(401, 301, 850.00,   'HDFC Bank'),
(402, 302, 3200.00,  'SBI'),
(403, 304, 5000.00,  'ICICI Bank'),
(404, 305, 120.00,   'Axis Bank'),   -- Low balance
(405, 307, 1500.00,  'Kotak Bank'),
(406, 308, 2200.00,  'HDFC Bank'),
(407, 309, 50.00,    'SBI'),         -- Very low balance
(408, 306, 4800.00,  'PNB');

-- ============================================================
-- 7. TOLL_RATE
-- ============================================================
INSERT INTO Toll_Rate (Plaza_ID, Vehicle_Type, Toll_Amount) VALUES
(1, 'Car',        65.00),
(1, 'Truck',     185.00),
(1, 'Bus',       155.00),
(1, 'Motorcycle', 30.00),
(1, 'SUV',        90.00),
(2, 'Car',        55.00),
(2, 'Truck',     160.00),
(2, 'Bus',       130.00),
(2, 'Motorcycle', 25.00),
(2, 'SUV',        75.00),
(3, 'Car',        70.00),
(3, 'Truck',     200.00),
(3, 'Bus',       165.00),
(3, 'Motorcycle', 35.00),
(3, 'SUV',        95.00),
(4, 'Car',        50.00),
(4, 'Truck',     145.00),
(4, 'Motorcycle', 20.00),
(5, 'Car',        45.00),
(5, 'SUV',        70.00),
(5, 'Motorcycle', 20.00);

-- ============================================================
-- 8. MONTHLY_PASS
-- ============================================================
INSERT INTO Monthly_Pass (Pass_ID, Vehicle_ID, Plaza_ID, Expiry_Date, Pass_Fee) VALUES
(501, 301, 1, '2026-04-30', 1200.00),
(502, 307, 1, '2026-05-31', 1200.00),
(503, 304, 2, '2026-03-31', 2800.00),  -- Expired
(504, 308, 3, '2026-06-30', 1600.00),
(505, 305, 1, '2026-04-15', 1200.00);  -- Expiring soon

-- ============================================================
-- 9. TRANSACTION
-- ============================================================
INSERT INTO Transaction (Transaction_ID, Vehicle_ID, Booth_ID, Transaction_Time, Amount_Paid, Payment_Mode) VALUES
(601, 301, 101, '2026-04-08 08:15:00', 0.00,   'Monthly Pass'),
(602, 302, 101, '2026-04-08 08:45:00', 185.00, 'FASTag'),
(603, 303, 102, '2026-04-08 09:10:00', 30.00,  'Cash'),
(604, 304, 104, '2026-04-08 10:00:00', 0.00,   'Monthly Pass'),
(605, 305, 101, '2026-04-08 10:30:00', 55.00,  'FASTag'),
(606, 306, 104, '2026-04-08 11:00:00', 160.00, 'FASTag'),
(607, 307, 102, '2026-04-08 11:45:00', 0.00,   'Monthly Pass'),
(608, 308, 106, '2026-04-08 12:00:00', 95.00,  'FASTag'),
(609, 309, 110, '2026-04-08 13:00:00', 45.00,  'Cash'),
(610, 310, 109, '2026-04-08 13:30:00', 20.00,  'Cash'),
(611, 301, 102, '2026-04-09 07:50:00', 0.00,   'Monthly Pass'),
(612, 302, 106, '2026-04-09 08:20:00', 200.00, 'FASTag'),
(613, 305, 104, '2026-04-09 09:05:00', 55.00,  'FASTag'),
(614, 308, 107, '2026-04-09 09:45:00', 95.00,  'FASTag'),
(615, 306, 108, '2026-04-09 10:15:00', 200.00, 'FASTag'),
(616, 303, 101, '2026-04-09 11:00:00', 30.00,  'Cash'),
(617, 309, 101, '2026-04-10 08:00:00', 65.00,  'Cash'),
(618, 310, 102, '2026-04-10 08:30:00', 30.00,  'Cash'),
(619, 307, 101, '2026-04-10 09:00:00', 0.00,   'Monthly Pass'),
(620, 302, 104, '2026-04-10 09:30:00', 160.00, 'FASTag');

-- ============================================================
-- 10. VIOLATION
-- ============================================================
INSERT INTO Violation (Violation_ID, Vehicle_ID, Plaza_ID, Violation_Type, Violation_Date, Penalty_Amount) VALUES
(701, 303, 1, 'No FASTag',         '2026-04-08', 500.00),
(702, 309, 5, 'Lane Violation',    '2026-04-08', 300.00),
(703, 306, 2, 'Overloading',       '2026-04-09', 2000.00),
(704, 310, 4, 'No FASTag',         '2026-04-09', 500.00),
(705, 302, 3, 'Speed Violation',   '2026-04-09', 1000.00),
(706, 309, 1, 'No FASTag',         '2026-04-10', 500.00),
(707, 305, 2, 'Expired Pass Used', '2026-04-10', 750.00);

-- ============================================================
-- 11. OPERATES
-- ============================================================
INSERT INTO Operates (Staff_ID, Booth_ID, Shift_Start, Shift_End) VALUES
(201, 101, '2026-04-08 06:00:00', '2026-04-08 14:00:00'),
(202, 101, '2026-04-08 14:00:00', '2026-04-08 22:00:00'),
(203, 102, '2026-04-08 06:00:00', '2026-04-08 18:00:00'),
(204, 104, '2026-04-08 08:00:00', '2026-04-08 16:00:00'),
(205, 105, '2026-04-08 16:00:00', '2026-04-09 00:00:00'),
(206, 106, '2026-04-08 06:00:00', '2026-04-08 18:00:00'),
(207, 107, '2026-04-08 06:00:00', '2026-04-08 14:00:00'),
(208, 108, '2026-04-08 14:00:00', '2026-04-08 22:00:00'),
(209, 109, '2026-04-08 08:00:00', '2026-04-08 16:00:00'),
(210, 110, '2026-04-08 06:00:00', '2026-04-08 18:00:00'),
(201, 101, '2026-04-09 06:00:00', '2026-04-09 14:00:00'),
(202, 101, '2026-04-09 14:00:00', '2026-04-09 22:00:00'),
(201, 101, '2026-04-10 06:00:00', '2026-04-10 14:00:00');

/*
Just to check whether it is correct or not

SET search_path TO toll_management;

SELECT 'Toll_Plaza'          AS table_name, COUNT(*) FROM Toll_Plaza        UNION ALL
SELECT 'Toll_Booth',                        COUNT(*) FROM Toll_Booth         UNION ALL
SELECT 'Staff',                             COUNT(*) FROM Staff              UNION ALL
SELECT 'Vehicle',                           COUNT(*) FROM Vehicle            UNION ALL
SELECT 'FASTag_Account',                    COUNT(*) FROM FASTag_Account     UNION ALL
SELECT 'Toll_Rate',                         COUNT(*) FROM Toll_Rate          UNION ALL
SELECT 'Monthly_Pass',                      COUNT(*) FROM Monthly_Pass       UNION ALL
SELECT 'Transaction',                       COUNT(*) FROM Transaction        UNION ALL
SELECT 'Violation',                         COUNT(*) FROM Violation          UNION ALL
SELECT 'Staff_Plaza',                       COUNT(*) FROM Staff_Plaza        UNION ALL
SELECT 'Operates',                          COUNT(*) FROM Operates           UNION ALL
SELECT 'Transaction_Pass',                  COUNT(*) FROM Transaction_Pass   UNION ALL
SELECT 'Transaction_FASTag',                COUNT(*) FROM Transaction_FASTag UNION ALL
SELECT 'Transaction_Rate',                  COUNT(*) FROM Transaction_Rate;

*/


