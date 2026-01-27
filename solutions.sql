/*----------------------------------------------------
Scott Peters
Solutions for Advanced SQL Puzzles
https://advancedsqlpuzzles.com
Last Updated: 01/23/2026
PostgreSQL

*/----------------------------------------------------

/*----------------------------------------------------
Answer to Puzzle #1
Shopping Carts
*/----------------------------------------------------

DROP TABLE IF EXISTS Cart1;
DROP TABLE IF EXISTS Cart2;

CREATE TABLE Cart1
(
Item  VARCHAR(100) PRIMARY KEY
);

CREATE TABLE Cart2
(
Item  VARCHAR(100) PRIMARY KEY
);

INSERT INTO Cart1 (Item) VALUES
('Sugar'),('Bread'),('Juice'),('Soda'),('Flour');

INSERT INTO Cart2 (Item) VALUES
('Sugar'),('Bread'),('Butter'),('Cheese'),('Fruit');

--Solution 1
--FULL OUTER JOIN
SELECT  a.Item AS ItemCart1,
        b.Item AS ItemCart2
FROM    Cart1 a FULL OUTER JOIN
        Cart2 b ON a.Item = b.Item;

--Solution 2
--LEFT JOIN, UNION and RIGHT JOIN
SELECT  a.Item AS Item1,
        b.Item AS Item2
FROM    Cart1 a
        LEFT JOIN Cart2 b ON a.Item = b.Item
UNION
SELECT  a.Item AS Item1,
        b.Item AS Item2
FROM    Cart1 a
        RIGHT JOIN Cart2 b ON a.Item = b.Item;

--Solution 3
--This solution does not use a FULL OUTER JOIN
SELECT  a.Item AS Item1,
        b.Item AS Item2
FROM    Cart1 a INNER JOIN
        Cart2 b ON a.Item = b.Item
UNION
SELECT  a.Item AS Item1,
        NULL AS Item2
FROM    Cart1 a
WHERE   a.Item NOT IN (SELECT b.Item FROM Cart2 b)
UNION
SELECT  NULL AS Item1,
        b.Item AS Item2
FROM    Cart2 b
WHERE b.Item NOT IN (SELECT a.Item FROM Cart1 a)
ORDER BY 1,2;

/*----------------------------------------------------
Answer to Puzzle #2
Managers and Employees
*/----------------------------------------------------

DROP TABLE IF EXISTS Employees;

CREATE TABLE Employees
(
EmployeeID  INTEGER PRIMARY KEY,
ManagerID   INTEGER NULL,
JobTitle    VARCHAR(100) NOT NULL
);

INSERT INTO Employees (EmployeeID, ManagerID, JobTitle) VALUES
(1001,NULL,'CEO'),(2002,1001,'Director'),
(3003,1001,'Office Manager'),(4004,2002,'Engineer'),
(5005,2002,'Engineer'),(6006,2002,'Engineer');

--Recursion
WITH RECURSIVE cte_Recursion AS
(
SELECT  EmployeeID, ManagerID, JobTitle, 0 AS Depth
FROM    Employees a
WHERE   ManagerID IS NULL
UNION ALL
SELECT  b.EmployeeID, b.ManagerID, b.JobTitle, a.Depth + 1 AS Depth
FROM    cte_Recursion a INNER JOIN
        Employees b ON a.EmployeeID = b.ManagerID
)
SELECT  EmployeeID,
        ManagerID,
        JobTitle,
        Depth
FROM    cte_Recursion;

/*----------------------------------------------------
Answer to Puzzle #3
Fiscal Year Table Constraints
*/----------------------------------------------------

DROP TABLE IF EXISTS EmployeePayRecords;

CREATE TABLE EmployeePayRecords
(
EmployeeID  INTEGER NOT NULL,
FiscalYear  INTEGER NOT NULL,
StartDate   DATE NOT NULL,
EndDate     DATE NOT NULL,
PayRate     DECIMAL(19,4) NOT NULL,
PRIMARY KEY (EmployeeID, FiscalYear),
CONSTRAINT Check_Year_StartDate CHECK (FiscalYear = EXTRACT(YEAR FROM StartDate)),
CONSTRAINT Check_Month_StartDate CHECK (EXTRACT(MONTH FROM StartDate) = 1),
CONSTRAINT Check_Day_StartDate CHECK (EXTRACT(DAY FROM StartDate) = 1),
CONSTRAINT Check_Year_EndDate CHECK (FiscalYear = EXTRACT(YEAR FROM EndDate)),
CONSTRAINT Check_Month_EndDate CHECK (EXTRACT(MONTH FROM EndDate) = 12),
CONSTRAINT Check_Day_EndDate CHECK (EXTRACT(DAY FROM EndDate) = 31),
CONSTRAINT Check_Payrate CHECK (PayRate > 0)
);

/*----------------------------------------------------
Answer to Puzzle #4
Two Predicates
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders
(
CustomerID     INTEGER,
OrderID        INTEGER,
DeliveryState  VARCHAR(100) NOT NULL,
Amount         DECIMAL(19,4) NOT NULL,
PRIMARY KEY (CustomerID, OrderID)
);

INSERT INTO Orders (CustomerID, OrderID, DeliveryState, Amount) VALUES
(1001,1,'CA',340),(1001,2,'TX',950),(1001,3,'TX',670),
(1001,4,'TX',860),(2002,5,'WA',320),(3003,6,'CA',650),
(3003,7,'CA',830),(4004,8,'TX',120);

--Solution 1
--INNER JOIN
WITH cte_CA AS
(
SELECT  DISTINCT CustomerID
FROM    Orders
WHERE   DeliveryState = 'CA'
)
SELECT  b.CustomerID, b.OrderID, b.DeliveryState, b.Amount
FROM    cte_CA a INNER JOIN
        Orders b ON a.CustomerID = B.CustomerID
WHERE   b.DeliveryState = 'TX';

--Solution 2
--IN
WITH cte_CA AS
(
SELECT  CustomerID
FROM    Orders
WHERE   DeliveryState = 'CA'
)
SELECT  CustomerID,
        OrderID,
        DeliveryState,
        Amount
FROM    Orders
WHERE   DeliveryState = 'TX' AND
        CustomerID IN (SELECT b.CustomerID FROM cte_CA b);

--Solution 3
--COUNT
WITH cte_distinct AS
(
SELECT DISTINCT CustomerID, DeliveryState
FROM   Orders
WHERE  DeliveryState IN ('CA','TX')
)
SELECT CustomerID
FROM   cte_distinct
GROUP BY CustomerID
HAVING COUNT(*) = 2;

/*----------------------------------------------------
Answer to Puzzle #5
Phone Directory
*/----------------------------------------------------

DROP TABLE IF EXISTS PhoneDirectory;

CREATE TABLE PhoneDirectory
(
CustomerID   INTEGER,
Type         VARCHAR(100),
PhoneNumber  VARCHAR(12) NOT NULL,
PRIMARY KEY (CustomerID, Type)
);

INSERT INTO PhoneDirectory (CustomerID, Type, PhoneNumber) VALUES
(1001,'Cellular','555-897-5421'),
(1001,'Work','555-897-6542'),
(1001,'Home','555-698-9874'),
(2002,'Cellular','555-963-6544'),
(2002,'Work','555-812-9856'),
(3003,'Cellular','555-987-6541');

--Solution 1
--PostgreSQL crosstab (requires tablefunc extension) or CASE/MAX
--Using MAX and CASE (most portable)
SELECT  CustomerID,
        MAX(CASE Type WHEN 'Cellular' THEN PhoneNumber END) AS Cellular,
        MAX(CASE Type WHEN 'Work' THEN PhoneNumber END) AS Work,
        MAX(CASE Type WHEN 'Home' THEN PhoneNumber END) AS Home
FROM    PhoneDirectory
GROUP BY CustomerID;

--Solution 2
--OUTER JOIN
WITH cte_Cellular AS
(
SELECT  CustomerID, PhoneNumber AS Cellular
FROM    PhoneDirectory
WHERE   Type = 'Cellular'
),
cte_Work AS
(
SELECT  CustomerID, PhoneNumber AS Work
FROM    PhoneDirectory
WHERE   Type = 'Work'
),
cte_Home AS
(
SELECT  CustomerID, PhoneNumber AS Home
FROM    PhoneDirectory
WHERE   Type = 'Home'
)
SELECT  a.CustomerID,
        b.Cellular,
        c.Work,
        d.Home
FROM    (SELECT DISTINCT CustomerID FROM PhoneDirectory) a LEFT OUTER JOIN
        cte_Cellular b ON a.CustomerID = b.CustomerID LEFT OUTER JOIN
        cte_Work c ON a.CustomerID = c.CustomerID LEFT OUTER JOIN
        cte_Home d ON a.CustomerID = d.CustomerID;

/*----------------------------------------------------
Answer to Puzzle #6
Workflow Steps
*/----------------------------------------------------

DROP TABLE IF EXISTS WorkflowSteps;

CREATE TABLE WorkflowSteps
(
Workflow        VARCHAR(100),
StepNumber      INTEGER,
CompletionDate  DATE NULL,
PRIMARY KEY (Workflow, StepNumber)
);

INSERT INTO WorkflowSteps (Workflow, StepNumber, CompletionDate) VALUES
('Alpha',1,'2018-07-02'),('Alpha',2,'2018-07-02'),('Alpha',3,'2018-07-01'),
('Bravo',1,'2018-06-25'),('Bravo',2,NULL),('Bravo',3,'2018-06-27'),
('Charlie',1,NULL),('Charlie',2,'2018-07-01');

--Solution 1
--NULL operators
WITH cte_NotNull AS
(
SELECT  DISTINCT
        Workflow
FROM    WorkflowSteps
WHERE   CompletionDate IS NOT NULL
),
cte_Null AS
(
SELECT  Workflow
FROM    WorkflowSteps
WHERE   CompletionDate IS NULL
)
SELECT  Workflow
FROM    cte_NotNull
WHERE   Workflow IN (SELECT Workflow FROM cte_Null);

--Solution 2
--HAVING clause and COUNT functions
SELECT  Workflow
FROM    WorkflowSteps
GROUP BY Workflow
HAVING  COUNT(*) <> COUNT(CompletionDate);

--Solution 3
--HAVING clause with MAX function
SELECT  Workflow
FROM    WorkflowSteps
GROUP BY Workflow
HAVING  MAX(CASE WHEN CompletionDate IS NULL THEN 1 ELSE 0 END) = 1;

/*----------------------------------------------------
Answer to Puzzle #7
Mission to Mars
*/----------------------------------------------------

DROP TABLE IF EXISTS Candidates;
DROP TABLE IF EXISTS Requirements;

CREATE TABLE Candidates
(
CandidateID  INTEGER,
Occupation   VARCHAR(100),
PRIMARY KEY (CandidateID, Occupation)
);

INSERT INTO Candidates (CandidateID, Occupation) VALUES
(1001,'Geologist'),(1001,'Astrogator'),(1001,'Biochemist'),
(1001,'Technician'),(2002,'Surgeon'),(2002,'Machinist'),(2002,'Geologist'),
(3003,'Geologist'),(3003,'Astrogator'),(4004,'Selenologist');

CREATE TABLE Requirements
(
Requirement  VARCHAR(100) PRIMARY KEY
);

INSERT INTO Requirements (Requirement) VALUES
('Geologist'),('Astrogator'),('Technician');

SELECT  CandidateID
FROM    Candidates
WHERE   Occupation IN (SELECT Requirement FROM Requirements)
GROUP BY CandidateID
HAVING COUNT(*) = (SELECT COUNT(*) FROM Requirements);

/*----------------------------------------------------
Answer to Puzzle #8
Workflow Cases
*/----------------------------------------------------

DROP TABLE IF EXISTS WorkflowCases;

CREATE TABLE WorkflowCases
(
Workflow  VARCHAR(100) PRIMARY KEY,
Case1     INTEGER NOT NULL DEFAULT 0,
Case2     INTEGER NOT NULL DEFAULT 0,
Case3     INTEGER NOT NULL DEFAULT 0
);

INSERT INTO WorkflowCases (Workflow, Case1, Case2, Case3) VALUES
('Alpha',0,0,0),('Bravo',0,1,1),('Charlie',1,0,0),('Delta',0,0,0);

--Solution 1
--Add each column
SELECT  Workflow,
        Case1 + Case2 + Case3 AS PassFail
FROM    WorkflowCases;

--Solution 2
--UNPIVOT using LATERAL
WITH cte_PassFail AS
(
SELECT  Workflow, CaseNumber, PassFail
FROM    WorkflowCases,
        LATERAL (VALUES ('Case1', Case1), ('Case2', Case2), ('Case3', Case3)) AS t(CaseNumber, PassFail)
)
SELECT  Workflow,
        SUM(PassFail) AS PassFail
FROM    cte_PassFail
GROUP BY Workflow
ORDER BY 1;

/*----------------------------------------------------
Answer to Puzzle #9
Matching Sets
*/----------------------------------------------------

DROP TABLE IF EXISTS Employees;

CREATE TABLE Employees
(
EmployeeID  INTEGER,
License     VARCHAR(100),
PRIMARY KEY (EmployeeID, License)
);

INSERT INTO Employees (EmployeeID, License) VALUES
(1001,'Class A'),(1001,'Class B'),(1001,'Class C'),
(2002,'Class A'),(2002,'Class B'),(2002,'Class C'),
(3003,'Class A'),(3003,'Class D'),
(4004,'Class A'),(4004,'Class B'),(4004,'Class D'),
(5005,'Class A'),(5005,'Class B'),(5005,'Class D');

WITH cte_Count AS
(
SELECT  EmployeeID,
        COUNT(*) AS LicenseCount
FROM    Employees
GROUP BY EmployeeID
),
cte_CountWindow AS
(
SELECT  a.EmployeeID AS EmployeeID_A,
        b.EmployeeID AS EmployeeID_B,
        COUNT(*) OVER (PARTITION BY a.EmployeeID, b.EmployeeID) AS CountWindow
FROM    Employees a CROSS JOIN
        Employees b
WHERE   a.EmployeeID <> b.EmployeeID and a.License = b.License
)
SELECT  DISTINCT
        a.EmployeeID_A,
        a.EmployeeID_B,
        a.CountWindow AS LicenseCount
