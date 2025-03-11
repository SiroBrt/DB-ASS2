-- ---------------------- QUERIES ---------------------
-- ----------------------------------------------------

--  ------------------  BoreBooks  ----------------------
--  -----------------------------------------------------
--  Books: 
--      B3: whose editions are in AT LEAST 3 different languages 
--          whose copies that have NEVER been loaned
WITH 
    B3 AS (
        SELECT COUNT(DISTINCT LANGUAGE), TITLE, AUTHOR
        FROM EDITIONS
        GROUP BY TITLE, AUTHOR HAVING COUNT(DISTINCT LANGUAGE) > 2
    ),
    LB AS ( 
        SELECT DISTINCT TITLE, AUTHOR
        FROM EDITIONS
        WHERE ISBN IN (
            SELECT DISTINCT ISBN
            FROM COPIES C
            JOIN LOANS L
            ON C.SIGNATURE = L.SIGNATURE
        )                                     -- editions that were loaned at least once
    )                                         -- books that were laoned at least once
SELECT DISTINCT B3.TITLE, B3.AUTHOR
    FROM B3
    LEFT JOIN LB                              
    ON LB.TITLE = B3.TITLE AND LB.AUTHOR = B3.AUTHOR
    WHERE LB.TITLE IS NULL AND LB.AUTHOR IS NULL 
;
-- 60 rows

--  ------------------  Reports on Employees  --------------------
--  --------------------------------------------------------------

-- NO BIBUSERO HAS END OF CONTRACT SO CANNOT VERIFY IF IT WORKS
WITH 
    DRIVER_STATS AS (
        SELECT 
            CASE
                WHEN SUM(N_LOANS) IS NULL THEN 0
                ELSE SUM(N_LOANS) 
            END AS UNRETURNED_LOANS, 
            CASE 
                WHEN SUM(N_UNRETURNED_LOANS) IS NULL THEN 0 
                ELSE SUM(N_UNRETURNED_LOANS) 
            END AS TOTAL_LOANS,
            COUNT(*) AS TOTAL_STOPS,
            SERVICES.PASSPORT
        FROM SERVICES 
        LEFT JOIN (
            SELECT 
                COUNT(RETURN) AS N_LOANS, 
                COUNT(CASE WHEN RETURN < TRUNC(SYSDATE) THEN 1 END) AS N_UNRETURNED_LOANS,
                TOWN, PROVINCE, STOPDATE 
            FROM LOANS
            GROUP BY TOWN, PROVINCE, STOPDATE
            -- ORDER BY COUNT(*) DESC
        ) LOANS_BY_SERVICE
        ON SERVICES.TOWN = LOANS_BY_SERVICE.TOWN
            AND SERVICES.PROVINCE = LOANS_BY_SERVICE.PROVINCE
            AND SERVICES.TASKDATE = LOANS_BY_SERVICE.STOPDATE
        GROUP BY SERVICES.PASSPORT
        -- ORDER BY TOTAL_LOANS DESC
    ),
    DRIVER_DATA AS (
        SELECT
            D.PASSPORT,
            D.FULLNAME,
            FLOOR(
                MONTHS_BETWEEN(TRUNC(sysdate), D.BIRTHDATE)/12
            ) AS AGE, 
            CASE
                WHEN D.CONT_END IS NULL THEN -1
                ELSE FLOOR((D.CONT_END - D.CONT_START)/365.25)
            END AS CONTRACTED_YEARS,
            FLOOR((SYSDATE - D.CONT_START)/365.25) AS ACTIVE_YEARS
        FROM DRIVERS D
    )
SELECT
    D.FULLNAME, 
    D.AGE, 
    D.CONTRACTED_YEARS,
    D.ACTIVE_YEARS,
    CASE 
        WHEN D.ACTIVE_YEARS = 0 THEN S.TOTAL_STOPS
        ELSE S.TOTAL_STOPS/D.ACTIVE_YEARS
    END AS STOPS_PER_ACTIVE_YEAR,
    CASE 
        WHEN D.ACTIVE_YEARS = 0 THEN S.TOTAL_LOANS
        ELSE S.TOTAL_LOANS/D.ACTIVE_YEARS
    END AS LOANS_PER_ACTIVE_YEAR,
    CASE
        WHEN S.TOTAL_LOANS = 0 THEN 0
        ELSE S.UNRETURNED_LOANS/S.TOTAL_LOANS
    END AS RATE
FROM DRIVER_DATA D
JOIN DRIVER_STATS S
ON D.PASSPORT = S.PASSPORT
ORDER BY FULLNAME DESC
;

