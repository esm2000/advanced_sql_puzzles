WITH DistinctCandidates AS (
        SELECT DISTINCT CandidateID, Occupation
        FROM Candidates
    ),

    RequirementCounts AS (
        SELECT d.CandidateID, COUNT(*) AS count
        FROM DistinctCandidates d
        JOIN Requirements r 
        ON d.Occupation = r.Requirement
        GROUP BY 1
    )

SELECT CandidateID
FROM RequirementCounts
WHERE count = (SELECT COUNT(*) FROM Requirements);