FROM    cte_CountWindow a INNER JOIN
        cte_Count b ON a.CountWindow = b.LicenseCount AND a.EmployeeID_A = b.EmployeeID INNER JOIN
        cte_Count c ON a.CountWindow = c.LicenseCount AND a.EmployeeID_B = c.EmployeeID;

/*----------------------------------------------------
Answer to Puzzle #10
Mean, Median, Mode, and Range
*/----------------------------------------------------

DROP TABLE IF EXISTS SampleData;

CREATE TABLE SampleData
(
IntegerValue  INTEGER NOT NULL
);

INSERT INTO SampleData (IntegerValue) VALUES
(5),(6),(10),(10),(13),(14),(17),(20),(81),(90),(76);

--Median using PERCENTILE_CONT
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY IntegerValue) AS Median
FROM SampleData;

--Mean and Range
SELECT  AVG(IntegerValue) AS Mean,
        MAX(IntegerValue) - MIN(IntegerValue) AS Range
FROM    SampleData;

--Mode
SELECT  IntegerValue AS Mode,
        COUNT(*) AS ModeCount
FROM    SampleData
GROUP BY IntegerValue
ORDER BY ModeCount DESC
LIMIT 1;

/*----------------------------------------------------
Answer to Puzzle #11
Permutations
*/----------------------------------------------------

DROP TABLE IF EXISTS TestCases;

CREATE TABLE TestCases
(
TestCase  VARCHAR(1) PRIMARY KEY
);

INSERT INTO TestCases (TestCase) VALUES
('A'),('B'),('C');

--Recursion
WITH RECURSIVE cte_Permutations (Permutation, Id, Depth) AS
(
SELECT  TestCase::TEXT,
        TestCase || ';',
        1 AS Depth
FROM    TestCases
UNION ALL
SELECT  a.Permutation || ',' || b.TestCase,
        a.Id || b.TestCase || ';',
        a.Depth + 1
FROM    cte_Permutations a,
        TestCases b
WHERE   a.Depth < (SELECT COUNT(*) FROM TestCases) AND
        a.Id NOT LIKE '%' || b.TestCase || ';%'
)
SELECT  Permutation
FROM    cte_Permutations
WHERE   Depth = (SELECT COUNT(*) FROM TestCases);

/*----------------------------------------------------
Answer to Puzzle #12
Average Days
*/----------------------------------------------------

DROP TABLE IF EXISTS ProcessLog;

CREATE TABLE ProcessLog
(
Workflow       VARCHAR(100),
ExecutionDate  DATE,
PRIMARY KEY (Workflow, ExecutionDate)
);

INSERT INTO ProcessLog (Workflow, ExecutionDate) VALUES
('Alpha','2018-06-01'),('Alpha','2018-06-14'),('Alpha','2018-06-15'),
('Bravo','2018-06-01'),('Bravo','2018-06-02'),('Bravo','2018-06-19'),
('Charlie','2018-06-01'),('Charlie','2018-06-15'),('Charlie','2018-06-30');

WITH cte_DayDiff AS
(
SELECT  Workflow,
        ExecutionDate - LAG(ExecutionDate) OVER (PARTITION BY Workflow ORDER BY ExecutionDate) AS DateDifference
FROM    ProcessLog
)
SELECT  Workflow,
        AVG(DateDifference) AS AvgDays
FROM    cte_DayDiff
WHERE   DateDifference IS NOT NULL
GROUP BY Workflow;

/*----------------------------------------------------
Answer to Puzzle #13
Inventory Tracking
*/----------------------------------------------------

DROP TABLE IF EXISTS Inventory;

CREATE TABLE Inventory
(
InventoryDate       DATE PRIMARY KEY,
QuantityAdjustment  INTEGER NOT NULL
);

INSERT INTO Inventory (InventoryDate, QuantityAdjustment) VALUES
('2018-07-01',100),('2018-07-02',75),('2018-07-03',-150),
('2018-07-04',50),('2018-07-05',-100);

SELECT  InventoryDate,
        QuantityAdjustment,
        SUM(QuantityAdjustment) OVER (ORDER BY InventoryDate) AS RunningTotal
FROM    Inventory;

/*----------------------------------------------------
Answer to Puzzle #14
Indeterminate Process Log
*/----------------------------------------------------

DROP TABLE IF EXISTS ProcessLog;

CREATE TABLE ProcessLog
(
Workflow    VARCHAR(100),
StepNumber  INTEGER,
RunStatus   VARCHAR(100) NOT NULL,
PRIMARY KEY (Workflow, StepNumber)
);

INSERT INTO ProcessLog (Workflow, StepNumber, RunStatus) VALUES
('Alpha',1,'Error'),('Alpha',2,'Complete'),('Alpha',3,'Running'),
('Bravo',1,'Complete'),('Bravo',2,'Complete'),
('Charlie',1,'Running'),('Charlie',2,'Running'),
('Delta',1,'Error'),('Delta',2,'Error'),
('Echo',1,'Running'),('Echo',2,'Complete');

--Solution 1
--MIN and MAX
WITH cte_MinMax AS
(
SELECT  Workflow,
        MIN(RunStatus) AS MinStatus,
        MAX(RunStatus) AS MaxStatus
FROM    ProcessLog
GROUP BY Workflow
),
cte_Error AS
(
SELECT  Workflow,
        MAX(CASE RunStatus WHEN 'Error' THEN RunStatus END) AS ErrorState,
        MAX(CASE RunStatus WHEN 'Running' THEN RunStatus END) AS RunningState
FROM    ProcessLog
WHERE   RunStatus IN ('Error','Running')
GROUP BY Workflow
)
SELECT  a.Workflow,
        CASE WHEN a.MinStatus = a.MaxStatus THEN a.MinStatus
             WHEN b.ErrorState = 'Error' THEN 'Indeterminate'
             WHEN b.RunningState = 'Running' THEN b.RunningState END AS RunStatus
FROM    cte_MinMax a LEFT OUTER JOIN
        cte_Error b ON a.WorkFlow = b.WorkFlow
ORDER BY 1;

--Solution 2
--COUNT and STRING_AGG
WITH cte_Distinct AS
(
SELECT DISTINCT
       Workflow,
       RunStatus
FROM   ProcessLog
),
cte_StringAgg AS
(
SELECT  Workflow,
        STRING_AGG(RunStatus, ', ') AS RunStatus_Agg,
        COUNT(DISTINCT RunStatus) AS DistinctCount
FROM    cte_Distinct
GROUP BY Workflow
)
SELECT  Workflow,
        CASE WHEN DistinctCount = 1 THEN RunStatus_Agg
             WHEN RunStatus_Agg LIKE '%Error%' THEN 'Indeterminate'
             WHEN RunStatus_Agg LIKE '%Running%' THEN 'Running' END AS RunStatus
FROM    cte_StringAgg
ORDER BY 1;

/*----------------------------------------------------
Answer to Puzzle #15
Group Concatenation
*/----------------------------------------------------

DROP TABLE IF EXISTS DMLTable;

CREATE TABLE DMLTable
(
SequenceNumber  INTEGER PRIMARY KEY,
String          VARCHAR(100) NOT NULL
);

INSERT INTO DMLTable (SequenceNumber, String) VALUES
(1,'SELECT'),
(2,'Product,'),
(3,'UnitPrice,'),
(4,'EffectiveDate'),
(5,'FROM'),
(6,'Products'),
(7,'WHERE'),
(8,'UnitPrice'),
(9,'> 100');

--Solution 1
--STRING_AGG
SELECT  STRING_AGG(String, ' ' ORDER BY SequenceNumber ASC)
FROM    DMLTable;

--Solution 2
--Recursion
WITH RECURSIVE cte_DMLGroupConcat(String2, Depth) AS
(
SELECT  ''::TEXT,
        MAX(SequenceNumber)
FROM    DMLTable
UNION ALL
SELECT  cte_Ordered.String || ' ' || cte_Concat.String2, cte_Concat.Depth-1
FROM    cte_DMLGroupConcat cte_Concat INNER JOIN
        DMLTable cte_Ordered ON cte_Concat.Depth = cte_Ordered.SequenceNumber
)
SELECT  String2
FROM    cte_DMLGroupConcat
WHERE   Depth = 0;

/*----------------------------------------------------
Answer to Puzzle #16
Reciprocals
*/----------------------------------------------------

DROP TABLE IF EXISTS PlayerScores;

CREATE TABLE PlayerScores
(
PlayerA  INTEGER,
PlayerB  INTEGER,
Score    INTEGER NOT NULL,
PRIMARY KEY (PlayerA, PlayerB)
);

INSERT INTO PlayerScores (PlayerA, PlayerB, Score) VALUES
(1001,2002,150),(3003,4004,15),(4004,3003,125);

SELECT  PlayerA,
        PlayerB,
        SUM(Score) AS Score
FROM    (
        SELECT
                (CASE WHEN PlayerA <= PlayerB THEN PlayerA ELSE PlayerB END) AS PlayerA,
                (CASE WHEN PlayerA <= PlayerB THEN PlayerB ELSE PlayerA END) AS PlayerB,
                Score
        FROM    PlayerScores
        ) a
GROUP BY PlayerA, PlayerB;

/*----------------------------------------------------
Answer to Puzzle #17
De-Grouping
*/----------------------------------------------------

DROP TABLE IF EXISTS Ungroup;

CREATE TABLE Ungroup
(
ProductDescription  VARCHAR(100) PRIMARY KEY,
Quantity            INTEGER NOT NULL
);

INSERT INTO Ungroup (ProductDescription, Quantity) VALUES
('Pencil',3),('Eraser',4),('Notebook',2);

--Solution 1
--Using GENERATE_SERIES
SELECT  a.ProductDescription,
        1 AS Quantity
FROM    Ungroup a
        CROSS JOIN LATERAL GENERATE_SERIES(1, a.Quantity) AS b(n);

--Solution 2
--Recursion
WITH RECURSIVE cte_Recursion AS
(
SELECT  ProductDescription, Quantity
FROM    Ungroup
UNION ALL
SELECT  ProductDescription, Quantity-1
FROM    cte_Recursion
WHERE   Quantity >= 2
)
SELECT  ProductDescription, 1 AS Quantity
FROM    cte_Recursion
ORDER BY ProductDescription DESC;

/*----------------------------------------------------
Answer to Puzzle #18
Seating Chart
*/----------------------------------------------------

DROP TABLE IF EXISTS SeatingChart;

CREATE TABLE SeatingChart
(
SeatNumber  INTEGER PRIMARY KEY
);

INSERT INTO SeatingChart (SeatNumber) VALUES
(7),(13),(14),(15),(27),(28),(29),(30),(31),(32),(33),(34),(35),(52),(53),(54);

--Place a value of 0 in the SeatingChart table
INSERT INTO SeatingChart (SeatNumber) VALUES (0);

-------------------
--Gap start and gap end
WITH cte_Gaps AS
(
SELECT  SeatNumber AS GapStart,
        LEAD(SeatNumber,1,0) OVER (ORDER BY SeatNumber) AS GapEnd,
        LEAD(SeatNumber,1,0) OVER (ORDER BY SeatNumber) - SeatNumber AS Gap
FROM    SeatingChart
)
SELECT  GapStart + 1 AS GapStart,
        GapEnd - 1 AS GapEnd
FROM    cte_Gaps
WHERE Gap > 1;

-------------------
--Sequence start and sequence End
WITH cte_Sequences AS
(
SELECT  SeatNumber,
        SeatNumber - ROW_NUMBER() OVER (ORDER BY SeatNumber) AS GroupID
FROM    SeatingChart
)
SELECT  MIN(SeatNumber) AS SequenceStart,
        MAX(SeatNumber) AS SequenceEnd
FROM    cte_Sequences
GROUP BY GroupID
ORDER BY SequenceStart;

-------------------
--Missing Numbers
--Solution 1
WITH cte_Rank AS
(
SELECT  SeatNumber,
        ROW_NUMBER() OVER (ORDER BY SeatNumber) AS RowNumber,
        SeatNumber - ROW_NUMBER() OVER (ORDER BY SeatNumber) AS Rnk
FROM    SeatingChart
WHERE   SeatNumber > 0
)
SELECT  MAX(Rnk) AS MissingNumbers
FROM    cte_Rank;

--Solution 2
SELECT  MAX(SeatNumber) - COUNT(SeatNumber) AS MissingNumbers
FROM    SeatingChart
WHERE   SeatNumber <> 0;

-------------------
--Odd and even number count
WITH cte_Seats AS
(
SELECT  *
FROM    SeatingChart
WHERE   SeatNumber > 0
)
SELECT  (CASE SeatNumber%2 WHEN 1 THEN 'Odd' WHEN 0 THEN 'Even' END) AS Modulus,
        COUNT(*) AS Count
FROM    cte_Seats
GROUP BY (CASE SeatNumber%2 WHEN 1 THEN 'Odd' WHEN 0 THEN 'Even' END);

/*----------------------------------------------------
Answer to Puzzle #19
Back to the Future
*/----------------------------------------------------

DROP TABLE IF EXISTS TimePeriods;
DROP TABLE IF EXISTS Distinct_StartDates;
DROP TABLE IF EXISTS OuterJoin;
DROP TABLE IF EXISTS DetermineValidEndDates;
DROP TABLE IF EXISTS DetermineValidEndDates2;

CREATE TABLE TimePeriods
(
StartDate  DATE,
EndDate    DATE,
PRIMARY KEY (StartDate, EndDate)
);

INSERT INTO TimePeriods (StartDate, EndDate) VALUES
('2018-01-01','2018-01-05'),
('2018-01-03','2018-01-09'),
('2018-01-10','2018-01-11'),
('2018-01-12','2018-01-16'),
('2018-01-15','2018-01-19');

