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
SELECT
    FULLNAME, 
    FLOOR(
        MONTHS_BETWEEN(
            TRUNC(sysdate),
            BIRTHDATE
        )/12
    ) AS AGE, 
    BIRTHDATE,
    CASE
        WHEN CONT_END IS NULL THEN NULL
        ELSE FLOOR((CONT_END - CONT_START)/365.25)
    END AS CONTRACTED_YEARS
    -- AS ACTIVE_YEARS, 
    -- AS STOPS_PER_ACTIVE_YEAR,
    -- AS LOANS_PER_ACTIVE_YEAR,
    -- AS UNRETURNED_LOANS
FROM DRIVERS;
