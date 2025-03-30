SET LINESIZE 1000;
SET WRAP OFF;

-- 1.2.1 tests
begin
  foundicu.set_current_user(1546522482);
  foundicu.insert_loan('NE000');
end;

INSERT INTO loans VALUES('NE000', 1546522482, SYSDATE+200, 'Madrid', 'Madrid', 'R', 30, NULL);

-- 1.2.3 TESTS
SELECT SIGNATURE, USER_ID, STOPDATE, RETURN FROM LOANS 
    WHERE ROWNUM < 10 AND RETURN IS NULL;

SELECT COUNT(*), l.return FROM loans l
        WHERE l.signature = '' 
            AND l.user_id = 1546522482 
        GROUP BY l.return;

-- SIGNA USER_ID    STOPDATE  RETURN                                                                                                                                                                 
-- IJ548 1546522482 16-NOV-24 30-NOV-24
-- LB296 1546522482 16-NOV-24 30-NOV-24  
begin
  foundicu.set_current_user(1546522482);
  foundicu.record_books_returning('IJ548');
end;
