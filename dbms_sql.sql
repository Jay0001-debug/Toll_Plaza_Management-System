-- SCENARIO 1: REVENUE ANALYSIS

-- Q1.1: Total revenue collected per plaza (excluding free passes)
SELECT
    tp.Plaza_Name,
    tp.Highway_Name,+
    COUNT(t.Transaction_ID)  AS Total_Transactions,
    SUM(t.Amount_Paid)       AS Total_Revenue
FROM Transaction t
JOIN Toll_Booth tb ON t.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE t.Amount_Paid > 0
GROUP BY tp.Plaza_ID, tp.Plaza_Name, tp.Highway_Name
ORDER BY Total_Revenue DESC;

-- Q1.2: Day-wise revenue summary per plaza
SELECT
    DATE(t.Transaction_Time) AS Transaction_Date,
    tp.Plaza_Name,
    COUNT(t.Transaction_ID)  AS Transactions,
    SUM(t.Amount_Paid)       AS Daily_Revenue
FROM Transaction t
JOIN Toll_Booth tb ON t.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE t.Amount_Paid > 0
GROUP BY DATE(t.Transaction_Time), tp.Plaza_ID, tp.Plaza_Name
ORDER BY Transaction_Date DESC, Daily_Revenue DESC;

-- Q1.3: Revenue breakdown by vehicle type per plaza
SELECT
    tp.Plaza_Name,
    v.Vehicle_Type,
    COUNT(t.Transaction_ID) AS Transaction_Count,
    SUM(t.Amount_Paid)      AS Revenue
FROM Transaction t
JOIN Vehicle    v  ON t.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Booth tb ON t.Booth_ID   = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID  = tp.Plaza_ID
WHERE t.Amount_Paid > 0
GROUP BY tp.Plaza_ID, tp.Plaza_Name, v.Vehicle_Type
ORDER BY tp.Plaza_Name, Revenue DESC;

-- Q1.4: Revenue breakdown by payment mode per plaza
SELECT
    tp.Plaza_Name,
    t.Payment_Mode,
    COUNT(t.Transaction_ID) AS Usage_Count,
    SUM(t.Amount_Paid)      AS Revenue
FROM Transaction t
JOIN Toll_Booth tb ON t.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE t.Amount_Paid > 0
GROUP BY tp.Plaza_ID, tp.Plaza_Name, t.Payment_Mode
ORDER BY tp.Plaza_Name, Revenue DESC;

-- Q1.5: Which booth generates the most revenue per plaza
SELECT
    tp.Plaza_Name,
    tb.Booth_Number,
    COUNT(t.Transaction_ID) AS Transactions,
    SUM(t.Amount_Paid)      AS Booth_Revenue
FROM Transaction t
JOIN Toll_Booth tb ON t.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE t.Amount_Paid > 0
GROUP BY tp.Plaza_ID, tp.Plaza_Name, tb.Booth_ID, tb.Booth_Number
ORDER BY tp.Plaza_Name, Booth_Revenue DESC;

-- Q1.6: Hourly revenue trend to identify peak traffic hours
SELECT
    EXTRACT(HOUR FROM t.Transaction_Time) AS Hour_of_Day,
    COUNT(t.Transaction_ID)               AS Transaction_Count,
    SUM(t.Amount_Paid)                    AS Revenue
FROM Transaction t
WHERE t.Amount_Paid > 0
GROUP BY EXTRACT(HOUR FROM t.Transaction_Time)
ORDER BY Hour_of_Day;

-- Q1.7: Monthly pass fee revenue collected per plaza
SELECT
    tp.Plaza_Name,
    COUNT(mp.Pass_ID)   AS Passes_Sold,
    SUM(mp.Pass_Fee)    AS Pass_Revenue
FROM Monthly_Pass mp
JOIN Toll_Plaza tp ON mp.Plaza_ID = tp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY Pass_Revenue DESC;

-- Q1.8: Penalty revenue collected per plaza from violations
SELECT
    tp.Plaza_Name,
    COUNT(viol.Violation_ID) AS Total_Violations,
    SUM(viol.Penalty_Amount) AS Penalty_Revenue
FROM Violation viol
JOIN Toll_Plaza tp ON viol.Plaza_ID = tp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY Penalty_Revenue DESC;

