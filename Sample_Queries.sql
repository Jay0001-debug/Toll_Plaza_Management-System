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

-- Q3.2: Booth-wise transaction count and revenue ranking
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

-- ============================================================
-- SCENARIO 4: FASTAG & PAYMENT TRACKING
-- ============================================================

-- Q4.1: Bank-wise FASTag account distribution and total balance
SELECT
    fa.Bank_Name,
    COUNT(fa.Fastag_ID)       AS Account_Count,
    SUM(fa.Balance)           AS Total_Balance_Held,
    ROUND(AVG(fa.Balance), 2) AS Avg_Balance
FROM FASTag_Account fa
GROUP BY fa.Bank_Name
ORDER BY Account_Count DESC;

-- Q4.2: Top 5 most active FASTag accounts by number of trips
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


-- ============================================================
-- SCENARIO 5: VIOLATION & PENALTY MANAGEMENT
-- ============================================================


-- Q5.1: Top 10 highest penalty amounts issued
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


-- Q5.2: Total penalties collected per plaza
SELECT
    tp.Plaza_Name,
    COUNT(viol.Violation_ID) AS Total_Violations,
    SUM(viol.Penalty_Amount) AS Total_Penalty_Collected
FROM Violation viol
JOIN Toll_Plaza tp ON viol.Plaza_ID = tp.Plaza_ID
GROUP BY tp.Plaza_ID, tp.Plaza_Name
ORDER BY Total_Penalty_Collected DESC;