--Step 1
SELECT  DISTINCT StartDate
INTO    Distinct_StartDates
FROM    TimePeriods;

--Step 2
SELECT  a.StartDate AS StartDate_A,
        a.EndDate AS EndDate_A,
        b.StartDate AS StartDate_B,
        b.EndDate AS EndDate_B
INTO    OuterJoin
FROM    TimePeriods AS a LEFT OUTER JOIN
        TimePeriods AS b ON a.EndDate >= b.StartDate AND
                            a.EndDate < b.EndDate;

--Step 3
SELECT  EndDate_A
INTO    DetermineValidEndDates
FROM    OuterJoin
WHERE   StartDate_B IS NULL
GROUP BY EndDate_A;

--Step 4
SELECT  a.StartDate, MIN(b.EndDate_A) AS MinEndDate_A
INTO    DetermineValidEndDates2
FROM    Distinct_StartDates a INNER JOIN
        DetermineValidEndDates b ON a.StartDate <= b.EndDate_A
GROUP BY a.StartDate;

--Results
SELECT  MIN(StartDate) AS StartDate,
        MAX(MinEndDate_A) AS EndDate
FROM    DetermineValidEndDates2
GROUP BY MinEndDate_A;

/*----------------------------------------------------
Answer to Puzzle #20
Price Points
*/----------------------------------------------------

DROP TABLE IF EXISTS ValidPrices;

CREATE TABLE ValidPrices
(
ProductID      INTEGER,
UnitPrice      DECIMAL(19,4),
EffectiveDate  DATE,
PRIMARY KEY (ProductID, UnitPrice, EffectiveDate)
);

INSERT INTO ValidPrices (ProductID, UnitPrice, EffectiveDate) VALUES
(1001,1.99,'2018-01-01'),
(1001,2.99,'2018-04-15'),
(1001,3.99,'2018-06-08'),
(2002,1.99,'2018-04-17'),
(2002,2.99,'2018-05-19');

--Solution 1
--NOT EXISTS
SELECT  ProductID,
        EffectiveDate,
        COALESCE(UnitPrice,0) AS UnitPrice
FROM    ValidPrices AS pp
WHERE   NOT EXISTS (SELECT 1
                    FROM   ValidPrices AS ppl
                    WHERE  ppl.ProductID = pp.ProductID AND
                           ppl.EffectiveDate > pp.EffectiveDate);

--Solution 2
--RANK
WITH cte_ValidPrices AS
(
SELECT  RANK() OVER (PARTITION BY ProductID ORDER BY EffectiveDate DESC) AS Rnk,
        ProductID,
        EffectiveDate,
        UnitPrice
FROM    ValidPrices
)
SELECT  Rnk, ProductID, EffectiveDate, UnitPrice
FROM    cte_ValidPrices
WHERE   Rnk = 1;

--Solution 3
--MAX
WITH cte_MaxEffectiveDate AS
(
SELECT  ProductID,
        MAX(EffectiveDate) AS MaxEffectiveDate
FROM    ValidPrices
GROUP BY ProductID
)
SELECT  a.*
FROM    ValidPrices a INNER JOIN
        cte_MaxEffectiveDate b ON a.EffectiveDate = b.MaxEffectiveDate AND a.ProductID = b.ProductID;

/*----------------------------------------------------
Answer to Puzzle #21
Average Monthly Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
OrderDate   DATE NOT NULL,
Amount      DECIMAL(19,4) NOT NULL,
State       VARCHAR(2) NOT NULL
);

INSERT INTO Orders (OrderID, CustomerID, OrderDate, Amount, State) VALUES
(1,1001,'2018-01-01',100,'TX'),
(2,1001,'2018-01-01',150,'TX'),
(3,1001,'2018-01-01',75,'TX'),
(4,1001,'2018-02-01',100,'TX'),
(5,1001,'2018-03-01',100,'TX'),
(6,2002,'2018-02-01',75,'TX'),
(7,2002,'2018-02-01',150,'TX'),
(8,3003,'2018-01-01',100,'IA'),
(9,3003,'2018-02-01',100,'IA'),
(10,3003,'2018-03-01',100,'IA'),
(11,4004,'2018-04-01',100,'IA'),
(12,4004,'2018-05-01',50,'IA'),
(13,4004,'2018-05-01',100,'IA');

WITH cte_AvgMonthlySalesCustomer AS
(
SELECT  CustomerID,
        OrderDate,
        State,
        AVG(Amount) AS AverageValue
FROM    Orders
GROUP BY CustomerID, OrderDate, State
),
cte_MinAverageValueState AS
(
SELECT  State
FROM    cte_AvgMonthlySalesCustomer
GROUP BY State
HAVING  MIN(AverageValue) >= 100
)
SELECT  State
FROM    cte_MinAverageValueState;

/*----------------------------------------------------
Answer to Puzzle #22
Occurrences
*/----------------------------------------------------

DROP TABLE IF EXISTS ProcessLog;

CREATE TABLE ProcessLog
(
Workflow     VARCHAR(100),
LogMessage   VARCHAR(100),
Occurrences  INTEGER NOT NULL,
PRIMARY KEY (Workflow, LogMessage)
);

INSERT INTO ProcessLog (Workflow, LogMessage, Occurrences) VALUES
('Alpha','Error: Conversion Failed',5),
('Alpha','Status Complete',8),
('Alpha','Error: Unidentified error occurred',9),
('Bravo','Error: Cannot Divide by 0',3),
('Bravo','Error: Unidentified error occurred',1),
('Charlie','Error: Unidentified error occurred',10),
('Charlie','Error: Conversion Failed',7),
('Charlie','Status Complete',6);

--Solution 1
--Rank
WITH cte_RankedMessages AS
(
SELECT  Workflow,
        LogMessage,
        Occurrences,
        RANK() OVER (PARTITION BY LogMessage ORDER BY Occurrences DESC) AS rnk
FROM    ProcessLog
)
SELECT Workflow, LogMessage, Occurrences
FROM   cte_RankedMessages
WHERE  rnk = 1;

--Solution 2
--MAX
WITH cte_LogMessageCount AS
(
SELECT  LogMessage,
        MAX(Occurrences) AS MaxOccurrences
FROM    ProcessLog
GROUP BY LogMessage
)
SELECT  a.Workflow,
        a.LogMessage,
        a.Occurrences
FROM    ProcessLog a INNER JOIN
        cte_LogMessageCount b ON a.LogMessage = b.LogMessage AND
                                 a.Occurrences = b.MaxOccurrences
ORDER BY 1;

--Solution 3
--Correlated Subquery
SELECT Workflow, LogMessage, Occurrences
FROM   ProcessLog p
WHERE  Occurrences = (SELECT MAX(Occurrences) FROM ProcessLog WHERE LogMessage = p.LogMessage);

/*----------------------------------------------------
Answer to Puzzle #23
Divide in Half
*/----------------------------------------------------

DROP TABLE IF EXISTS PlayerScores;

CREATE TABLE PlayerScores
(
PlayerID  INTEGER PRIMARY KEY,
Score     INTEGER NOT NULL
);

INSERT INTO PlayerScores (PlayerID, Score) VALUES
(1001,2343),(2002,9432),
(3003,6548),(4004,1054),
(5005,6832);

SELECT  NTILE(2) OVER (ORDER BY Score DESC) AS Quartile,
        PlayerID,
        Score
FROM    PlayerScores a
ORDER BY Score DESC;

/*----------------------------------------------------
Answer to Puzzle #24
Page Views
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
OrderDate   DATE NOT NULL,
Amount      DECIMAL(19,4) NOT NULL,
State       VARCHAR(2) NOT NULL
);

INSERT INTO Orders (OrderID, CustomerID, OrderDate, Amount, State) VALUES
(1, 1001, '2018-01-01', 100, 'TX'),
(2, 3003, '2018-01-01', 100, 'IA'),
(3, 1001, '2018-03-01', 100, 'TX'),
(4, 2002, '2018-02-01', 150, 'TX'),
(5, 1001, '2018-02-01', 100, 'TX'),
(6, 4004, '2018-05-01', 50,  'IA'),
(7, 1001, '2018-01-01', 150, 'TX'),
(8, 3003, '2018-03-01', 100, 'IA'),
(9, 4004, '2018-04-01', 100, 'IA'),
(10, 1001, '2018-01-01', 75,  'TX'),
(11, 2002, '2018-02-01', 75,  'TX'),
(12, 3003, '2018-02-01', 100, 'IA'),
(13, 4004, '2018-05-01', 100, 'IA');

--Solution 1
--LIMIT OFFSET
SELECT  OrderID, CustomerID, OrderDate, Amount, State
FROM    Orders
ORDER BY OrderID
LIMIT 6 OFFSET 4;

--Solution 2
--RowNumber
WITH cte_RowNumber AS
(
SELECT  ROW_NUMBER() OVER (ORDER BY OrderID) AS RowNumber,
        OrderID, CustomerID, OrderDate, Amount, State
FROM    Orders
)
SELECT  OrderID, CustomerID, OrderDate, Amount, State
FROM    cte_RowNumber
WHERE   RowNumber BETWEEN 5 AND 10;

/*----------------------------------------------------
Answer to Puzzle #25
Top Vendors
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
Count       INTEGER NOT NULL,
Vendor      VARCHAR(100) NOT NULL
);

INSERT INTO Orders (OrderID, CustomerID, Count, Vendor) VALUES
(1,1001,12,'Direct Parts'),
(2,1001,54,'Direct Parts'),
(3,1001,32,'ACME'),
(4,2002,7,'ACME'),
(5,2002,16,'ACME'),
(6,2002,5,'Direct Parts');

--Solution 1
--MAX window function
WITH cte_Max AS
(
SELECT  OrderID, CustomerID, Count, Vendor,
        MAX(Count) OVER (PARTITION BY CustomerID ORDER BY CustomerID) AS MaxCount
FROM    Orders
)
SELECT  CustomerID, Vendor
FROM    cte_Max
WHERE   Count = MaxCount
ORDER BY 1, 2;

--Solution 2
--RANK function
WITH cte_Rank AS
(
SELECT  CustomerID,
        Vendor,
        RANK() OVER (PARTITION BY CustomerID ORDER BY Count DESC) AS Rnk
FROM    Orders
GROUP BY CustomerID, Vendor, Count
)
SELECT  DISTINCT b.CustomerID, b.Vendor
FROM    Orders a INNER JOIN
        cte_Rank b ON a.CustomerID = b.CustomerID AND a.Vendor = b.Vendor
WHERE   Rnk = 1
ORDER BY 1, 2;

/*----------------------------------------------------
Answer to Puzzle #26
Previous Year's Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Sales;

CREATE TABLE Sales
(
Year    INTEGER NOT NULL,
Amount  INTEGER NOT NULL
);

INSERT INTO Sales (Year, Amount) VALUES
(EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,352645),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 year')::INTEGER,165565),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 year')::INTEGER,254654),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '2 years')::INTEGER,159521),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '2 years')::INTEGER,251696),
(EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '3 years')::INTEGER,111894);

--Solution using LAG
WITH cte_AggregateTotal AS
(
SELECT  Year,
        SUM(Amount) AS Amount
FROM    Sales
GROUP BY Year
),
cte_Lag AS
(
SELECT  Year,
        Amount,
        LAG(Amount,1,0) OVER (ORDER BY Year) AS Lag1,
        LAG(Amount,2,0) OVER (ORDER BY Year) AS Lag2
FROM    cte_AggregateTotal
)
SELECT  Amount AS CurrentYear,
        Lag1 AS PreviousYear1,
        Lag2 AS PreviousYear2
FROM    cte_Lag
WHERE   Year = EXTRACT(YEAR FROM CURRENT_DATE);

/*----------------------------------------------------
Answer to Puzzle #27
Delete the Duplicates
*/----------------------------------------------------

DROP TABLE IF EXISTS SampleData;

CREATE TABLE SampleData
(
IntegerValue  INTEGER NOT NULL
);

INSERT INTO SampleData (IntegerValue) VALUES
(1),(1),(2),(3),(3),(4);

-- PostgreSQL approach using ctid
DELETE FROM SampleData
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM SampleData
    GROUP BY IntegerValue
);

SELECT * FROM SampleData;

/*----------------------------------------------------
Answer to Puzzle #28
Fill the Gaps
Note, this is often called a flash fill or a data smudge.
*/----------------------------------------------------

DROP TABLE IF EXISTS Gaps;

CREATE TABLE Gaps
(
RowNumber  INTEGER PRIMARY KEY,
TestCase   VARCHAR(100) NULL
);

INSERT INTO Gaps (RowNumber, TestCase) VALUES
(1,'Alpha'),(2,NULL),(3,NULL),(4,NULL),
(5,'Bravo'),(6,NULL),(7,'Charlie'),(8,NULL),(9,NULL);

--Solution 1
--MAX and COUNT function
WITH cte_Count AS
(
SELECT RowNumber,
       TestCase,
       COUNT(TestCase) OVER (ORDER BY RowNumber) AS DistinctCount
FROM Gaps
)
SELECT  RowNumber,
        MAX(TestCase) OVER (PARTITION BY DistinctCount) AS TestCase
FROM    cte_Count
ORDER BY RowNumber;

--Solution 2
--MAX function without windowing
SELECT  a.RowNumber,
        (SELECT b.TestCase
        FROM    Gaps b
        WHERE   b.RowNumber =
                    (SELECT MAX(c.RowNumber)
                    FROM Gaps c
                    WHERE c.RowNumber <= a.RowNumber AND c.TestCase != '')) TestCase
FROM Gaps a;

/*----------------------------------------------------
Answer to Puzzle #29
Count the Groupings
*/----------------------------------------------------
DROP TABLE IF EXISTS Groupings;

CREATE TABLE Groupings
(
StepNumber  INTEGER PRIMARY KEY,
TestCase    VARCHAR(100) NOT NULL,
Status      VARCHAR(100) NOT NULL
);

