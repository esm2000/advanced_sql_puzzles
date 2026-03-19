SELECT *, SUM(QuantityAdjustment) OVER (ORDER BY InventoryDate) AS Inventory
FROM Inventory;