WITH t AS (
    SELECT
        EmployeeID,
        ARRAY_AGG(License ORDER BY License) AS Licenses
    FROM Employees
    GROUP BY EmployeeID
)

SELECT DISTINCT
    t1.EmployeeID,
    t2.EmployeeID,
    ARRAY_LENGTH(t1.Licenses, 1) AS Count
FROM t t1
JOIN t t2
ON t1.Licenses = t2.Licenses
    AND t1.EmployeeID <> t2.EMployeeID
ORDER BY 1, 2;