-- Q1.9: Average toll amount per vehicle type across all plazas
SELECT
    v.Vehicle_Type,
    COUNT(t.Transaction_ID)      AS Total_Transactions,
    ROUND(AVG(t.Amount_Paid), 2) AS Avg_Toll_Paid,
    SUM(t.Amount_Paid)           AS Total_Revenue
FROM Transaction t
JOIN Vehicle v ON t.Vehicle_ID = v.Vehicle_ID
WHERE t.Amount_Paid > 0
GROUP BY v.Vehicle_Type
ORDER BY Total_Revenue DESC;

-- Q1.11: FASTag vs Cash revenue share overall
SELECT
    Payment_Mode,
    COUNT(*)                                                               AS Transactions,
    SUM(Amount_Paid)                                                       AS Revenue,
    ROUND(SUM(Amount_Paid) * 100.0 / SUM(SUM(Amount_Paid)) OVER (), 2)   AS Revenue_Percentage
FROM Transaction
WHERE Amount_Paid > 0
GROUP BY Payment_Mode
ORDER BY Revenue DESC;

-- Q1.12: Daily FASTag vs Cash revenue comparison
SELECT
    DATE(t.Transaction_Time) AS Date,
    SUM(CASE WHEN t.Payment_Mode = 'FASTag' THEN t.Amount_Paid ELSE 0 END) AS FASTag_Revenue,
    SUM(CASE WHEN t.Payment_Mode = 'Cash'   THEN t.Amount_Paid ELSE 0 END) AS Cash_Revenue,
    SUM(t.Amount_Paid)                                                      AS Total_Revenue
FROM Transaction t
GROUP BY DATE(t.Transaction_Time)
ORDER BY Date;


-- ============================================================
-- SCENARIO 2: VEHICLE & PASS MANAGEMENT
-- ============================================================

-- Q2.1: All active monthly pass holders per plaza
SELECT
    tp.Plaza_Name,
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    v.Owner_Contact_Number,
    mp.Expiry_Date,
    mp.Pass_Fee
FROM Monthly_Pass mp
JOIN Vehicle    v  ON mp.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Plaza tp ON mp.Plaza_ID   = tp.Plaza_ID
WHERE mp.Expiry_Date >= CURRENT_DATE
ORDER BY tp.Plaza_Name, mp.Expiry_Date;

-- Q2.2: Monthly passes expiring within the next 30 days (renewal alert)
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    v.Owner_Contact_Number,
    tp.Plaza_Name,
    mp.Expiry_Date,
    (mp.Expiry_Date - CURRENT_DATE) AS Days_Remaining
FROM Monthly_Pass mp
JOIN Vehicle    v  ON mp.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Plaza tp ON mp.Plaza_ID   = tp.Plaza_ID
WHERE mp.Expiry_Date BETWEEN CURRENT_DATE
                         AND (CURRENT_DATE + INTERVAL '30 days')
ORDER BY Days_Remaining ASC;

-- Q2.3: Expired monthly passes still linked to transactions
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    tp.Plaza_Name,
    mp.Expiry_Date,
    t.Transaction_Time,
    t.Payment_Mode
FROM Transaction_Pass tpass
JOIN Transaction  t   ON tpass.Transaction_ID = t.Transaction_ID
JOIN Monthly_Pass mp  ON tpass.Pass_ID        = mp.Pass_ID
JOIN Vehicle      v   ON t.Vehicle_ID         = v.Vehicle_ID
JOIN Toll_Booth   tb  ON t.Booth_ID           = tb.Booth_ID
JOIN Toll_Plaza   tp  ON tb.Plaza_ID          = tp.Plaza_ID
WHERE mp.Expiry_Date < DATE(t.Transaction_Time)
ORDER BY t.Transaction_Time DESC;

-- Q2.4: How many times each vehicle passed through each plaza
SELECT
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    tp.Plaza_Name,
    COUNT(t.Transaction_ID) AS Total_Visits
FROM Transaction t
JOIN Vehicle    v  ON t.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Booth tb ON t.Booth_ID   = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID  = tp.Plaza_ID
GROUP BY v.Vehicle_ID, v.Vehicle_Number, v.Vehicle_Type,
         v.Owner_Name, tp.Plaza_ID, tp.Plaza_Name
