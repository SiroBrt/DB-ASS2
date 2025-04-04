-- delete previous versions
DROP PACKAGE BODY foundicu;
DROP PACKAGE foundicu;

-- to have everything printed
SET SERVEROUTPUT ON;

-- upload new ones of header and body files

-- check errors
SHOW ERRORS PACKAGE foundicu;
SHOW ERRORS PACKAGE BODY foundicu;
-- this user has 6 loans, so comfortable to test everything

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