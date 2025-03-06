-- QUERIES -------------------------------------------
-- -----------------------------------------------------

--  ------------------  BoreBooks--  --------------------
--  -----------------------------------------------------
--  Books: 
--      whose editions are in AT LEAST 3 different languages 
--      whose copies that have NEVER been loaned
SELECT DISTINCT TITLE, AUTHOR
FROM (
    SELECT COUNT(DISTINCT LANGUAGE), TITLE, AUTHOR
    FROM EDITIONS
    GROUP BY TITLE, AUTHOR HAVING COUNT(DISTINCT LANGUAGE) > 2
) B3                                    -- books with editions on more than 2 different languages
WHERE (TITLE, AUTHOR) NOT IN ( 
    SELECT DISTINCT TITLE, AUTHOR
    FROM EDITIONS
    WHERE ISBN IN (
        SELECT DISTINCT ISBN
        FROM COPIES C
        JOIN LOANS L
        ON C.SIGNATURE = L.SIGNATURE
    )                                   -- editions that were loaned at least once
)                                       -- books that were laoned at least once
;
-- 60 rows

--  ------------------  Reports on Employees  --------------------