ORDER BY Total_Visits DESC;

-- Q2.5: Vehicles with no FASTag account (cash-only vehicles)
SELECT
    v.Vehicle_ID,
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    v.Owner_Contact_Number
FROM Vehicle v
WHERE v.Vehicle_ID NOT IN (
    SELECT Vehicle_ID FROM FASTag_Account
)
ORDER BY v.Vehicle_Type;

-- Q2.6: Vehicles that always pay full toll — potential monthly pass customers
SELECT
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    COUNT(t.Transaction_ID) AS Total_Trips,
    SUM(t.Amount_Paid)      AS Total_Paid
FROM Transaction t
JOIN Vehicle v ON t.Vehicle_ID = v.Vehicle_ID
WHERE t.Amount_Paid > 0
  AND v.Vehicle_ID NOT IN (SELECT Vehicle_ID FROM Monthly_Pass)
GROUP BY v.Vehicle_ID, v.Vehicle_Number, v.Vehicle_Type, v.Owner_Name
HAVING COUNT(t.Transaction_ID) >= 2
ORDER BY Total_Trips DESC;

-- Q2.7: Vehicles that used multiple plazas
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    COUNT(DISTINCT tb.Plaza_ID)              AS Plazas_Used,
    STRING_AGG(DISTINCT tp.Plaza_Name, ', ') AS Plaza_Names
FROM Transaction t
JOIN Vehicle    v  ON t.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Booth tb ON t.Booth_ID   = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID  = tp.Plaza_ID
GROUP BY v.Vehicle_ID, v.Vehicle_Number, v.Owner_Name
HAVING COUNT(DISTINCT tb.Plaza_ID) > 1
ORDER BY Plazas_Used DESC;

-- Q2.8: Truck traffic count per plaza (heavy vehicle monitoring)
SELECT
    tp.Plaza_Name,
    COUNT(t.Transaction_ID) AS Truck_Count,
    SUM(t.Amount_Paid)      AS Truck_Revenue
FROM Transaction t
JOIN Vehicle    v  ON t.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Booth tb ON t.Booth_ID   = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID  = tp.Plaza_ID
WHERE v.Vehicle_Type = 'Truck'
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY Truck_Count DESC;

-- Q2.9: Full transaction history of a specific vehicle
SELECT
    t.Transaction_ID,
    tp.Plaza_Name,
    tb.Booth_Number,
    t.Transaction_Time,
    t.Amount_Paid,
    t.Payment_Mode
FROM Transaction t
JOIN Toll_Booth tb ON t.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE t.Vehicle_ID = 302   -- Change Vehicle_ID as needed
ORDER BY t.Transaction_Time;

-- Q2.10: Vehicle type distribution across all transactions
SELECT
    v.Vehicle_Type,
    COUNT(t.Transaction_ID)                                                   AS Transaction_Count,
    ROUND(COUNT(t.Transaction_ID) * 100.0 / SUM(COUNT(t.Transaction_ID)) OVER(), 2) AS Percentage
FROM Transaction t
JOIN Vehicle v ON t.Vehicle_ID = v.Vehicle_ID
GROUP BY v.Vehicle_Type
ORDER BY Transaction_Count DESC;

-- Q2.11: Total toll paid by each vehicle (top spenders)
SELECT
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    COUNT(t.Transaction_ID) AS Trips,
    SUM(t.Amount_Paid)      AS Total_Toll_Paid
FROM Transaction t
JOIN Vehicle v ON t.Vehicle_ID = v.Vehicle_ID
WHERE t.Amount_Paid > 0
GROUP BY v.Vehicle_ID, v.Vehicle_Number, v.Vehicle_Type, v.Owner_Name
ORDER BY Total_Toll_Paid DESC;

-- Q2.12: Vehicles that passed through a specific plaza on a given date
SELECT
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    t.Transaction_Time,
    t.Amount_Paid,
    t.Payment_Mode,
    tb.Booth_Number
FROM Transaction t
JOIN Vehicle    v  ON t.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Booth tb ON t.Booth_ID   = tb.Booth_ID
WHERE tb.Plaza_ID = 1
  AND DATE(t.Transaction_Time) = '2026-04-08'
