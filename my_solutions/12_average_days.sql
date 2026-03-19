
WITH 

a AS (
    SELECT 
        *,
        LAG(ExecutionDate, 1) OVER (PARTITION BY WorkFlow ORDER BY ExecutionDate) AS LastExecutionDate
    FROM ProcessLog
),

b AS (
    SELECT
        WorkFlow,
        ExecutionDate - LastExecutionDate AS DaysBetween
    FROM a
)

SELECT
    WorkFlow,
    FLOOR(AVG(DaysBetween)) AS AverageDays
FROM b
GROUP BY 1;