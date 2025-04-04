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
  -- this user has 6 loans, so comfortable to test everything
  SELECT SIGNATURE, USER_ID, TYPE FROM LOANS WHERE USER_ID = 9994309731;

  -- modify one to make it R
  UPDATE LOANS 
      SET TYPE = 'R' 
      WHERE SIGNATURE = 'YC183' 
      AND USER_ID = 9994309731;

  -- set current user
  EXEC foundicu.set_current_user(9994309731);

  -- should modify R to L
  EXEC foundicu.insert_loan('YC183');
  /*
  Current user exists
  Loan updated from reservation to loan

  PL/SQL procedure successfully completed.
  */
  -- should again have all L
  SELECT SIGNATURE, USER_ID, TYPE FROM LOANS WHERE USER_ID = 9994309731;


  -- set bandate of today + 2 days to check how procedure handles banned users
  UPDATE USERS 
      SET BAN_UP = SYSDATE + 2 
      WHERE USER_ID = 9994309731;

  -- works fine, as user has one reservation
  EXEC foundicu.insert_loan('YC183');
  -- however if to call after, having that there is no reservation,
  -- the execution will be aborted


  -- modify return dates of some loans to test checking for having more than 2 reservations
  UPDATE LOANS 
      SET RETURN = SYSDATE + 3 
      WHERE USER_ID = 9994309731 
      AND SIGNATURE = 'MG759';

  UPDATE LOANS 
      SET RETURN = SYSDATE + 3 
      WHERE USER_ID = 9994309731 
      AND SIGNATURE = 'DG889';

  EXEC foundicu.insert_loan('YC183');
  /*
  Current user exists
  No reservation found for this user
  Error. Current user has reached the upper limit for loans
  */

  -- modify return dates so the user have not reache upper limit
  UPDATE LOANS 
      SET RETURN = SYSDATE - 3 
      WHERE USER_ID = 9994309731 
      AND SIGNATURE = 'DG889';

  -- to create service that will be in future
  -- first create driver assignment
  INSERT INTO ASSIGN_DRV (PASSPORT, TASKDATE)
      VALUES ('ESP>>101010101111',  TO_DATE('06-APR-25', 'DD-MON-YY'));

  -- creat bus assignment
  INSERT INTO ASSIGN_BUS (PLATE, TASKDATE, ROUTE_ID)
      VALUES ('BUS-017', TO_DATE('06-APR-25', 'DD-MON-YY'), 'MU-02');

  -- now create service

  INSERT INTO SERVICES (TOWN, PROVINCE, BUS, TASKDATE, PASSPORT)
      VALUES ('Paramo de los Sequillos', 'Cuenca', 'BUS-017', 
      TO_DATE('06-APR-25', 'DD-MON-YY'), 'ESP>>101010101111');
      

  -- call procedure to insert loan
  EXEC foundicu.insert_loan('YC183');


-- 1.2.2 TESTS
  -- set current user
  EXEC foundicu.set_current_user(9994309731);

  -- to create service that will be in future
  -- first create driver assignment
  INSERT INTO ASSIGN_DRV (PASSPORT, TASKDATE)
      VALUES ('ESP>>101010101111',  TO_DATE('06-APR-25', 'DD-MON-YY'));

  -- creat bus assignment
  INSERT INTO ASSIGN_BUS (PLATE, TASKDATE, ROUTE_ID)
      VALUES ('BUS-017', TO_DATE('06-APR-25', 'DD-MON-YY'), 'MU-02');

  -- now create service

  INSERT INTO SERVICES (TOWN, PROVINCE, BUS, TASKDATE, PASSPORT)
      VALUES ('Paramo de los Sequillos', 'Cuenca', 'BUS-017', 
      TO_DATE('06-APR-25', 'DD-MON-YY'), 'ESP>>101010101111');
      
  -- execute procedure. It will create new reservation as date matches the bus drive
  EXEC foundicu.insert_reservation('84-218-2589-5', TO_DATE('06-APR-25', 'DD-MON-YY'));

  -- will produce error as there is no ride at that day
  EXEC foundicu.insert_reservation('84-218-2589-5', TO_DATE('07-APR-25', 'DD-MON-YY'));


-- 1.2.3 TESTS
  -- SIGNA USER_ID    STOPDATE  RETURN                                                                                                                                                                 
  -- IJ548 1546522482 16-NOV-24 30-NOV-24
  -- LB296 1546522482 16-NOV-24 30-NOV-24  
  begin
    foundicu.set_current_user(1546522482);
    UPDATE loans SET RETURN=NULL WHERE USER_ID='1546522482' AND signature='IJ548';
    foundicu.record_books_returning('IJ548');
    foundicu.record_books_returning('IJ548'); -- ERROR
  end;
  /

  begin
    foundicu.set_current_user(69);
    foundicu.record_books_returning('IJ548'); -- ERROR
  end;
  /


-- 1.3.1 TESTS
  EXEC foundicu.set_current_user(9994309824);
  SELECT * FROM my_data;
  -- CANNOT INSERT THIS: READ ONLY
  INSERT INTO my_data VALUES('1', '1111', NULL, SYSDATE, '', '', '', NULL, 1111111111111, 'P', NULL);

-- 1.3.2 TESTS
  EXEC foundicu.set_current_user(5005122262);
  UPDATE my_loans
      SET TEXT = 'THIS IS TEST'
      WHERE SIGNATURE='UC856'; 
  SELECT * FROM my_loans;
  SELECT * FROM POSTS WHERE USER_ID = 5005122262;

  -- to test case of insertion
  EXEC foundicu.set_current_user(8612169569);
  UPDATE my_loans
      SET TEXT = 'HIHIHI'
      WHERE SIGNATURE = 'JL729';
  SELECT SIGNATURE, TEXT FROM POSTS WHERE USER_ID = 8612169569;

-- 1.3.3 TESTS
  EXEC FOUNDICU.SET_CURRENT_USER(1546522482);
  INSERT INTO my_reservations VALUES('NE000', '16-NOV-24', 'Sotolemures', 'Barcelona', 'R', 750, NULL);
  SELECT * FROM my_reservations;
  SELECT * FROM loans WHERE user_id=foundicu.get_current_user() AND type='R';
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