INSERT INTO Groupings (StepNumber, TestCase, Status) VALUES
(1,'Test Case 1','Passed'),
(2,'Test Case 2','Passed'),
(3,'Test Case 3','Passed'),
(4,'Test Case 4','Passed'),
(5,'Test Case 5','Failed'),
(6,'Test Case 6','Failed'),
(7,'Test Case 7','Failed'),
(8,'Test Case 8','Failed'),
(9,'Test Case 9','Failed'),
(10,'Test Case 10','Passed'),
(11,'Test Case 11','Passed'),
(12,'Test Case 12','Passed');

--Solution 1
WITH cte_Groupings AS
(
SELECT  StepNumber,
        Status,
        StepNumber - ROW_NUMBER() OVER (PARTITION BY Status ORDER BY StepNumber) AS Rnk
FROM    Groupings
)
SELECT  MIN(StepNumber) AS MinStepNumber,
        MAX(StepNumber) AS MaxStepNumber,
        Status,
        COUNT(*) AS ConsecutiveCount,
        MAX(StepNumber) - MIN(StepNumber) + 1 AS ConsecutiveCount_MinMax
FROM    cte_Groupings
GROUP BY Rnk, Status
ORDER BY 1, 2;

--Solution 2
WITH cte_Lag AS
(
SELECT  *,
        LAG(Status) OVER(ORDER BY StepNumber) AS PreviousStatus
FROM    Groupings
),
cte_Groupings AS
(
SELECT  *,
        SUM(CASE WHEN PreviousStatus <> Status THEN 1 ELSE 0 END) OVER (ORDER BY StepNumber) AS GroupNumber
FROM    cte_Lag
)
SELECT  MIN(StepNumber) AS MinStepNumber,
        MAX(StepNumber) AS MaxStepNumber,
        Status,
        COUNT(*) AS ConsecutiveCount,
        MAX(StepNumber) - MIN(StepNumber) + 1 AS ConsecutiveCount_MinMax
FROM    cte_Groupings
GROUP BY Status, GroupNumber;

/*----------------------------------------------------
Answer to Puzzle #30
Select Star
*/----------------------------------------------------

DROP TABLE IF EXISTS Products;

CREATE TABLE Products
(
ProductID    INTEGER PRIMARY KEY,
ProductName  VARCHAR(100) NOT NULL
);

--Add a computed column that causes divide by zero error
--PostgreSQL uses GENERATED columns
ALTER TABLE Products ADD COLUMN ComputedColumn INTEGER GENERATED ALWAYS AS (0/1) STORED;
--Note: PostgreSQL won't allow 0/0 as it's evaluated at column creation time
--This puzzle demonstrates the concept that SELECT * can fail with computed columns

/*----------------------------------------------------
Answer to Puzzle #31
Second Highest
*/----------------------------------------------------

DROP TABLE IF EXISTS SampleData;

CREATE TABLE SampleData
(
IntegerValue  INTEGER PRIMARY KEY
);

INSERT INTO SampleData (IntegerValue) VALUES
(3759),(3760),(3761),(3762),(3763);

--Solution 1
--RANK
WITH cte_Rank AS
(
SELECT  RANK() OVER (ORDER BY IntegerValue DESC) AS MyRank,
        *
FROM    SampleData
)
SELECT  IntegerValue
FROM    cte_Rank
WHERE   MyRank = 2;

--Solution 2
--LIMIT and Max
SELECT  IntegerValue
FROM    SampleData
WHERE   IntegerValue <> (SELECT MAX(IntegerValue) FROM SampleData)
ORDER BY IntegerValue DESC
LIMIT 1;

--Solution 3
--LIMIT OFFSET
SELECT  IntegerValue
FROM    SampleData
ORDER BY IntegerValue DESC
LIMIT 1 OFFSET 1;

--Solution 4
--Subquery
SELECT  IntegerValue
FROM    (
        SELECT  *
        FROM    SampleData
        ORDER BY IntegerValue DESC
        LIMIT 2
        ) a
ORDER BY IntegerValue ASC
LIMIT 1;

/*----------------------------------------------------
Answer to Puzzle #32
First and Last
*/----------------------------------------------------

DROP TABLE IF EXISTS Personal;

CREATE TABLE Personal
(
SpacemanID      INTEGER PRIMARY KEY,
JobDescription  VARCHAR(100) NOT NULL,
MissionCount    INTEGER NOT NULL
);

INSERT INTO Personal (SpacemanID, JobDescription, MissionCount) VALUES
(1001,'Astrogator',6),(2002,'Astrogator',12),(3003,'Astrogator',17),
(4004,'Geologist',21),(5005,'Geologist',9),(6006,'Geologist',8),
(7007,'Technician',13),(8008,'Technician',2),(9009,'Technician',7);

--Solution 1
--ROW_NUMBER, MAX, CASE
WITH RankedExperience AS
(
SELECT  JobDescription,
        SpacemanID,
        MissionCount,
        ROW_NUMBER() OVER (PARTITION BY JobDescription ORDER BY MissionCount DESC) AS rn_max,
        ROW_NUMBER() OVER (PARTITION BY JobDescription ORDER BY MissionCount ASC) AS rn_min
FROM Personal
)
SELECT  MAX(CASE WHEN rn_max = 1 THEN JobDescription END) AS JobDescription,
        MAX(CASE WHEN rn_max = 1 THEN SpacemanID END) AS MostExperienced,
        MAX(CASE WHEN rn_min = 1 THEN SpacemanID END) AS LeastExperienced
FROM    RankedExperience
GROUP BY JobDescription;

--Solution 2
--MIN and MAX
WITH cte_MinMax AS
(
SELECT  JobDescription,
        MAX(MissionCount) AS MaxMissionCount,
        MIN(MissionCount) AS MinMissionCount
FROM    Personal
GROUP BY JobDescription
)
SELECT  a.JobDescription,
        b.SpacemanID AS MostExperienced,
        c.SpacemanID AS LeastExperienced
FROM    cte_MinMax a INNER JOIN
        Personal b ON a.JobDescription = b.JobDescription AND
                       a.MaxMissionCount = b.MissionCount  INNER JOIN
        Personal c ON a.JobDescription = c.JobDescription AND
                       a.MinMissionCount = c.MissionCount;

/*----------------------------------------------------
Answer to Puzzle #33
Deadlines
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS ManufacturingTimes;

CREATE TABLE Orders
(
OrderID        INTEGER PRIMARY KEY,
Product        VARCHAR(100) NOT NULL,
DaysToDeliver  INTEGER NOT NULL
);

CREATE TABLE ManufacturingTimes
(
Product            VARCHAR(100),
Component          VARCHAR(100),
DaysToManufacture  INTEGER NOT NULL,
PRIMARY KEY (Product, Component)
);

INSERT INTO Orders (OrderID, Product, DaysToDeliver) VALUES
(1, 'Aurora', 7),
(2, 'Twilight', 3),
(3, 'SunRay', 9);

INSERT INTO ManufacturingTimes (Product, Component, DaysToManufacture) VALUES
('Aurora', 'Photon Coil', 7),
('Aurora', 'Filament', 2),
('Aurora', 'Shine Capacitor', 3),
('Aurora', 'Glow Sphere', 1),
('Twilight', 'Photon Coil', 7),
('Twilight', 'Filament', 2),
('SunRay', 'Shine Capacitor', 3),
('SunRay', 'Photon Coil', 1);

WITH cte_Max AS
(
SELECT  Product,
        MAX(DaysToManufacture) AS DaysToBuild
FROM    ManufacturingTimes b
GROUP BY Product
)
SELECT  a.OrderID,
        a.Product,
        b.DaystoBuild,
        a.DaysToDeliver,
        CASE WHEN b.DaystoBuild = DaystoDeliver THEN 'On Schedule'
             WHEN b.DaystoBuild < DaystoDeliver THEN 'Ahead of Schedule'
             WHEN b.DaystoBuild > DaystoDeliver THEN 'Behind Schedule' END AS Schedule
FROM    Orders a INNER JOIN
        cte_Max b ON a.Product = b.Product;

/*----------------------------------------------------
Answer to Puzzle #34
Specific Exclusion
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders
(
OrderID     INTEGER PRIMARY KEY,
CustomerID  INTEGER NOT NULL,
Amount      DECIMAL(19,4) NOT NULL
);

INSERT INTO Orders (OrderID, CustomerID, Amount) VALUES
(1,1001,25),(2,1001,50),(3,2002,65),(4,3003,50);

--Solutions 1 and 2 show Morgan's Law.
--Solution 1
--NOT
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
WHERE   NOT(CustomerID = 1001 AND Amount = 50);

--Solution 2
--OR
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
WHERE   CustomerID <> 1001 OR Amount <> 50;

--Solution 3
--EXCEPT
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
EXCEPT
SELECT  OrderID,
        CustomerID,
        Amount
FROM    Orders
WHERE   CustomerID = 1001 AND Amount = 50;

/*----------------------------------------------------
Answer to Puzzle #35
International vs Domestic Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders
(
InvoiceID   INTEGER PRIMARY KEY,
SalesRepID  INTEGER NOT NULL,
Amount      DECIMAL(19,4) NOT NULL,
SalesType   VARCHAR(100) NOT NULL
);

INSERT INTO Orders (InvoiceId, SalesRepID, Amount, SalesType) VALUES
(1,1001,13454,'International'),
(2,2002,3434,'International'),
(3,4004,54645,'International'),
(4,5005,234345,'International'),
(5,1001,4564,'Domestic'),
(6,2002,34534,'Domestic'),
(7,3003,345,'Domestic'),
(8,6006,6543,'Domestic');

SELECT  SalesRepID
FROM    Orders
GROUP BY SalesRepID
HAVING  COUNT(DISTINCT SalesType) = 1;

/*----------------------------------------------------
Answer to Puzzle #36
Traveling Salesman
*/----------------------------------------------------

DROP TABLE IF EXISTS Routes;
DROP TABLE IF EXISTS TravelingSalesman;

CREATE TABLE Routes
(
RouteID        INTEGER NOT NULL,
DepartureCity  VARCHAR(30) NOT NULL,
ArrivalCity    VARCHAR(30) NOT NULL,
Cost           DECIMAL(19,4) NOT NULL,
PRIMARY KEY (DepartureCity, ArrivalCity)
);

INSERT INTO Routes (RouteID, DepartureCity, ArrivalCity, Cost) VALUES
(1,'Austin','Dallas',100),
(2,'Dallas','Memphis',200),
(3,'Memphis','Des Moines',300),
(4,'Dallas','Des Moines',400);

--Solution using Recursion
WITH RECURSIVE cte_Map (Nodes, LastNode, NodeMap, Cost) AS
(
SELECT  2 AS Nodes,
        ArrivalCity,
        '\' || DepartureCity || '\' || ArrivalCity || '\' AS NodeMap,
        Cost
FROM    Routes
WHERE   DepartureCity = 'Austin'
UNION ALL
SELECT  m.Nodes + 1 AS Nodes,
        r.ArrivalCity AS LastNode,
        m.NodeMap || r.ArrivalCity || '\' AS NodeMap,
        m.Cost + r.Cost AS Cost
FROM    cte_Map AS m INNER JOIN
        Routes AS r ON r.DepartureCity = m.LastNode
WHERE   m.NodeMap NOT LIKE '\%' || r.ArrivalCity || '%\'
)
SELECT  NodeMap, Cost
INTO    TravelingSalesman
FROM    cte_Map;

