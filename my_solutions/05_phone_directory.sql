WITH base AS (
    SELECT
        CustomerID,
        MAX(PhoneNumber) AS Cellular,
        NULL AS Work,
        NULL AS Home
    FROM PhoneDirectory
    WHERE Type = 'Cellular'
    GROUP BY CustomerID

    UNION ALL

    SELECT
        CustomerID,
        NULL AS Cellular,
        MAX(PhoneNumber) AS Work,
        NULL AS Home
    FROM PhoneDirectory
    WHERE Type = 'Work'
    GROUP BY CustomerID


    UNION ALL 

    SELECT
        CustomerID,
        NULL AS Cellular,
        NULL AS Work,
        MAX(PhoneNumber) AS Home
    FROM PhoneDirectory
    WHERE Type = 'Home'
    GROUP BY CustomerID
)

SELECT 
    CustomerID,
    MAX(Cellular) AS Cellular,
    MAX(Work) AS Work,
    MAX(Home) AS Home
FROM base
GROUP BY CustomerID;