SELECT
    c1.Item AS "Item Cart 1",
    c2.Item AS "Item Cart 2"
FROM Cart1 c1 
FULL JOIN Cart2 c2 
ON c1.Item = c2.Item;