WITH cte_LeftReplace AS
(
SELECT  LEFT(NodeMap, LENGTH(NodeMap)-1) AS RoutePath,
        Cost
FROM    TravelingSalesman
WHERE   RIGHT(NodeMap,11) = 'Des Moines\'
),
cte_RightReplace AS
(
SELECT  SUBSTRING(RoutePath,2,LENGTH(RoutePath)-1) AS RoutePath,
        Cost
FROM    cte_LeftReplace
)
SELECT  REPLACE(RoutePath,'\', ' -->') AS RoutePath,
        Cost AS TotalCost
FROM    cte_RightReplace;

/*----------------------------------------------------
Answer to Puzzle #37
Group Criteria Keys
*/----------------------------------------------------

DROP TABLE IF EXISTS GroupCriteria;

CREATE TABLE GroupCriteria
(
OrderID      INTEGER PRIMARY KEY,
Distributor  VARCHAR(100) NOT NULL,
Facility     INTEGER NOT NULL,
Zone         VARCHAR(100) NOT NULL,
Amount       DECIMAL(19,4) NOT NULL
);

INSERT INTO GroupCriteria (OrderID, Distributor, Facility, Zone, Amount) VALUES
(1,'ACME',123,'ABC',100),
(2,'ACME',123,'ABC',75),
(3,'Direct Parts',789,'XYZ',150),
(4,'Direct Parts',789,'XYZ',125);

SELECT  DENSE_RANK() OVER (ORDER BY Distributor, Facility, Zone) AS CriteriaID,
        OrderID,
        Distributor,
        Facility,
        Zone,
        Amount
FROM    GroupCriteria;

/*----------------------------------------------------
Answer to Puzzle #38
Reporting Elements
*/----------------------------------------------------

DROP TABLE IF EXISTS RegionSales;

CREATE TABLE RegionSales
(
Region       VARCHAR(100),
Distributor  VARCHAR(100),
Sales        INTEGER NOT NULL,
PRIMARY KEY (Region, Distributor)
);

INSERT INTO RegionSales (Region, Distributor, Sales) VALUES
('North','ACE',10),
('South','ACE',67),
('East','ACE',54),
('North','ACME',65),
('South','ACME',9),
('East','ACME',1),
('West','ACME',7),
('North','Direct Parts',8),
('South','Direct Parts',7),
('West','Direct Parts',12);

WITH cte_DistinctRegion AS
(
SELECT  DISTINCT Region
FROM    RegionSales
),
cte_DistinctDistributor AS
(
SELECT  DISTINCT Distributor
FROM    RegionSales
),
cte_CrossJoin AS
(
SELECT  Region, Distributor
FROM    cte_DistinctRegion a CROSS JOIN
        cte_DistinctDistributor b
)
SELECT  a.Region,
        a.Distributor,
        COALESCE(b.Sales,0) AS Sales
FROM    cte_CrossJoin a LEFT OUTER JOIN
        RegionSales b ON a.Region = b.Region and a.Distributor = b.Distributor
ORDER BY a.Distributor,
        (CASE a.Region  WHEN 'North' THEN 1
                        WHEN 'South' THEN 2
                        WHEN 'East'  THEN 3
                        WHEN 'West'  THEN 4 END);

/*----------------------------------------------------
Answer to Puzzle #39
Prime Numbers
*/----------------------------------------------------

DROP TABLE IF EXISTS PrimeNumbers;

CREATE TABLE PrimeNumbers
(
IntegerValue  INTEGER PRIMARY KEY
);

INSERT INTO PrimeNumbers (IntegerValue) VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

SELECT  IntegerValue
FROM    PrimeNumbers p
WHERE   IntegerValue > 1
AND NOT EXISTS (
    SELECT  1
    FROM    PrimeNumbers d
    WHERE   d.IntegerValue > 1
      AND   d.IntegerValue < p.IntegerValue
      AND   p.IntegerValue % d.IntegerValue = 0
);

/*----------------------------------------------------
Answer to Puzzle #40
Sort Order
*/----------------------------------------------------

DROP TABLE IF EXISTS SortOrder;

CREATE TABLE SortOrder
(
City  VARCHAR(100) PRIMARY KEY
);

INSERT INTO SortOrder (City) VALUES
('Atlanta'),('Baltimore'),('Chicago'),('Denver');

SELECT  City
FROM    SortOrder
ORDER BY (CASE City WHEN 'Atlanta' THEN 2
                    WHEN 'Baltimore' THEN 1
                    WHEN 'Chicago' THEN 4
                    WHEN 'Denver' THEN 1 END);

/*----------------------------------------------------
Answer to Puzzle #41
Associate IDs
*/----------------------------------------------------

DROP TABLE IF EXISTS Associates;
DROP TABLE IF EXISTS Associates2;
DROP TABLE IF EXISTS Associates3;

CREATE TABLE Associates
(
Associate1  VARCHAR(100),
Associate2  VARCHAR(100),
PRIMARY KEY (Associate1, Associate2)
);

INSERT INTO Associates (Associate1, Associate2) VALUES
('Anne','Betty'),('Anne','Charles'),('Betty','Dan'),('Charles','Emma'),
('Francis','George'),('George','Harriet');

--Step 1
--Recursion
WITH RECURSIVE cte_Recursive AS
(
SELECT  Associate1,
        Associate2
FROM    Associates
UNION ALL
SELECT  a.Associate1,
        b.Associate2
FROM    Associates a INNER JOIN
        cte_Recursive b ON a.Associate2 = b.Associate1
)
SELECT  Associate1,
        Associate2
INTO    Associates2
FROM    cte_Recursive
UNION ALL
SELECT  Associate1,
        Associate1
FROM    Associates;

--Step 2
SELECT  MIN(Associate1) AS Associate1,
        Associate2
INTO    Associates3
FROM    Associates2
GROUP BY Associate2;

--Results
SELECT  DENSE_RANK() OVER (ORDER BY Associate1) AS GroupingNumber,
        Associate2 AS Associate
FROM    Associates3;

/*----------------------------------------------------
Answer to Puzzle #42
Mutual Friends
*/----------------------------------------------------

DROP TABLE IF EXISTS Friends;
DROP TABLE IF EXISTS Nodes;
DROP TABLE IF EXISTS Edges;
DROP TABLE IF EXISTS Nodes_Edges_To_Evaluate;

CREATE TABLE Friends
(
Friend1  VARCHAR(100),
Friend2  VARCHAR(100),
PRIMARY KEY (Friend1, Friend2)
);

INSERT INTO Friends (Friend1, Friend2) VALUES
('Jason','Mary'),('Mike','Mary'),('Mike','Jason'),
('Susan','Jason'),('John','Mary'),('Susan','Mary');

--Create reciprocals (Edges)
SELECT  Friend1, Friend2
INTO    Edges
FROM    Friends
UNION
SELECT  Friend2, Friend1
FROM    Friends;

--Created Nodes
SELECT Friend1 AS Person
INTO   Nodes
FROM   Friends
UNION
SELECT  Friend2
FROM    Friends;

--Cross join all Edges and Nodes
SELECT  a.Friend1, a.Friend2, b.Person
INTO    Nodes_Edges_To_Evaluate
FROM    Edges a CROSS JOIN
        Nodes b
ORDER BY 1,2,3;

--Evaluates the cross join to the edges
WITH cte_JoinLogic AS
(
SELECT  a.Friend1
        ,a.Friend2
        ,'---' AS Id1
        ,b.Friend2 AS MutualFriend1
        ,'----' AS Id2
        ,c.Friend2 AS MutualFriend2
FROM   Nodes_Edges_To_Evaluate a LEFT OUTER JOIN
       Edges b ON a.Friend1 = b.Friend1 and a.Person = b.Friend2 LEFT OUTER JOIN
       Edges c ON a.Friend2 = c.Friend1 and a.Person = c.Friend2
),
cte_Predicate AS
(
--Apply predicate logic
SELECT  Friend1, Friend2, MutualFriend1 AS MutualFriend
FROM    cte_JoinLogic
WHERE   MutualFriend1 = MutualFriend2 AND MutualFriend1 IS NOT NULL AND MutualFriend2 IS NOT NULL
),
cte_Count AS
(
SELECT  Friend1, Friend2, COUNT(*) AS CountMutualFriends
FROM    cte_Predicate
GROUP BY Friend1, Friend2
)
SELECT  DISTINCT
        (CASE WHEN Friend1 < Friend2 THEN Friend1 ELSE Friend2 END) AS Friend1,
        (CASE WHEN Friend1 < Friend2 THEN Friend2 ELSE Friend1 END) AS Friend2,
        CountMutualFriends
FROM    cte_Count
ORDER BY 1,2;

/*----------------------------------------------------
Answer to Puzzle #43
Unbounded Preceding
*/----------------------------------------------------

DROP TABLE IF EXISTS CustomerOrders;

CREATE TABLE CustomerOrders
(
OrderID     INTEGER,
CustomerID  INTEGER,
Quantity    INTEGER NOT NULL,
PRIMARY KEY (OrderID, CustomerID)
);

INSERT INTO CustomerOrders (OrderID, CustomerID, Quantity) VALUES
(1,1001,5),(2,1001,8),(3,1001,3),(4,1001,7),
(1,2002,4),(2,2002,9);

SELECT  OrderID,
        CustomerID,
        Quantity,
        MIN(Quantity) OVER (PARTITION by CustomerID ORDER BY OrderID) AS MinQuantity
FROM    CustomerOrders;

/*----------------------------------------------------
Answer to Puzzle #44
Slowly Changing Dimension Part I
*/----------------------------------------------------

DROP TABLE IF EXISTS Balances;

CREATE TABLE Balances
(
CustomerID   INTEGER,
BalanceDate  DATE,
Amount       DECIMAL(19,4) NOT NULL,
PRIMARY KEY (CustomerID, BalanceDate)
);

INSERT INTO Balances (CustomerID, BalanceDate, Amount) VALUES
(1001,'2021-10-11',54.32),
(1001,'2021-10-10',17.65),
(1001,'2021-09-18',65.56),
(1001,'2021-09-12',56.23),
(1001,'2021-09-01',42.12),
(2002,'2021-10-15',46.52),
(2002,'2021-10-13',7.65),
(2002,'2021-09-15',75.12),
(2002,'2021-09-10',47.34),
(2002,'2021-09-02',11.11);

WITH cte_Customers AS
(
SELECT  CustomerID,
        BalanceDate,
        LAG(BalanceDate) OVER
                (PARTITION BY CustomerID ORDER BY BalanceDate DESC)
                    AS EndDate,
        Amount
FROM    Balances
)
SELECT  CustomerID,
        BalanceDate AS StartDate,
        COALESCE(EndDate - INTERVAL '1 day', '9999-12-31'::DATE) AS EndDate,
        Amount
FROM    cte_Customers
ORDER BY CustomerID, BalanceDate DESC;

/*----------------------------------------------------
Answer to Puzzle #45
Slowly Changing Dimension Part II
*/----------------------------------------------------

DROP TABLE IF EXISTS Balances;

CREATE TABLE Balances
(
CustomerID  INTEGER,
StartDate   DATE,
EndDate     DATE,
Amount      DECIMAL(19,4),
PRIMARY KEY (CustomerID, StartDate)
);

INSERT INTO Balances (CustomerID, StartDate, EndDate, Amount) VALUES
(1001,'2021-10-11','9999-12-31',54.32),
(1001,'2021-10-10','2021-10-10',17.65),
(1001,'2021-09-18','2021-10-12',65.56),
(2002,'2021-09-12','2021-09-17',56.23),
(2002,'2021-09-01','2021-09-17',42.12),
(2002,'2021-08-15','2021-08-31',16.32);

WITH cte_Lag AS
(
SELECT  CustomerID, StartDate, EndDate, Amount,
        LAG(StartDate) OVER
            (PARTITION BY CustomerID ORDER BY StartDate DESC) AS StartDate_Lag
FROM    Balances
)
SELECT  CustomerID, StartDate, EndDate, Amount, StartDate_Lag
FROM    cte_Lag
WHERE   EndDate >= StartDate_Lag
ORDER BY CustomerID, StartDate DESC;

/*----------------------------------------------------
Answer to Puzzle #46
Negative Account Balances
*/----------------------------------------------------

DROP TABLE IF EXISTS AccountBalances;

CREATE TABLE AccountBalances
(
AccountID  INTEGER,
Balance    DECIMAL(19,4),
PRIMARY KEY (AccountID, Balance)
);

INSERT INTO AccountBalances (AccountID, Balance) VALUES
(1001,234.45),(1001,-23.12),(2002,-93.01),(2002,-120.19),
(3003,186.76), (3003,90.23), (3003,10.11);

--Solution 1
--SET Operators
SELECT DISTINCT AccountID FROM AccountBalances WHERE Balance < 0
EXCEPT
SELECT DISTINCT AccountID FROM AccountBalances WHERE Balance > 0;

--Solution 2
--MAX
SELECT  AccountID
FROM    AccountBalances
GROUP BY AccountID
HAVING  MAX(Balance) < 0;

--Solution 3
--NOT IN
SELECT  DISTINCT AccountID
FROM    AccountBalances
WHERE   AccountID NOT IN (SELECT AccountID FROM AccountBalances WHERE Balance > 0);

--Solution 4
--NOT EXISTS with Correlated Subquery
SELECT  DISTINCT AccountID
FROM    AccountBalances a
WHERE   NOT EXISTS (SELECT AccountID FROM AccountBalances b WHERE Balance > 0 AND a.AccountID = b.AccountID);

--Solution 5
--LEFT OUTER JOIN
SELECT  DISTINCT a.AccountID
FROM    AccountBalances a LEFT OUTER JOIN
        AccountBalances b ON a.AccountID = b.AccountID AND b.Balance > 0
WHERE   b.AccountID IS NULL;

/*----------------------------------------------------
Answer to Puzzle #47
Work Schedule
*/----------------------------------------------------

DROP TABLE IF EXISTS Schedule CASCADE;
DROP TABLE IF EXISTS Activity CASCADE;
DROP TABLE IF EXISTS ScheduleTimes;
DROP TABLE IF EXISTS ActivityCoalesce;

CREATE TABLE Schedule
(
ScheduleId  CHAR(1) PRIMARY KEY,
StartTime   TIMESTAMP NOT NULL,
EndTime     TIMESTAMP NOT NULL
);

CREATE TABLE Activity
(
ScheduleID   CHAR(1) REFERENCES Schedule (ScheduleID),
ActivityName VARCHAR(100),
StartTime    TIMESTAMP,
EndTime      TIMESTAMP,
PRIMARY KEY (ScheduleID, ActivityName, StartTime, EndTime)
);

INSERT INTO Schedule (ScheduleID, StartTime, EndTime) VALUES
('A','2021-10-01 10:00:00'::TIMESTAMP,'2021-10-01 15:00:00'::TIMESTAMP),
('B','2021-10-01 10:15:00'::TIMESTAMP,'2021-10-01 12:15:00'::TIMESTAMP);

INSERT INTO Activity (ScheduleID, ActivityName, StartTime, EndTime) VALUES
('A','Meeting','2021-10-01 10:00:00'::TIMESTAMP,'2021-10-01 10:30:00'::TIMESTAMP),
('A','Break','2021-10-01 12:00:00'::TIMESTAMP,'2021-10-01 12:30:00'::TIMESTAMP),
('A','Meeting','2021-10-01 13:00:00'::TIMESTAMP,'2021-10-01 13:30:00'::TIMESTAMP),
('B','Break','2021-10-01 11:00:00'::TIMESTAMP,'2021-10-01 11:15:00'::TIMESTAMP);

--Step 1
SELECT  ScheduleID, StartTime AS ScheduleTime
INTO    ScheduleTimes
FROM    Schedule
UNION
SELECT  ScheduleID, EndTime FROM Schedule
UNION
SELECT  ScheduleID, StartTime FROM Activity
UNION
SELECT  ScheduleID, EndTime FROM Activity;

--Step 2
SELECT  a.ScheduleID
        ,a.ScheduleTime
        ,COALESCE(b.ActivityName, c.ActivityName, 'Work') AS ActivityName
INTO    ActivityCoalesce
FROM    ScheduleTimes a LEFT OUTER JOIN
        Activity b ON a.ScheduleTime = b.StartTime AND a.ScheduleId = b.ScheduleID LEFT OUTER JOIN
        Activity c ON a.ScheduleTime = c.EndTime AND a.ScheduleId = b.ScheduleID LEFT OUTER JOIN
        Schedule d ON a.ScheduleTime = d.StartTime AND a.ScheduleId = b.ScheduleID LEFT OUTER JOIN
        Schedule e ON a.ScheduleTime = e.EndTime AND a.ScheduleId = b.ScheduleID
ORDER BY a.ScheduleID, a.ScheduleTime;

--Step 3
WITH cte_Lead AS
(
SELECT  ScheduleID,
        ActivityName,
        ScheduleTime AS StartTime,
        LEAD(ScheduleTime) OVER (PARTITION BY ScheduleID ORDER BY ScheduleTime) AS EndTime
FROM    ActivityCoalesce
)
SELECT  ScheduleID, ActivityName, StartTime, EndTime
FROM    cte_Lead
WHERE   EndTime IS NOT NULL;

/*----------------------------------------------------
Answer to Puzzle #48
Consecutive Sales
*/----------------------------------------------------

DROP TABLE IF EXISTS Sales;

CREATE TABLE Sales
(
SalesID  INTEGER,
Year     INTEGER,
PRIMARY KEY (SalesID, Year)
);

INSERT INTO Sales (SalesID, Year) VALUES
(1001,2018),(1001,2019),(1001,2020),(2002,2020),(2002,2021),
(3003,2018),(3003,2020),(3003,2021),(4004,2019),(4004,2020),(4004,2021);

SELECT  SalesID
FROM    Sales
GROUP BY SalesID
HAVING  SUM(CASE WHEN Year = 2021     THEN 1 ELSE 0 END) > 0
    AND SUM(CASE WHEN Year = 2021 - 1 THEN 1 ELSE 0 END) > 0
    AND SUM(CASE WHEN Year = 2021 - 2 THEN 1 ELSE 0 END) > 0
ORDER BY SalesID;

/*----------------------------------------------------
Answer to Puzzle #49
Sumo Wrestlers
*/----------------------------------------------------

DROP TABLE IF EXISTS ElevatorOrder;

CREATE TABLE ElevatorOrder
(
LineOrder  INTEGER PRIMARY KEY,
Name       VARCHAR(100) NOT NULL,
Weight     INTEGER NOT NULL
);

INSERT INTO ElevatorOrder (Name, Weight, LineOrder)
VALUES
('Haruto',611,1),('Minato',533,2),('Haruki',623,3),
('Sota',569,4),('Aoto',610,5),('Hinata',525,6);

WITH cte_Running_Total AS
(
SELECT  Name, Weight, LineOrder,
        SUM(Weight) OVER (ORDER BY LineOrder) AS Running_Total
FROM    ElevatorOrder
)
SELECT  Name, Weight, LineOrder, Running_Total
FROM    cte_Running_Total
WHERE   Running_Total <= 2000
ORDER BY Running_Total DESC
LIMIT 1;

/*----------------------------------------------------
Answer to Puzzle #50
Baseball Balls and Strikes
*/----------------------------------------------------

DROP TABLE IF EXISTS Pitches;
DROP TABLE IF EXISTS BallsStrikes;
DROP TABLE IF EXISTS BallsStrikesSumWindow;
DROP TABLE IF EXISTS BallsStrikesLag;

CREATE TABLE Pitches
(
BatterID     INTEGER,
PitchNumber  INTEGER,
Result       VARCHAR(100) NOT NULL,
PRIMARY KEY (BatterID, PitchNumber)
);

INSERT INTO Pitches (BatterID, PitchNumber, Result) VALUES
(1001,1,'Foul'), (1001,2,'Foul'),(1001,3,'Ball'),(1001,4,'Ball'),(1001,5,'Strike'),
(2002,1,'Ball'),(2002,2,'Strike'),(2002,3,'Foul'),(2002,4,'Foul'),(2002,5,'Foul'),
(2002,6,'In Play'),(3003,1,'Ball'),(3003,2,'Ball'),(3003,3,'Ball'),
(3003,4,'Ball'),(4004,1,'Foul'),(4004,2,'Foul'),(4004,3,'Foul'),
(4004,4,'Foul'),(4004,5,'Foul'),(4004,6,'Strike');

SELECT  BatterID,
        PitchNumber,
        Result,
        (CASE WHEN Result = 'Ball' THEN 1 ELSE 0 END) AS Ball,
        (CASE WHEN Result IN ('Foul','Strike') THEN 1 ELSE 0 END) AS Strike
INTO    BallsStrikes
FROM    Pitches;

SELECT  BatterID,
        PitchNumber,
        Result,
        SUM(Ball) OVER (PARTITION BY BatterID ORDER BY PitchNumber) AS SumBall,
        SUM(Strike) OVER (PARTITION BY BatterID ORDER BY PitchNumber) AS SumStrike
INTO    BallsStrikesSumWindow
FROM    BallsStrikes;

SELECT  BatterID,
        PitchNumber,
        Result,
        SumBall,
        SumStrike,
        LAG(SumBall,1,0) OVER (PARTITION BY BatterID ORDER BY PitchNumber) AS SumBallLag,
        (CASE   WHEN Result IN ('Foul','In-Play') AND
                     LAG(SumStrike,1,0) OVER (PARTITION BY BatterID ORDER BY PitchNumber) >= 3 THEN 2
                WHEN Result = 'Strike' AND SumStrike >= 2 THEN 2
                ELSE LAG(SumStrike,1,0) OVER (PARTITION BY BatterID ORDER BY PitchNumber)
        END) AS SumStrikeLag
INTO    BallsStrikesLag
FROM    BallsStrikesSumWindow;

SELECT  BatterID,
        PitchNumber,
        Result,
        SumBallLag || ' - ' || SumStrikeLag AS StartOfPitchCount,
        (CASE WHEN Result = 'In Play' THEN Result
                ELSE SumBall || ' - ' || (CASE   WHEN Result = 'Foul' AND SumStrike >= 3 THEN 2
                                                    WHEN Result = 'Strike' AND SumStrike >= 2 THEN 3
                                                    ELSE SumStrike END)
        END) AS EndOfPitchCount
FROM    BallsStrikesLag
ORDER BY 1,2;

/*----------------------------------------------------
Answer to Puzzle #51
Primary Key Creation
*/----------------------------------------------------

DROP TABLE IF EXISTS Assembly;

CREATE TABLE Assembly
(
AssemblyID  INTEGER,
Part        VARCHAR(100),
PRIMARY KEY (AssemblyID, Part)
);

INSERT INTO Assembly (AssemblyID, Part) VALUES
(1001,'Bolt'),(1001,'Screw'),(2002,'Nut'),
(2002,'Washer'),(3003,'Toggle'),(3003,'Bolt');

SELECT  md5(AssemblyID::TEXT || Part) AS ExampleUniqueID,
        AssemblyID,
        Part
FROM    Assembly;

/*----------------------------------------------------
Answer to Puzzle #52
Phone Numbers Table
*/----------------------------------------------------

DROP TABLE IF EXISTS CustomerInfo;

CREATE TABLE CustomerInfo
(
CustomerID   INTEGER PRIMARY KEY,
PhoneNumber  VARCHAR(14) NOT NULL,
CONSTRAINT ckPhoneNumber CHECK (LENGTH(PhoneNumber) = 14
                            AND SUBSTRING(PhoneNumber,1,1) = '('
                            AND SUBSTRING(PhoneNumber,5,1) = ')'
                            AND SUBSTRING(PhoneNumber,6,1) = '-'
                            AND SUBSTRING(PhoneNumber,10,1) = '-')
);

INSERT INTO CustomerInfo (CustomerID, PhoneNumber) VALUES
(1001,'(555)-555-5555'),(2002,'(555)-555-5555'), (3003,'(555)-555-5555');

SELECT  CustomerID, PhoneNumber
FROM    CustomerInfo;

/*----------------------------------------------------
Answer to Puzzle #53
Spouse IDs
*/----------------------------------------------------

DROP TABLE IF EXISTS Spouses;

CREATE TABLE Spouses
(
PrimaryID  VARCHAR(100),
SpouseID   VARCHAR(100),
PRIMARY KEY (PrimaryID, SpouseID)
);

INSERT INTO Spouses (PrimaryID, SpouseID) VALUES
('Pat','Charlie'),('Jordan','Casey'),
('Ashley','Dee'),('Charlie','Pat'),
('Casey','Jordan'),('Dee','Ashley');

WITH cte_Reciprocals AS
(
SELECT
        (CASE WHEN PrimaryID < SpouseID THEN PrimaryID ELSE SpouseID END) AS ID1,
        (CASE WHEN PrimaryID > SpouseID THEN PrimaryID ELSE SpouseID END) AS ID2,
        PrimaryID,
        SpouseID
FROM    Spouses
),
cte_DenseRank AS
(
SELECT  DENSE_RANK() OVER (ORDER BY ID1) AS GroupID,
        ID1, ID2, PrimaryID, SpouseID
FROM    cte_Reciprocals
)
SELECT  GroupID,
        b.PrimaryID,
        b.SpouseID
FROM    cte_DenseRank a INNER JOIN
        Spouses b ON a.PrimaryID = b.PrimaryID AND a.SpouseID = b.SpouseID;

/*----------------------------------------------------
Answer to Puzzle #54
Winning the Lottery
*/----------------------------------------------------

DROP TABLE IF EXISTS WinningNumbers;
DROP TABLE IF EXISTS LotteryTickets;

CREATE TABLE WinningNumbers
(
Number  INTEGER PRIMARY KEY
);

INSERT INTO WinningNumbers (Number) VALUES
(25),(45),(78);

CREATE TABLE LotteryTickets
(
TicketID  VARCHAR(3),
Number    INTEGER,
PRIMARY KEY (TicketID, Number)
);

INSERT INTO LotteryTickets (TicketID, Number) VALUES
('AAA',25),('AAA',45),('AAA',78),
('BBB',25),('BBB',45),('BBB',98),
('CCC',67),('CCC',86),('CCC',91);

WITH cte_Ticket AS
(
SELECT  TicketID,
        COUNT(*) AS MatchingNumbers
FROM    LotteryTickets a INNER JOIN
        WinningNumbers b ON a.Number = b.Number
GROUP BY TicketID
),
cte_Payout AS
(
SELECT  (CASE WHEN MatchingNumbers = (SELECT COUNT(*) FROM WinningNumbers) THEN 100 ELSE 10 END) AS Payout
FROM    cte_Ticket
)
SELECT  SUM(Payout) AS TotalPayout
FROM    cte_Payout;

/*----------------------------------------------------
Answer to Puzzle #55
Table Audit
*/----------------------------------------------------

DROP TABLE IF EXISTS ProductsA;
DROP TABLE IF EXISTS ProductsB;

CREATE TABLE ProductsA
(
ProductName  VARCHAR(100) PRIMARY KEY,
Quantity     INTEGER NOT NULL
);

CREATE TABLE ProductsB
(
ProductName  VARCHAR(100) PRIMARY KEY,
Quantity     INTEGER NOT NULL
);

INSERT INTO ProductsA (ProductName, Quantity) VALUES
('Widget',7),
('Doodad',9),
('Gizmo',3);

INSERT INTO ProductsB (ProductName, Quantity) VALUES
('Widget',7),
('Doodad',6),
('Dingbat',9);

WITH cte_FullOuter AS
(
SELECT  a.ProductName AS ProductNameA,
        b.ProductName AS ProductNameB,
        a.Quantity AS QuantityA,
        b.Quantity AS QuantityB
FROM    ProductsA a FULL OUTER JOIN
        ProductsB b ON a.ProductName = b.ProductName
)
SELECT  'Matches in both table A and table B' AS Type,
        ProductNameA
FROM    cte_FullOuter
WHERE   ProductNameA = ProductNameB AND QuantityA = QuantityB
UNION
SELECT  'Product does not exist in table B' AS Type,
        ProductNameA
FROM    cte_FullOuter
WHERE   ProductNameB IS NULL
UNION
SELECT  'Product does not exist in table A' AS Type,
        ProductNameB
FROM   cte_FullOuter
WHERE  ProductNameA IS NULL
UNION
SELECT  'Quantities in table A and table B do not match' AS Type,
        ProductNameA
FROM    cte_FullOuter
WHERE   ProductNameA = ProductNameB AND QuantityA <> QuantityB;

/*----------------------------------------------------
Answer to Puzzle #56
Numbers Using Recursion
*/----------------------------------------------------

--Solution 1
--PostgreSQL has GENERATE_SERIES
SELECT value
FROM GENERATE_SERIES(1, 10) AS value;

--Solution 2
--Recursion
WITH RECURSIVE cte_Number (Number) AS
(
SELECT  1 AS Number
UNION ALL
SELECT  Number + 1
FROM    cte_Number
WHERE   Number < 10
)
SELECT  Number
FROM    cte_Number;

/*----------------------------------------------------
Answer to Puzzle #57
Find the Spaces
*/----------------------------------------------------

DROP TABLE IF EXISTS Strings;

CREATE TABLE Strings
(
QuoteId  SERIAL PRIMARY KEY,
String   VARCHAR(100) NOT NULL
);

INSERT INTO Strings (String) VALUES
('SELECT EmpID FROM Employees;'),('SELECT * FROM Transactions;');

WITH cte_StringSplit AS
(
SELECT  ROW_NUMBER() OVER (PARTITION BY a.QuoteId ORDER BY 1) AS RowNumber,
        a.QuoteId,
        a.String,
        b.Word,
        LENGTH(b.Word) AS WordLength
FROM    Strings a,
        LATERAL REGEXP_SPLIT_TO_TABLE(a.String, '\s+') WITH ORDINALITY AS b(Word, Ordinal)
)
SELECT RowNumber,
       QuoteID,
       String,
       POSITION(Word IN String) AS Starts,
       (POSITION(Word IN String) + WordLength) - 1 AS Ends,
       Word
FROM cte_StringSplit;

/*----------------------------------------------------
Answer to Puzzle #58
Add Them Up
*/----------------------------------------------------

DROP TABLE IF EXISTS Equations;

CREATE TABLE Equations
(
Equation  VARCHAR(200) PRIMARY KEY,
TotalSum  INTEGER NULL
);

INSERT INTO Equations (Equation) VALUES
('123'),('1+2+3'),('1+2-3'),('1+23'),('1-2+3'),('1-2-3'),('1-23'),('12+3'),('12-3');

--Solution using string manipulation
WITH cte_ReplacePositive AS
(
SELECT  Equation,
        REPLACE(Equation,'+',',') AS EquationReplace
FROM    Equations
),
cte_ReplaceNegative AS
(
SELECT  Equation,
        REPLACE(EquationReplace,'-',',-') AS EquationReplace
FROM    cte_ReplacePositive
),
cte_StringSplit AS
(
SELECT  a.Equation, value::INTEGER AS Value
FROM    cte_ReplaceNegative a,
        LATERAL REGEXP_SPLIT_TO_TABLE(EquationReplace, ',') AS value
WHERE   value <> ''
)
SELECT Equation, SUM(Value) AS EquationSum
FROM   cte_StringSplit
GROUP BY Equation;

/*----------------------------------------------------
Answer to Puzzle #59
Balanced String
-- This puzzle requires procedural logic which is more complex in PostgreSQL
-- Showing a simplified approach
*/----------------------------------------------------

DROP TABLE IF EXISTS BalancedString;

CREATE TABLE BalancedString
(
RowNumber        SERIAL PRIMARY KEY,
ExpectedOutcome  VARCHAR(50),
MatchString      VARCHAR(50),
UpdateString     VARCHAR(50)
);

INSERT INTO BalancedString (ExpectedOutcome, MatchString) VALUES
('Balanced','( )'),
('Balanced','[]'),
('Balanced','{}'),
('Balanced','( ( { [] } ) )'),
('Balanced','( ) [ ]'),
('Balanced','( { } )'),
('Unbalanced','( { ) }'),
('Unbalanced','( { ) }}}()'),
('Unbalanced','}{()][');

--Remove any spaces and initialize UpdateString
UPDATE BalancedString
SET MatchString = REPLACE(MatchString,' ',''),
    UpdateString = REPLACE(MatchString,' ','');

-- Note: The iterative WHILE loop approach requires PL/pgSQL
-- Here's a simplified check using a function or manual iteration
-- For a complete solution, you would use DO $$ ... $$ block with PL/pgSQL

/*----------------------------------------------------
Answer to Puzzle #60
Products Without Duplicates
*/----------------------------------------------------

DROP TABLE IF EXISTS Products;

CREATE TABLE Products
(
Product      VARCHAR(10),
ProductCode  VARCHAR(2),
PRIMARY KEY (Product, ProductCode)
);

INSERT INTO Products (Product, ProductCode) VALUES
('Alpha','01'),
('Alpha','02'),
('Bravo','03'),
('Charlie','02');

SELECT ProductCode
FROM   Products
GROUP BY ProductCode
HAVING COUNT(DISTINCT Product) = 1;

/*----------------------------------------------------
Answer to Puzzle #61
Player Scores
*/----------------------------------------------------

DROP TABLE IF EXISTS PlayerScores;

CREATE TABLE PlayerScores
(
AttemptID  INTEGER,
PlayerID   INTEGER,
Score      INTEGER,
PRIMARY KEY (AttemptID, PlayerID)
);

INSERT INTO PlayerScores (AttemptID, PlayerID, Score) VALUES
(1,1001,2),(2,1001,7),(3,1001,8),(1,2002,6),(2,2002,9),(3,2002,7);

WITH cte_FirstLastValues AS
(
SELECT  *
        ,FIRST_VALUE(Score) OVER (PARTITION BY PlayerID ORDER BY AttemptID) AS FirstValue
        ,LAST_VALUE(Score) OVER  (PARTITION BY PlayerID ORDER BY AttemptID
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastValue
        ,LAG(Score,1,99999999) OVER (PARTITION BY PlayerID ORDER BY AttemptID) AS LagScore
        ,CASE WHEN Score - LAG(Score,1,0) OVER (PARTITION BY PlayerID ORDER BY AttemptID) > 0 THEN 1 ELSE 0 END AS IsImproved
FROM    PlayerScores
)
SELECT  AttemptID
       ,PlayerID
       ,Score
       ,Score - FirstValue AS Difference_First
       ,Score - LastValue AS Difference_Last
       ,IsImproved AS IsPreviousScoreLower
       ,MIN(IsImproved) OVER (PARTITION BY PlayerID) AS IsOverallImproved
FROM   cte_FirstLastValues;

/*----------------------------------------------------
Answer to Puzzle #62
Car and Boat Purchase
*/----------------------------------------------------

DROP TABLE IF EXISTS Vehicles;

CREATE TABLE Vehicles (
VehicleID  INTEGER PRIMARY KEY,
Type       VARCHAR(20),
Model      VARCHAR(20),
Price      DECIMAL(19,4)
);

INSERT INTO Vehicles (VehicleID, Type, Model, Price) VALUES
(1, 'Car','Rolls-Royce Phantom', 460000),
(2, 'Car','Cadillac CT5', 39000),
(3, 'Car','Porsche Boxster', 63000),
(4, 'Car','Lamborghini Spyder', 290000),
(5, 'Boat','Malibu', 210000),
(6, 'Boat', 'ATX 22-S', 85000),
(7, 'Boat', 'Sea Ray SLX', 520000),
(8, 'Boat', 'Mastercraft', 25000);

SELECT  a.Model AS Car,
        b.Model AS Boat
FROM    Vehicles a CROSS JOIN
        Vehicles B
WHERE   a.Type = 'Car' AND
        b.Type = 'Boat' AND
        a.Price > b.Price + 200000
ORDER BY 1,2;

/*----------------------------------------------------
Answer to Puzzle #63
Promotion Codes
*/----------------------------------------------------

DROP TABLE IF EXISTS Promotions;

CREATE TABLE Promotions (
OrderID   INTEGER NOT NULL,
Product   VARCHAR(255) NOT NULL,
Discount  VARCHAR(255)
);

INSERT INTO Promotions (OrderID, Product, Discount) VALUES
(1, 'Item1', 'PROMO'),
(1, 'Item1', 'PROMO'),
(1, 'Item1', 'MARKDOWN'),
(1, 'Item2', 'PROMO'),
(2, 'Item2', NULL),
(2, 'Item3', 'MARKDOWN'),
(2, 'Item3', NULL),
(3, 'Item1', 'PROMO'),
(3, 'Item1', 'PROMO'),
(3, 'Item1', 'PROMO');

SELECT OrderID
FROM   Promotions
WHERE  Discount = 'PROMO'
GROUP BY OrderID
HAVING COUNT(DISTINCT Product) = 1;

/*----------------------------------------------------
Answer to Puzzle #64
Between Quotes
*/----------------------------------------------------

DROP TABLE IF EXISTS Strings;

CREATE TABLE Strings
(
ID      SERIAL PRIMARY KEY,
String  VARCHAR(256) NOT NULL
);

INSERT INTO Strings (String) VALUES
('"12345678901234"'),
('1"2345678901234"'),
('123"45678"901234"'),
('123"45678901234"'),
('12345678901"234"'),
('12345678901234');

WITH cte_Strings AS
(
SELECT  ID,
        String,
        (CASE WHEN LENGTH(String) - LENGTH(REPLACE(String,'"','')) <> 2 THEN 'Error' END) AS Result
FROM    Strings
),
cte_StringSplit AS
(
SELECT  ROW_NUMBER() OVER (PARTITION BY String ORDER BY 1) AS RowNumber,
        ID,
        String,
        Result,
        part AS Value
FROM    cte_Strings,
        LATERAL REGEXP_SPLIT_TO_TABLE(String, '"') AS part
)
SELECT  ID,
        String,
        (CASE WHEN LENGTH(Value) > 10 THEN 'True' ELSE 'False' END) AS Result
FROM    cte_StringSplit
WHERE   Result IS NULL AND
        RowNumber = 2
UNION
SELECT  ID,
        String,
        Result
FROM    cte_Strings
WHERE  Result = 'Error'
ORDER BY 1;

/*----------------------------------------------------
Answer to Puzzle #65
Home Listings
*/----------------------------------------------------

DROP TABLE IF EXISTS HomeListings;

CREATE TABLE HomeListings
(
ListingID  INTEGER PRIMARY KEY,
HomeID     VARCHAR(100),
Status     VARCHAR(100)
);

INSERT INTO HomeListings (ListingID, HomeID, Status) VALUES
(1, 'Home A', 'New Listing'),
(2, 'Home A', 'Pending'),
(3, 'Home A', 'Relisted'),
(4, 'Home B', 'New Listing'),
(5, 'Home B', 'Under Contract'),
(6, 'Home B', 'Relisted'),
(7, 'Home C', 'New Listing'),
(8, 'Home C', 'Under Contract'),
(9, 'Home C', 'Closed');

WITH cte_Case AS
(
SELECT  *,
        (CASE WHEN Status IN ('New Listing', 'Relisted') THEN 1 END) AS IsNewOrRelisted
FROM    HomeListings
)
SELECT  ListingID, HomeID, Status,
        SUM(IsNewOrRelisted) OVER (ORDER BY ListingID) AS GroupingID
FROM    cte_Case;

/*----------------------------------------------------
Answer to Puzzle #66
Matching Parts
*/----------------------------------------------------

DROP TABLE IF EXISTS Parts;

CREATE TABLE Parts
(
SerialNumber    VARCHAR(100) PRIMARY KEY,
ManufactureDay  INTEGER,
Product         VARCHAR(100)
);

INSERT INTO Parts (SerialNumber, ManufactureDay, Product) VALUES
('A111', 1, 'Bolt'),
('B111', 3, 'Bolt'),
('C111', 5, 'Bolt'),
('D222', 2, 'Washer'),
('E222', 4, 'Washer'),
('F222', 6, 'Washer'),
('G333', 3, 'Nut'),
('H333', 5, 'Nut'),
('I333', 7, 'Nut');

WITH cte_RowNumber AS
(
SELECT  ROW_NUMBER() OVER (PARTITION BY Product ORDER BY ManufactureDay) AS RowNumber,
        *
FROM    Parts
)
SELECT  a.SerialNumber AS Bolt,
        b.SerialNumber AS Washer,
        c.SerialNumber AS Nut
FROM    (SELECT * FROM cte_RowNumber WHERE Product = 'Bolt') a INNER JOIN
        (SELECT * FROM cte_RowNumber WHERE Product = 'Washer') b ON a.RowNumber = b.RowNumber INNER JOIN
        (SELECT * FROM cte_RowNumber WHERE Product = 'Nut') c ON a.RowNumber = c.RowNumber;

/*----------------------------------------------------
Answer to Puzzle #67
Matching Birthdays
*/----------------------------------------------------

DROP TABLE IF EXISTS Students;

CREATE TABLE Students
(
StudentName  VARCHAR(50) PRIMARY KEY,
Birthday     DATE
);

INSERT INTO Students (StudentName, Birthday) VALUES
('Susan', '2015-04-15'),
('Tim', '2015-04-15'),
('Jacob', '2015-04-15'),
('Earl', '2015-02-05'),
('Mike', '2015-05-23'),
('Angie', '2015-05-23'),
('Jenny', '2015-11-19'),
('Michelle', '2015-12-12'),
('Aaron', '2015-12-18');

SELECT  Birthday, STRING_AGG(StudentName, ', ') AS Students
FROM    Students
GROUP BY Birthday
HAVING  COUNT(*) > 1;

/*----------------------------------------------------
Answer to Puzzle #68
Removing Outliers
*/----------------------------------------------------

DROP TABLE IF EXISTS Teams;

CREATE TABLE Teams (
Team    VARCHAR(50),
Year    INTEGER,
Score   INTEGER,
PRIMARY KEY (Team, Year)
);

INSERT INTO Teams (Team, Year, Score) VALUES
('Cougars', 2015, 50),
('Cougars', 2016, 45),
('Cougars', 2017, 65),
('Cougars', 2018, 92),
('Bulldogs', 2015, 65),
('Bulldogs', 2016, 60),
('Bulldogs', 2017, 58),
('Bulldogs', 2018, 12);

WITH
cte_SummaryStatistics AS
(
SELECT  AVG(Score) OVER (PARTITION BY Team) AS AverageScore
       ,a.*
FROM   Teams a
),
cte_RowNumber AS
(
SELECT  ROW_NUMBER() OVER (PARTITION BY Team ORDER BY ABS(Score - AverageScore) DESC) AS RowNumber,
        *
FROM    cte_SummaryStatistics
)
SELECT Team, AVG(Score) AS Score
FROM   cte_RowNumber
WHERE  RowNumber <> 1
GROUP BY Team;

/*----------------------------------------------------
Answer to Puzzle #69
Splitting a Hierarchy
*/----------------------------------------------------

DROP TABLE IF EXISTS OrganizationChart;
DROP TABLE IF EXISTS OrganizationChartSummary;

CREATE TABLE OrganizationChart
(
ManagerID   CHAR(1),
EmployeeID  CHAR(1) NOT NULL PRIMARY KEY
);

INSERT INTO OrganizationChart (ManagerID, EmployeeID) VALUES
(NULL, 'A'),
('A', 'B'),
('A', 'C'),
('B', 'D'),
('B', 'E'),
('D', 'G'),
('C', 'F');

CREATE TABLE OrganizationChartSummary
(
Summary  VARCHAR(5000) NOT NULL PRIMARY KEY
);

--Seed the table
INSERT INTO OrganizationChartSummary (Summary)
SELECT  EmployeeID
FROM    OrganizationChart
WHERE   ManagerID IS NULL;

-- Note: The WHILE loop approach requires PL/pgSQL
-- For demonstration, using a recursive CTE instead:
WITH RECURSIVE cte_Hierarchy AS (
    SELECT EmployeeID::TEXT AS Summary
    FROM OrganizationChart
    WHERE ManagerID IS NULL
    UNION ALL
    SELECT h.Summary || ' / ' || o.EmployeeID
    FROM cte_Hierarchy h
    JOIN OrganizationChart o ON RIGHT(h.Summary, 1) = o.ManagerID
)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY Summary) AS GroupID,
    TRIM(value) AS EmployeeID
FROM cte_Hierarchy,
     LATERAL REGEXP_SPLIT_TO_TABLE(Summary, ' / ') AS value
WHERE LENGTH(Summary) - LENGTH(REPLACE(Summary, '/', '')) = 1
  AND LENGTH(Summary) > 1;

/*----------------------------------------------------
Answer to Puzzle #70
Student Facts
*/----------------------------------------------------

DROP TABLE IF EXISTS Students;

CREATE TABLE Students
(
ParentID  INTEGER NOT NULL,
ChildID   CHAR(1) PRIMARY KEY,
Age       INTEGER NOT NULL,
Gender    CHAR(1) NOT NULL
);

INSERT INTO Students (ParentID, ChildID, Age, Gender) VALUES
(1001, 'A', 8, 'M'),
(1001, 'B', 12, 'F'),
(2002, 'C', 7, 'F'),
(2002, 'D', 9, 'F'),
(2002, 'E', 14, 'M'),
(3003, 'F', 12, 'F'),
(3003, 'G', 14, 'M'),
(4004, 'H', 7, 'M');

WITH cte_LagAgeGap AS
(
SELECT  ParentID,
        AGE - LAG(AGE,1) OVER (PARTITION BY ParentID ORDER BY AGE) AS AgeDifference
FROM    Students
GROUP BY ParentID, Age
),
cte_MaxAgeGap AS
(
SELECT  ParentID,
        MAX(AgeDifference) AS MaxAgeDifference
FROM    cte_LagAgeGap
GROUP BY ParentID
HAVING COUNT(*) >= 2
)
SELECT  a.ParentID,
        COUNT(*) AS NumberChildren,
        AVG(a.Age::FLOAT) AS AverageAge,
        CASE WHEN COUNT(*) = 1 THEN NULL ELSE MAX(a.Age) - MIN(Age) END AS AgeDifference,
        b.MaxAgeDifference,
        MIN(a.Age) AS YoungestAge,
        MAX(a.Age) AS OldestAge,
        STRING_AGG(a.Gender, ', ') AS Genders
FROM    Students a LEFT OUTER JOIN
        cte_MaxAgeGap b ON a.ParentID = b.ParentID
GROUP BY a.ParentID, b.MaxAgeDifference
ORDER BY 1;

/*----------------------------------------------------
Answer to Puzzle #71
Employee Validation
-- Note: Triggers have different syntax in PostgreSQL
*/----------------------------------------------------

DROP TABLE IF EXISTS TemporaryEmployees CASCADE;
DROP TABLE IF EXISTS PermanentEmployees CASCADE;
DROP TABLE IF EXISTS Employees CASCADE;

CREATE TABLE Employees
(
EmployeeID  INTEGER PRIMARY KEY,
Name        VARCHAR(50) NOT NULL
);

CREATE TABLE TemporaryEmployees
(
EmployeeID  INTEGER PRIMARY KEY REFERENCES Employees(EmployeeID),
Department  VARCHAR(50) NOT NULL
);

CREATE TABLE PermanentEmployees
(
EmployeeID  INTEGER PRIMARY KEY REFERENCES Employees(EmployeeID),
Department  VARCHAR(50) NOT NULL
);

INSERT INTO Employees (EmployeeID, Name) VALUES
(1001, 'John'),
(2002, 'Eric'),
(3003, 'Jennifer'),
(4004, 'Bob'),
(5005, 'Stuart'),
(6006, 'Angie');

INSERT INTO TemporaryEmployees (EmployeeID, Department) VALUES
(1001, 'Engineering'),
(2002, 'Sales'),
(3003, 'Marketing');

INSERT INTO PermanentEmployees (EmployeeID, Department) VALUES
(4004, 'Marketing'),
(5005, 'Accounting'),
(6006, 'Accounting');

-- Create trigger functions for PostgreSQL
CREATE OR REPLACE FUNCTION check_permanent_before_insert_temp()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM PermanentEmployees WHERE EmployeeID = NEW.EmployeeID) THEN
        RAISE EXCEPTION 'Employee ID already exists in PermanentEmployees.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_temporary_before_insert_perm()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM TemporaryEmployees WHERE EmployeeID = NEW.EmployeeID) THEN
        RAISE EXCEPTION 'Employee ID already exists in TemporaryEmployees.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_permanent_before_insert_temp
