WITH 

    ranks AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY IntegerValue) AS row_number,
            IntegerValue AS value
        FROM SampleData
    ),

    mean AS (
        SELECT
            'mean' AS metric, 
            ROUND(SUM(IntegerValue) / COUNT(IntegerValue), 2) AS value
        FROM SampleData
    ),

    median AS (
        SELECT 
            'median' AS metric,
            ROUND(AVG(value), 2) AS value
        FROM ranks
        WHERE row_number IN (
            (
                SELECT 
                    CASE 
                        WHEN count % 2 = 0 THEN count / 2
                        ELSE count / 2 + 1
                    END
                FROM (SELECT COUNT(*) AS count FROM SampleData)
            ), 
            (
                SELECT 
                    count / 2 + 1
                FROM (SELECT COUNT(*) AS count FROM SampleData)
            )
        )
    ),

    mode AS (
        SELECT
            'mode' AS metric,
            IntegerValue AS value,
            COUNT(*) AS count
        FROM SampleData
        GROUP BY IntegerValue
        ORDER BY 3 DESC
        LIMIT 1
    ),

    range_metric AS (
        SELECT 
            'range' AS metric,
            MAX(IntegerValue) - MIN(IntegerValue) value
        FROM SampleData
    )


SELECT metric, value FROM mean 

UNION ALL

SELECT metric, value FROM median 

UNION ALL 

SELECT metric, value FROM mode

UNION ALL

SELECT metric, value FROM range_metric;
