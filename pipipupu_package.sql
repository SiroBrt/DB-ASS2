-- FOUNDICU PACKAGE -------------------------------------------------------------------
-- ------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY foundicu IS 

    PROCEDURE insert_loan(signature IN VARCHAR2)
        IS PRAGMA AUTONOMOUS_TRANSACTION;
        -- BEGIN

        -- COMMIT;
    END insert_loan;

    PROCEDURE insert_reservation(isbn IN varchar2, reservation_date in date)
        IS PRAGMA AUTONOMOUS_TRANSACTION;
        -- BEGIN

        -- COMMIT;
    END insert_reservation;

    PROCEDURE record_books_returning(signature IN VARCHAR2)
        IS PRAGMA AUTONOMOUS_TRANSACTION;
        -- BEGIN

        -- COMMIT;
    END record_books_returning;

BEGIN	
    dbms_output.put_line('Control is now executing the package initialization part');
END foundicu;

-- Printing 
-- SET SERVEROUTPUT ON;
-- dbms_output.put_line('pipipupu_package.sql');