BEFORE INSERT ON TemporaryEmployees
FOR EACH ROW EXECUTE FUNCTION check_permanent_before_insert_temp();

CREATE TRIGGER trg_check_temporary_before_insert_perm
BEFORE INSERT ON PermanentEmployees
FOR EACH ROW EXECUTE FUNCTION check_temporary_before_insert_perm();

/*----------------------------------------------------
Answer to Puzzle #72
Under Warranty
*/----------------------------------------------------

DROP TABLE IF EXISTS Repairs;

CREATE TABLE Repairs (
RepairID    INTEGER PRIMARY KEY,
CustomerID  CHAR(1) NOT NULL,
RepairDate  DATE NOT NULL
);

INSERT INTO Repairs (RepairID, CustomerID, RepairDate) VALUES
(1001,'A','2023-01-01'),
(2002,'A','2023-01-15'),
(3003,'A','2023-01-17'),
(4004,'A','2023-03-24'),
(5005,'A','2023-04-01'),
(6006,'B','2023-06-22'),
(7007,'B','2023-06-23'),
(8008,'B','2023-09-01');

WITH cte_Lag AS
(
SELECT  *,
        LAG(RepairDate,1) OVER (PARTITION BY CustomerID ORDER BY RepairDate) AS LagRepairDate,
        LAG(RepairID,1)   OVER (PARTITION BY CustomerID ORDER BY RepairDate) AS LagRepairID
FROM    Repairs
),
cte_DateDiff AS
(
SELECT  RepairDate - LagRepairDate AS LagDateDiff,
        ROW_NUMBER() OVER (ORDER BY RepairDate) AS RowNumber,
        *
FROM cte_Lag
),
cte_GroupKey AS
(
SELECT  CASE WHEN LagDateDiff > 30 THEN 1 END AS GroupKey,
        *
FROM    cte_DateDiff
),
cte_Sum AS
(
SELECT  *,
        SUM(GroupKey) OVER (PARTITION BY CustomerID ORDER BY RowNumber) AS GroupingID
FROM    cte_GroupKey
),
cte_RowNumber AS
(
SELECT  *
        ,ROW_NUMBER() OVER (PARTITION BY CustomerID, GroupingID ORDER BY GroupingID, RepairDate) - 1 AS SequenceNumber
FROM    cte_Sum
)
SELECT  CustomerID
        ,RepairID
        ,LagRepairID AS PreviousRepaidID
        ,RepairDate
        ,LagRepairDate AS PreviousRepairDate
        ,SequenceNumber
        ,LagDateDiff AS RepaidGapDays
