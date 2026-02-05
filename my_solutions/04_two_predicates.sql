WITH CaliforniaCustomers AS (
    SELECT CustomerID
    FROM Orders
    WHERE DeliveryState = 'CA'
)

SELECT o.*
FROM Orders o 
JOIN CaliforniaCustomers c
ON o.CustomerID = c.CustomerID
WHERE o.DeliveryState = 'TX';