ORDER BY t.Transaction_Time;


-- ============================================================
-- SCENARIO 3: STAFF & BOOTH MANAGEMENT
-- ============================================================

-- Q3.1: All staff with their assigned booth and plaza details
SELECT
    tp.Plaza_Name,
    tb.Booth_Number,
    s.Staff_Name,
    s.Role,
    s.Salary,
    s.Shift_Start,
    s.Shift_End
FROM Staff s
JOIN Toll_Booth tb ON s.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
ORDER BY tp.Plaza_Name, tb.Booth_Number, s.Role;

-- Q3.2: Supervisors who cover multiple plazas
SELECT
    s.Staff_Name,
    s.Role,
    COUNT(sp.Plaza_ID)              AS Plazas_Covered,
    STRING_AGG(tp.Plaza_Name, ', ') AS Plaza_Names
FROM Staff_Plaza sp
JOIN Staff      s  ON sp.Staff_ID = s.Staff_ID
JOIN Toll_Plaza tp ON sp.Plaza_ID = tp.Plaza_ID
WHERE s.Role = 'Supervisor'
GROUP BY s.Staff_ID, s.Staff_Name, s.Role
HAVING COUNT(sp.Plaza_ID) > 1
ORDER BY Plazas_Covered DESC;

-- Q3.3: Staff operating each booth on a specific date
SELECT
    tp.Plaza_Name,
    tb.Booth_Number,
    s.Staff_Name,
    s.Role,
    o.Shift_Start,
    o.Shift_End
FROM Operates o
JOIN Staff      s  ON o.Staff_ID  = s.Staff_ID
JOIN Toll_Booth tb ON o.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE DATE(o.Shift_Start) = '2026-04-08'
ORDER BY tp.Plaza_Name, tb.Booth_Number, o.Shift_Start;

-- Q3.4: Total shifts worked and total hours per staff member
SELECT
    s.Staff_Name,
    s.Role,
    COUNT(o.Shift_Start) AS Shifts_Worked,
    SUM(EXTRACT(EPOCH FROM (o.Shift_End - o.Shift_Start)) / 3600)  AS Total_Hours
FROM Operates o
JOIN Staff s ON o.Staff_ID = s.Staff_ID
GROUP BY s.Staff_ID, s.Staff_Name, s.Role
ORDER BY Shifts_Worked DESC;

-- Q3.5: Booths that are currently inactive (maintenance check)
SELECT
    tp.Plaza_Name,
    tb.Booth_ID,
    tb.Booth_Number,
    tb.Status
FROM Toll_Booth tb
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE tb.Status = 'Inactive'
ORDER BY tp.Plaza_Name;

-- Q3.6: Booth-wise transaction count and revenue ranking
SELECT
    tp.Plaza_Name,
    tb.Booth_Number,
    tb.Status,
    COUNT(t.Transaction_ID) AS Transaction_Count,
    SUM(t.Amount_Paid)      AS Revenue_Generated
FROM Toll_Booth tb
JOIN Toll_Plaza tp  ON tb.Plaza_ID = tp.Plaza_ID
LEFT JOIN Transaction t ON t.Booth_ID = tb.Booth_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name, tb.Booth_ID, tb.Booth_Number, tb.Status
ORDER BY Revenue_Generated DESC NULLS LAST;

-- Q3.7: Monthly salary expenditure per plaza
SELECT
    tp.Plaza_Name,
    COUNT(s.Staff_ID)       AS Staff_Count,
    SUM(s.Salary)           AS Monthly_Salary_Expense,
    ROUND(AVG(s.Salary), 2) AS Avg_Salary
FROM Staff_Plaza sp
JOIN Staff      s  ON sp.Staff_ID = s.Staff_ID
JOIN Toll_Plaza tp ON sp.Plaza_ID = tp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY Monthly_Salary_Expense DESC;

-- Q3.8: Staff handling busiest booths (transactions during their shift)
SELECT
    s.Staff_Name,
    s.Role,
    tp.Plaza_Name,
    tb.Booth_Number,
    COUNT(t.Transaction_ID) AS Transactions_During_Shift
