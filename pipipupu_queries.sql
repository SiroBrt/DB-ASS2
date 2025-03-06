-- QUERIES -------------------------------------------
-- -----------------------------------------------------

--  ------------------  BoreBooks--  --------------------
--  -----------------------------------------------------
--  Books: 
--      whose editions are in AT LEAST 3 different languages 
--      whose copies that have NEVER been loaned
WITH 
    B3 AS (
        SELECT COUNT(DISTINCT LANGUAGE), TITLE, AUTHOR
        FROM EDITIONS
        GROUP BY TITLE, AUTHOR HAVING COUNT(DISTINCT LANGUAGE) > 2
    )                                       -- books with editions on more than 2 different languages
SELECT DISTINCT TITLE, AUTHOR
    FROM B3                              
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
--  --------------------------------------------------------------
WITH 
    TOTAL_LOANS_BY_DRIVER AS (
        SELECT 
            CASE
                WHEN SUM(N_LOANS) IS NULL THEN 0
                ELSE SUM(N_LOANS) 
            END AS TOTAL_LOANS, 
            SERVICES.PASSPORT
        FROM SERVICES 
        LEFT JOIN (
        SELECT COUNT(*) AS N_LOANS, TOWN, PROVINCE, STOPDATE 
            FROM LOANS
            GROUP BY TOWN, PROVINCE, STOPDATE
            ORDER BY COUNT(*) DESC
        ) N_LOANS_BY_SERVICE
        ON SERVICES.TOWN = N_LOANS_BY_SERVICE.TOWN
            AND SERVICES.PROVINCE = N_LOANS_BY_SERVICE.PROVINCE
            AND SERVICES.TASKDATE = N_LOANS_BY_SERVICE.STOPDATE
        GROUP BY SERVICES.PASSPORT
        ORDER BY TOTAL_LOANS DESC
    ),
    UNRETURNED_LOANS_BY_DRIVER AS (
        SELECT 
            CASE
                WHEN SUM(N_LOANS) IS NULL THEN 0
                ELSE SUM(N_LOANS) 
            END AS UNRETURNED_LOANS, 
            SERVICES.PASSPORT
        FROM SERVICES 
        LEFT JOIN (
        SELECT COUNT(*) AS N_LOANS, TOWN, PROVINCE, STOPDATE 
            FROM LOANS
            WHERE RETURN < TRUNC(SYSDATE)
            GROUP BY TOWN, PROVINCE, STOPDATE
            ORDER BY COUNT(*) DESC
        ) N_UNRETURNED_LOANS_BY_SERVICE
        ON SERVICES.TOWN = N_UNRETURNED_LOANS_BY_SERVICE.TOWN
            AND SERVICES.PROVINCE = N_UNRETURNED_LOANS_BY_SERVICE.PROVINCE
            AND SERVICES.TASKDATE = N_UNRETURNED_LOANS_BY_SERVICE.STOPDATE
        GROUP BY SERVICES.PASSPORT
        ORDER BY UNRETURNED_LOANS DESC
    )
SELECT
    D.FULLNAME, 
    FLOOR(
        MONTHS_BETWEEN(
            TRUNC(sysdate),
            D.BIRTHDATE
        )/12
    ) AS AGE, 
    CASE
        WHEN D.CONT_END IS NULL THEN NULL
        ELSE FLOOR((D.CONT_END - D.CONT_START)/365.25)
    END AS CONTRACTED_YEARS,
    -- AS ACTIVE_YEARS, 
    -- AS STOPS_PER_ACTIVE_YEAR,
    -- AS LOANS_PER_ACTIVE_YEAR,
    UNRETURNED_LOANS_RATE.RATE AS RATE
FROM DRIVERS D
JOIN (
    SELECT 
        TOTAL_LOANS_BY_DRIVER.PASSPORT, 
        CASE
            WHEN TOTAL_LOANS_BY_DRIVER.TOTAL_LOANS = 0 THEN 0
            ELSE
                UNRETURNED_LOANS_BY_DRIVER.UNRETURNED_LOANS/TOTAL_LOANS_BY_DRIVER.TOTAL_LOANS 
        END AS RATE
    FROM TOTAL_LOANS_BY_DRIVER
    JOIN UNRETURNED_LOANS_BY_DRIVER
    ON TOTAL_LOANS_BY_DRIVER.PASSPORT = UNRETURNED_LOANS_BY_DRIVER.PASSPORT
) UNRETURNED_LOANS_RATE
ON D.PASSPORT = UNRETURNED_LOANS_RATE.PASSPORT
;

