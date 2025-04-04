SET LINESIZE 1000;
SET WRAP OFF;

-- 1.1.1
-- 1.1.2
  -- Custom driver with things
  insert into drivers values('123', '123@hotmail.com', 'Sujeto de la Prueba Estandar', '29-FEB-00', 123456789, 'Casa 1 a la derecha', '01-MAR-00','02-MAR-24');
  insert into assign_drv values('123', '1-NOV-20', 'AN-02');
  insert into assign_bus values('BUS-029', '1-NOV-20', 'AN-02');
  insert into services values('Villaverde', 'Madrid', 'BUS-029', '1-NOV-20', '123');
  insert into loans values('CH068', 1546522482, '1-NOV-20', 'Villaverde', 'Madrid', 'L', 100, NULL);
  insert into loans values('YB164', 1546522482, '1-NOV-20', 'Villaverde', 'Madrid', 'L', 100, SYSDATE+365);



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

-- 1.2.2 TESTS

-- 1.2.3 TESTS
  -- SIGNA USER_ID    STOPDATE  RETURN                                                                                                                                                                 
  -- IJ548 1546522482 16-NOV-24 30-NOV-24
  -- LB296 1546522482 16-NOV-24 30-NOV-24  
  begin
    foundicu.set_current_user(1546522482);
    foundicu.record_books_returning('IJ548');
    foundicu.record_books_returning('ZZZZZ'); -- ERROR
    foundicu.set_current_user(69);
    foundicu.record_books_returning('ZZZZZ'); -- ERROR
  end;



-- 1.3.1 TESTS
  EXEC foundicu.set_current_user(9994309824);
  SELECT * FROM my_data;
  -- CANNOT INSERT THIS: READ ONLY
  INSERT INTO my_data VALUES('1', '1111', NULL, SYSDATE, '', '', '', NULL, 1111111111111, 'P', NULL);

-- 1.3.3 TESTS
  BEGIN
    FOUNDICU.SET_CURRENT_USER(1546522482);
  END;
  /
  INSERT INTO my_reservations VALUES('NE000', '16-NOV-24', 'Sotolemures', 'Barcelona', 'R', 750, NULL);
  SELECT * FROM my_reservations;
  UPDATE my_reservations SET signature='IJ548' WHERE signature='NE000';     
  UPDATE my_reservations SET TIME=2000 WHERE signature='NE000';
  DELETE FROM my_reservations WHERE SIGNATURE='NE000' AND STOPDATE='16-NOV-24';

-- 1.4.A TESTS
  -- INSERT LIBRARY POST: ERROR
  INSERT INTO posts VALUES('AA957', '9994309856', TO_DATE('19-11-2024','DD-MM-YYYY'), SYSDATE, 'text', 0, 0);
  -- INSERT USER POST: GOOD
  INSERT INTO POSTS VALUES('JG545', '9266310304', TO_DATE('22-11-2024','DD-MM-YYYY'), SYSDATE, 'text', 1, 1);

-- 1.4.B TESTS
  UPDATE copies SET condition='D' WHERE copies.signature='AA070';
  SELECT deregsitered FROM copies WHERE copies.signature='AA070';
  UPDATE copies SET condition='N' WHERE copies.signature='AA070'; -- ERROR

-- 1.4.D TESTS
  -- NO TESTS YET