FROM Operates o
JOIN Staff      s  ON o.Staff_ID  = s.Staff_ID
JOIN Toll_Booth tb ON o.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
JOIN Transaction t ON t.Booth_ID  = tb.Booth_ID
               AND t.Transaction_Time BETWEEN o.Shift_Start AND o.Shift_End
GROUP BY s.Staff_ID, s.Staff_Name, s.Role, tp.Plaza_Name, tb.Booth_Number
ORDER BY Transactions_During_Shift DESC;

-- Q3.9: Active vs inactive booth count per plaza
SELECT
    tp.Plaza_Name,
    tp.Number_of_Lanes,
    COUNT(tb.Booth_ID)                                       AS Total_Booths,
    SUM(CASE WHEN tb.Status = 'Active'   THEN 1 ELSE 0 END) AS Active_Booths,
    SUM(CASE WHEN tb.Status = 'Inactive' THEN 1 ELSE 0 END) AS Inactive_Booths
FROM Toll_Plaza tp
LEFT JOIN Toll_Booth tb ON tp.Plaza_ID = tb.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name, tp.Number_of_Lanes
ORDER BY tp.Plaza_Name;

-- Q3.10: Understaffed plazas (less than 3 staff assigned)
SELECT
    tp.Plaza_Name,
    tp.Number_of_Lanes,
    COUNT(DISTINCT sp.Staff_ID) AS Staff_Assigned
FROM Toll_Plaza tp
LEFT JOIN Staff_Plaza sp ON tp.Plaza_ID = sp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name, tp.Number_of_Lanes
HAVING COUNT(DISTINCT sp.Staff_ID) < 3
ORDER BY Staff_Assigned ASC;

-- Q3.11: Staff assigned to more than one plaza
SELECT
    s.Staff_Name,
    s.Role,
    COUNT(sp.Plaza_ID)              AS Plaza_Count,
    STRING_AGG(tp.Plaza_Name, ', ') AS Assigned_Plazas
FROM Staff_Plaza sp
JOIN Staff      s  ON sp.Staff_ID = s.Staff_ID
JOIN Toll_Plaza tp ON sp.Plaza_ID = tp.Plaza_ID
GROUP BY s.Staff_ID, s.Staff_Name, s.Role
HAVING COUNT(sp.Plaza_ID) > 1
ORDER BY Plaza_Count DESC;

-- Q3.12: Contact directory of all toll plazas
SELECT
    Plaza_ID,
    Plaza_Name,
    Location,
    Highway_Name,
    Number_of_Lanes,
    Contact_Number
FROM Toll_Plaza
ORDER BY Highway_Name, Plaza_Name;


-- ============================================================
-- SCENARIO 4: FASTAG & PAYMENT TRACKING
-- ============================================================

-- Q4.1: FASTag accounts with low balance — recharge alert (below 200)
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    v.Owner_Contact_Number,
    fa.Bank_Name,
    fa.Balance
FROM FASTag_Account fa
JOIN Vehicle v ON fa.Vehicle_ID = v.Vehicle_ID
WHERE fa.Balance < 200.00
ORDER BY fa.Balance ASC;

-- Q4.2: FASTag transaction history with current balance context
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    fa.Bank_Name,
    fa.Balance               AS Current_Balance,
    t.Transaction_Time,
    t.Amount_Paid,
    tp.Plaza_Name
FROM Transaction_FASTag tf
JOIN Transaction    t  ON tf.Transaction_ID = t.Transaction_ID
JOIN FASTag_Account fa ON tf.Fastag_ID      = fa.Fastag_ID
JOIN Vehicle        v  ON fa.Vehicle_ID     = v.Vehicle_ID
JOIN Toll_Booth     tb ON t.Booth_ID        = tb.Booth_ID
JOIN Toll_Plaza     tp ON tb.Plaza_ID       = tp.Plaza_ID
ORDER BY v.Vehicle_Number, t.Transaction_Time;

-- Q4.3: Total amount deducted from each FASTag account
SELECT
    fa.Fastag_ID,
    v.Vehicle_Number,
    v.Owner_Name,
    fa.Bank_Name,
    fa.Balance               AS Remaining_Balance,
    SUM(t.Amount_Paid)       AS Total_Deducted,
    COUNT(t.Transaction_ID)  AS FASTag_Trips
