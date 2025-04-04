-- delete previous versions
DROP PACKAGE BODY foundicu;
DROP PACKAGE foundicu;

-- to have everything printed
SET SERVEROUTPUT ON;

-- upload new ones of header and body files using @
-- (it is better to split header and body into different files)

-- check errors
SHOW ERRORS PACKAGE foundicu;
SHOW ERRORS PACKAGE BODY foundicu;
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