FROM    cte_RowNumber
WHERE   SequenceNumber <> 0;

/*----------------------------------------------------
Answer to Puzzle #73
Distinct Statuses
*/----------------------------------------------------
DROP TABLE IF EXISTS WorkflowSteps;

CREATE TABLE WorkflowSteps
(
StepID    INTEGER PRIMARY KEY,
Workflow  VARCHAR(50),
Status    VARCHAR(50)
);

INSERT INTO WorkflowSteps (StepID, Workflow, Status) VALUES
(1, 'Alpha', 'Open'),
(2, 'Alpha', 'Open'),
(3, 'Alpha', 'Inactive'),
(4, 'Alpha', 'Open'),
(5, 'Bravo', 'Closed'),
(6, 'Bravo', 'Closed'),
(7, 'Bravo', 'Open'),
(8, 'Bravo', 'Inactive');

SELECT  a.StepID,
        a.Workflow,
        a.Status,
        COUNT(DISTINCT b.Status) AS Count
FROM    WorkflowSteps a INNER JOIN
        WorkflowSteps b ON a.StepID >= b.StepID AND a.Workflow = b.Workflow
GROUP BY a.StepID, a.Workflow, a.Status
ORDER BY 1;

/*----------------------------------------------------
Answer to Puzzle #74
Bowling League
*/----------------------------------------------------
DROP TABLE IF EXISTS BowlingResults;