FROM Transaction_FASTag tf
JOIN Transaction    t  ON tf.Transaction_ID = t.Transaction_ID
JOIN FASTag_Account fa ON tf.Fastag_ID      = fa.Fastag_ID
JOIN Vehicle        v  ON fa.Vehicle_ID     = v.Vehicle_ID
GROUP BY fa.Fastag_ID, v.Vehicle_Number, v.Owner_Name,
         fa.Bank_Name, fa.Balance
ORDER BY Total_Deducted DESC;

-- Q4.4: Bank-wise FASTag account distribution and total balance
SELECT
    fa.Bank_Name,
    COUNT(fa.Fastag_ID)       AS Account_Count,
    SUM(fa.Balance)           AS Total_Balance_Held,
    ROUND(AVG(fa.Balance), 2) AS Avg_Balance
FROM FASTag_Account fa
GROUP BY fa.Bank_Name
ORDER BY Account_Count DESC;

-- Q4.5: FASTag usage per plaza
SELECT
    tp.Plaza_Name,
    COUNT(tf.Transaction_ID) AS FASTag_Transactions,
    SUM(t.Amount_Paid)       AS FASTag_Revenue
FROM Transaction_FASTag tf
JOIN Transaction t  ON tf.Transaction_ID = t.Transaction_ID
JOIN Toll_Booth  tb ON t.Booth_ID        = tb.Booth_ID
JOIN Toll_Plaza  tp ON tb.Plaza_ID       = tp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY FASTag_Transactions DESC;

-- Q4.6: Vehicles with FASTag that still paid by Cash
--       (possible FASTag malfunction or wrong lane)
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    fa.Bank_Name,
    fa.Balance,
    t.Transaction_Time,
    t.Amount_Paid,
    tp.Plaza_Name
FROM Transaction t
JOIN Vehicle        v  ON t.Vehicle_ID = v.Vehicle_ID
JOIN FASTag_Account fa ON v.Vehicle_ID = fa.Vehicle_ID
JOIN Toll_Booth     tb ON t.Booth_ID   = tb.Booth_ID
JOIN Toll_Plaza     tp ON tb.Plaza_ID  = tp.Plaza_ID
WHERE t.Payment_Mode = 'Cash'
  AND t.Transaction_ID NOT IN (SELECT Transaction_ID FROM Transaction_FASTag)
ORDER BY t.Transaction_Time;

-- Q4.7: Top 5 most active FASTag accounts by number of trips
SELECT
    fa.Fastag_ID,
    v.Vehicle_Number,
    v.Owner_Name,
    fa.Bank_Name,
    COUNT(tf.Transaction_ID) AS Total_FASTag_Trips
FROM Transaction_FASTag tf
JOIN FASTag_Account fa ON tf.Fastag_ID  = fa.Fastag_ID
JOIN Vehicle        v  ON fa.Vehicle_ID = v.Vehicle_ID
GROUP BY fa.Fastag_ID, v.Vehicle_Number, v.Owner_Name, fa.Bank_Name
ORDER BY Total_FASTag_Trips DESC
LIMIT 5;

-- Q4.8: FASTag accounts that have never been used in any transaction
SELECT
    fa.Fastag_ID,
    v.Vehicle_Number,
    v.Owner_Name,
    fa.Bank_Name,
    fa.Balance
FROM FASTag_Account fa
JOIN Vehicle v ON fa.Vehicle_ID = v.Vehicle_ID
WHERE fa.Fastag_ID NOT IN (
    SELECT Fastag_ID FROM Transaction_FASTag
)
ORDER BY fa.Balance DESC;

-- Q4.9: Average FASTag deduction per trip by vehicle type
SELECT
    v.Vehicle_Type,
    COUNT(tf.Transaction_ID)     AS FASTag_Trips,
    ROUND(AVG(t.Amount_Paid), 2) AS Avg_Deduction
FROM Transaction_FASTag tf
JOIN Transaction t ON tf.Transaction_ID = t.Transaction_ID
JOIN Vehicle     v ON t.Vehicle_ID      = v.Vehicle_ID
GROUP BY v.Vehicle_Type
ORDER BY Avg_Deduction DESC;

