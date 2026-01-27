
WITH RECURSIVE employee_hierarchy AS (
    SELECT 
        EmployeeID,
        ManagerID,
        JobTitle,
        0 AS Depth
    FROM Employees
    WHERE JobTitle = 'CEO'
    
    UNION ALL

    SELECT 
        e.EmployeeID,
        e.ManagerID,
        e.JobTitle,
        h.Depth + 1 AS Depth
    FROM employee_hierarchy h
    JOIN Employees e 
    ON h.EmployeeID = e.ManagerID
)

SELECT * FROM employee_hierarchy;