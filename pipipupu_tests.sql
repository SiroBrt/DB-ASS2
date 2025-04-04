SET LINESIZE 1000;
SET WRAP OFF;

-- 1.2.1 tests

insert into drivers values ('123', '123@123.com', 'Sujeto de Prueba', '29-FEB-00', 123456789,'Casa 1 a la derecha', '01-MAR-00', '01-MAR-24');
insert into assign_drv values('123', '01-MAR-00', 'MA-03');
insert into assign_bus values('BUS-017', '01-MAR-00', 'MA-03');
insert into services values('Villaverde', 'Madrid', 'BUS-017', '01-MAR-00', '123');
insert into loans values('YD250', 1546522482, '01-MAR-00', 'Villaverde', 'Madrid', 'L', 100);
insert into loans values('NG473', 1546522482, '01-MAR-00', 'Villaverde', 'Madrid', 'L', 100 '01-MAR-01');


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
INSERT INTO my_data VALUES('1', '1111', NULL, SYSDATE, '', '', '', NULL, 1111111111111, 'P', NULL);


-- 1.4.D TESTS
-- SELECT title, author, reads FROM books
--     WHERE reads > 5;
