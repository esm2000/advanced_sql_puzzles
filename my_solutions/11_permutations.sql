SELECT
    CONCAT(t1.TestCase, ',', t2.TestCase, ',', t3.TestCase) AS "Test Cases"
FROM TestCases t1
JOIN TestCases t2
ON t1.TestCase != t2.TestCase
JOIN TestCases t3
ON t2.TestCase != t3.TestCase
    AND t1.TestCase != t3.TestCase;