CREATE TABLE BowlingResults
(
GameID  INTEGER,
Bowler  VARCHAR(50),
Score   INTEGER,
PRIMARY KEY (GameID, Bowler)
);

INSERT INTO BowlingResults (GameID, Bowler, Score) VALUES
(1, 'John', 167),
(1, 'Susan', 139),
(1, 'Ralph', 95),
(1, 'Mary', 90),
(2, 'Susan', 187),
(2, 'John', 155),
(2, 'Dennis', 100),
(2, 'Anthony', 78);

WITH cte_Lead AS
(
SELECT  *,
        LEAD(Bowler,1) OVER (PARTITION BY GameID ORDER BY Score DESC) AS LeadBowler
FROM    BowlingResults
),
cte_Least_Greatest AS
(
SELECT  GameID,
        LEAST(Bowler,LeadBowler) AS Bowler1,
        GREATEST(Bowler,LeadBowler) AS Bowler2
FROM    cte_Lead a
)
SELECT  Bowler1,
        Bowler2,
        COUNT(*) AS Count
FROM    cte_Least_Greatest
WHERE   Bowler1 IS NOT NULL AND Bowler2 IS NOT NULL
GROUP BY Bowler1, Bowler2
ORDER BY 3 DESC;

/*----------------------------------------------------
Answer to Puzzle #75
Symmetric Matches
*/----------------------------------------------------
DROP TABLE IF EXISTS Boxes;

CREATE TABLE Boxes
(
Box      CHAR(1) PRIMARY KEY,
Length   INTEGER,
Width    INTEGER,
Height   INTEGER
);

INSERT INTO Boxes (Box, Length, Width, Height) VALUES
('A', 10, 25, 15),
('B', 15, 10, 25),
('C', 10, 16, 24);

WITH cte_StringAgg AS
(
SELECT  Box,
        STRING_AGG(value::TEXT, ',' ORDER BY value) AS SortedDims
FROM    Boxes,
        LATERAL (VALUES (Length), (Width), (Height)) AS D(value)
GROUP BY Box
),
cte_GroupID AS
(
SELECT  DISTINCT
        SortedDims,
        DENSE_RANK() OVER (ORDER BY SortedDims) AS GroupingID
FROM    cte_StringAgg
)
SELECT  n.Box,
        g.GroupingID
FROM    cte_StringAgg n INNER JOIN
        cte_GroupID g ON n.SortedDims = g.SortedDims
ORDER BY n.Box;

/*----------------------------------------------------
Answer to Puzzle #76
Determine Batches
*/----------------------------------------------------
DROP TABLE IF EXISTS BatchStarts;
DROP TABLE IF EXISTS BatchLines;

CREATE TABLE BatchStarts
(
Batch       CHAR(1),
BatchStart  INTEGER,
PRIMARY KEY (Batch, BatchStart)
);

CREATE TABLE BatchLines
(
Batch   CHAR(1),
Line    INTEGER,
Syntax  TEXT,
PRIMARY KEY (Batch, Line)
);

INSERT INTO BatchStarts (Batch, BatchStart) VALUES
('A', 1),
('A', 5);

INSERT INTO BatchLines (Batch, Line, Syntax) VALUES
('A', 1, 'SELECT *'),
('A', 2, 'FROM Account;'),
('A', 3, 'GO'),
('A', 4, ''),
('A', 5, 'TRUNCATE TABLE Accounts;'),
('A', 6, 'GO');

--Solution 1
--CTE with MIN
WITH cte_BatchLines_Go AS
(
SELECT  *
FROM    BatchLines
WHERE   Syntax = 'GO'
)
SELECT  a.Batch, a.BatchStart, MIN(b.Line) AS MinLine
FROM    BatchStarts a LEFT JOIN
        cte_BatchLines_Go b ON b.Line >= a.BatchStart AND a.Batch = b.Batch
GROUP BY a.Batch, a.BatchStart;

--Solution 2
--Correlated Subquery using LATERAL
SELECT  a.*,
        b.MinLine
FROM    BatchStarts a,
        LATERAL (SELECT MIN(Line) AS MinLine
                 FROM   BatchLines b
                 WHERE  b.Line >= a.BatchStart AND Syntax = 'GO' AND a.Batch = b.Batch) b;

/*----------------------------------------------------
Answer to Puzzle #77
Temperature Readings
-- Note: PostgreSQL doesn't support IGNORE NULLS directly
-- Using a workaround
*/----------------------------------------------------
DROP TABLE IF EXISTS TemperatureData;

CREATE TABLE TemperatureData
(
TempID     INTEGER PRIMARY KEY,
TempValue  INTEGER NULL
);

INSERT INTO TemperatureData (TempID, TempValue) VALUES
(1,52),(2,NULL),(3,NULL),(4,65),(5,NULL),(6,72),
(7,NULL),(8,70),(9,NULL),(10,75),(11,NULL),(12,80);

-- Workaround for LAG/LEAD IGNORE NULLS
WITH cte_filled AS (
    SELECT
        TempID,
        TempValue,
        -- Forward fill (last non-null value)
        FIRST_VALUE(TempValue) OVER (
            PARTITION BY grp_forward
            ORDER BY TempID
        ) AS forward_fill
    FROM (
        SELECT *,
            COUNT(TempValue) OVER (ORDER BY TempID) AS grp_forward
        FROM TemperatureData
    ) sub
),
cte_backward AS (
    SELECT
        TempID,
        TempValue,
        -- Backward fill (next non-null value)
        FIRST_VALUE(TempValue) OVER (
            PARTITION BY grp_backward
            ORDER BY TempID DESC
        ) AS backward_fill
    FROM (
        SELECT *,
            COUNT(TempValue) OVER (ORDER BY TempID DESC) AS grp_backward
        FROM TemperatureData
    ) sub
)
SELECT
    a.TempID,
    COALESCE(a.TempValue, GREATEST(a.forward_fill, b.backward_fill)) AS TempValue
FROM cte_filled a
JOIN cte_backward b ON a.TempID = b.TempID
ORDER BY 1;

/*----------------------------------------------------
The End
*/----------------------------------------------------