-- Q4.10: Daily FASTag vs Cash transaction count comparison
SELECT
    DATE(t.Transaction_Time)                                            AS Date,
    SUM(CASE WHEN t.Payment_Mode = 'FASTag' THEN 1 ELSE 0 END)        AS FASTag_Count,
    SUM(CASE WHEN t.Payment_Mode = 'Cash'   THEN 1 ELSE 0 END)        AS Cash_Count,
    SUM(CASE WHEN t.Payment_Mode = 'FASTag' THEN t.Amount_Paid ELSE 0 END) AS FASTag_Revenue,
    SUM(CASE WHEN t.Payment_Mode = 'Cash'   THEN t.Amount_Paid ELSE 0 END) AS Cash_Revenue
FROM Transaction t
GROUP BY DATE(t.Transaction_Time)
ORDER BY Date;

-- Q4.11: FASTag penetration rate per plaza
--        (what % of paying transactions used FASTag)
SELECT
    tp.Plaza_Name,
    COUNT(t.Transaction_ID)                                                    AS Total_Paid_Transactions,
    SUM(CASE WHEN t.Payment_Mode = 'FASTag' THEN 1 ELSE 0 END)               AS FASTag_Transactions,
    ROUND(SUM(CASE WHEN t.Payment_Mode = 'FASTag' THEN 1 ELSE 0 END) * 100.0
          / COUNT(t.Transaction_ID), 2)                                        AS FASTag_Penetration_Pct
FROM Transaction t
JOIN Toll_Booth tb ON t.Booth_ID  = tb.Booth_ID
JOIN Toll_Plaza tp ON tb.Plaza_ID = tp.Plaza_ID
WHERE t.Amount_Paid > 0
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY FASTag_Penetration_Pct DESC;


-- ============================================================
-- SCENARIO 5: VIOLATION & PENALTY MANAGEMENT
-- ============================================================

-- Q5.1: All violations with full vehicle and plaza details
SELECT
    viol.Violation_ID,
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    v.Owner_Contact_Number,
    tp.Plaza_Name,
    viol.Violation_Type,
    viol.Violation_Date,
    viol.Penalty_Amount
FROM Violation viol
JOIN Vehicle    v  ON viol.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Plaza tp ON viol.Plaza_ID   = tp.Plaza_ID
ORDER BY viol.Violation_Date DESC;

-- Q5.2: Total penalties collected per plaza
SELECT
    tp.Plaza_Name,
    COUNT(viol.Violation_ID) AS Total_Violations,
    SUM(viol.Penalty_Amount) AS Total_Penalty_Collected
FROM Violation viol
JOIN Toll_Plaza tp ON viol.Plaza_ID = tp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY Total_Penalty_Collected DESC;

-- Q5.3: Most common violation types across all plazas
SELECT
    Violation_Type,
    COUNT(*)            AS Occurrence_Count,
    SUM(Penalty_Amount) AS Total_Penalty
FROM Violation
GROUP BY Violation_Type
ORDER BY Occurrence_Count DESC;

-- Q5.4: Repeat offenders — vehicles with more than one violation
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    v.Owner_Contact_Number,
    COUNT(viol.Violation_ID)              AS Violation_Count,
    SUM(viol.Penalty_Amount)              AS Total_Penalty,
    STRING_AGG(viol.Violation_Type, ', ') AS Violation_Types
FROM Violation viol
JOIN Vehicle v ON viol.Vehicle_ID = v.Vehicle_ID
GROUP BY v.Vehicle_ID, v.Vehicle_Number, v.Owner_Name, v.Owner_Contact_Number
HAVING COUNT(viol.Violation_ID) > 1
ORDER BY Violation_Count DESC;

-- Q5.5: Violations by vehicle type (which type violates most)
SELECT
    v.Vehicle_Type,
    COUNT(viol.Violation_ID) AS Violations,
    SUM(viol.Penalty_Amount) AS Total_Penalty
FROM Violation viol
JOIN Vehicle v ON viol.Vehicle_ID = v.Vehicle_ID
GROUP BY v.Vehicle_Type
ORDER BY Violations DESC;

