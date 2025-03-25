-- FOUNDICU PACKAGE -------------------------------------------------------------------
-- ------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY foundicu IS 
    -- TYPE my_type IS RECORD (...);
    current_user CHAR(10);
    PROCEDURE insert_loan(signature IN loans.signature%TYPE);
    PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in date);
    PROCEDURE record_books_returning(signature IN loans.signature%TYPE);

    PROCEDURE set_current_user(new_user IN CHAR(10));
    FUNCTION get_current_user RETURN CHAR;
END foundicu;




CREATE OR REPLACE PACKAGE BODY foundicu IS

    PROCEDURE insert_loan(signature IN loans.signature%TYPE) IS
        user users%ROWTYPE;
    BEGIN
        -- SELECT * INTO user FROM users u
        --     WHERE u.user_id = current_user;
        
        -- SELECT signature, user_id, stopdate, type FROM loans l
        -- WHERE l.signature = signature AND l.user_id = current_user;
        -- INSERT INTO LOANS VALUES (signature, user_id, SYSDATE, town, province, type, time, return);
        -- COMMIT;
    -- EXCEPTION
    END insert_loan;

    PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in DATE) IS
    BEGIN
        SELECT * INTO user FROM users u
            WHERE u.user_id = current_user;

        -- COMMIT;
    END insert_reservation;

    PROCEDURE record_books_returning(signature IN loans.signature%TYPE) IS
        signature loans.signature%TYPE;
    BEGIN
        SELECT signature, user_id, stopdate FROM loans l
            WHERE l.signature = signature AND l.user_id = current_user AND l.type = 'L';
        UPDATE loans SET return = SYSDATE 
            WHERE signature = signature AND user_id = current_user;
        -- COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('No data found');
        WHEN OTHERS THEN
            dbms_output.put_line('An error has occurred');
    END record_books_returning;

END package_name;
-- BEGIN	
--     dbms_output.put_line('Control is now executing the package initialization part');
-- END foundicu;

-- Printing 
-- SET SERVEROUTPUT ON;
-- dbms_output.put_line('pipipupu_package.sql');
