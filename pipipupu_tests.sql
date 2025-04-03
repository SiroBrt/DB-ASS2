SET LINESIZE 1000;
SET WRAP OFF;

-- 1.1.2
-- Frutos campo dorado driver in 2020
insert into assign_drv values('ESP>>101010101111', '1-NOV-20', 'AN-02');
insert into assign_bus values('BUS-029', '1-NOV-20', 'AN-02');
insert into services values('Villaverde', 'Madrid', 'BUS-029', '1-NOV-20', 'ESP>>101010101111');


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



-- 1.3.1 TESTS
  -- CANNOT INSERT THIS: READ ONLY
  INSERT INTO my_data VALUES('1', '1111', NULL, SYSDATE, '', '', '', NULL, 1111111111111, 'P', NULL);

-- 1.4.A TESTS
  -- INSERT LIBRARY POST
  INSERT INTO posts VALUES('AA957', '9994309856', TO_DATE('19-11-2024','DD-MM-YYYY'), SYSDATE, 'text', 0, 0);
  -- INSERT USER POST
  INSERT INTO POSTS VALUES('JG545', '9266310304', TO_DATE('22-11-2024','DD-MM-YYYY'), SYSDATE, 'text', 1, 1);

-- 1.4.B TESTS
  UPDATE copies SET condition='D' WHERE copies.signature='AA070';
  SELECT DEREGISTERED FROM COPIES WHERE copies.signature='AA070';
  UPDATE copies SET condition='N' WHERE copies.signature='AA070';

-- 1.4.D TESTS
-- SELECT title, author, reads FROM books
--     WHERE reads > 5;