-- Q5.6: Day-wise violation and penalty trend
SELECT
    viol.Violation_Date,
    COUNT(viol.Violation_ID) AS Daily_Violations,
    SUM(viol.Penalty_Amount) AS Daily_Penalty
FROM Violation viol
GROUP BY viol.Violation_Date
ORDER BY viol.Violation_Date DESC;

-- Q5.7: Vehicles with violations but no FASTag
--       (flagged for mandatory FASTag compliance)
SELECT
    v.Vehicle_Number,
    v.Vehicle_Type,
    v.Owner_Name,
    v.Owner_Contact_Number,
    COUNT(viol.Violation_ID) AS Violations
FROM Violation viol
JOIN Vehicle v ON viol.Vehicle_ID = v.Vehicle_ID
WHERE v.Vehicle_ID NOT IN (SELECT Vehicle_ID FROM FASTag_Account)
GROUP BY v.Vehicle_ID, v.Vehicle_Number, v.Vehicle_Type,
         v.Owner_Name, v.Owner_Contact_Number
ORDER BY Violations DESC;

-- Q5.8: Top 10 highest penalty amounts issued
SELECT
    viol.Violation_ID,
    v.Vehicle_Number,
    v.Owner_Name,
    tp.Plaza_Name,
    viol.Violation_Type,
    viol.Violation_Date,
    viol.Penalty_Amount
FROM Violation viol
JOIN Vehicle    v  ON viol.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Plaza tp ON viol.Plaza_ID   = tp.Plaza_ID
ORDER BY viol.Penalty_Amount DESC
LIMIT 10;

-- Q5.9: Plaza-wise violation type breakdown
SELECT
    tp.Plaza_Name,
    viol.Violation_Type,
    COUNT(*)            AS Count,
    SUM(Penalty_Amount) AS Total_Penalty
FROM Violation viol
JOIN Toll_Plaza tp ON viol.Plaza_ID = tp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name, viol.Violation_Type
ORDER BY tp.Plaza_Name, Count DESC;

-- Q5.10: Vehicles that committed a violation on the same day
--        as their toll transaction at that plaza
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    tp.Plaza_Name,
    viol.Violation_Type,
    viol.Violation_Date,
    viol.Penalty_Amount,
    t.Transaction_Time,
    t.Amount_Paid
FROM Violation viol
JOIN Vehicle     v  ON viol.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Plaza  tp ON viol.Plaza_ID   = tp.Plaza_ID
JOIN Transaction t  ON t.Vehicle_ID    = viol.Vehicle_ID
JOIN Toll_Booth  tb ON t.Booth_ID      = tb.Booth_ID
                   AND tb.Plaza_ID     = viol.Plaza_ID
WHERE DATE(t.Transaction_Time) = viol.Violation_Date
ORDER BY viol.Violation_Date, v.Vehicle_Number;

-- Q5.11: Vehicles with violations that never returned to that plaza
--        (possible penalty evaders)
SELECT
    v.Vehicle_Number,
    v.Owner_Name,
    v.Owner_Contact_Number,
    tp.Plaza_Name,
    viol.Violation_Type,
    viol.Violation_Date,
    viol.Penalty_Amount
FROM Violation viol
JOIN Vehicle    v  ON viol.Vehicle_ID = v.Vehicle_ID
JOIN Toll_Plaza tp ON viol.Plaza_ID   = tp.Plaza_ID
WHERE NOT EXISTS (
    SELECT 1
    FROM Transaction t
    JOIN Toll_Booth tb ON t.Booth_ID = tb.Booth_ID
    WHERE t.Vehicle_ID  = viol.Vehicle_ID
      AND tb.Plaza_ID   = viol.Plaza_ID
      AND DATE(t.Transaction_Time) > viol.Violation_Date
)
ORDER BY viol.Violation_Date;

-- Q5.12: Monthly violation summary
SELECT
    TO_CHAR(viol.Violation_Date, 'YYYY-MM') AS Month,
    COUNT(viol.Violation_ID)                AS Total_Violations,
    SUM(viol.Penalty_Amount)                AS Penalty_Revenue
FROM Violation viol
GROUP BY TO_CHAR(viol.Violation_Date, 'YYYY-MM')
ORDER BY Month DESC;