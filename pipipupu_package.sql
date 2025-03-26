-- FOUNDICU PACKAGE -------------------------------------------------------------------
-- ------------------------------------------------------------------------------------

-- PACKAGE HEADER
CREATE OR REPLACE PACKAGE foundicu AS 
    -- TYPE my_type IS RECORD (...);
    current_user CHAR(10);
    PROCEDURE insert_loan(signature IN loans.signature%TYPE);
    -- PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in date);
    -- PROCEDURE record_books_returning(signature IN loans.signature%TYPE);

    -- PROCEDURE set_current_user(new_user IN current_user%TYPE);
    -- FUNCTION get_current_user RETURN CHAR;
END foundicu;

-- PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY foundicu AS
    PROCEDURE insert_loan(signature IN loans.signature%TYPE) IS
        user_count NUMBER;
        reservated NUMBER;
        ban_date users.BAN_UP2%TYPE;

        user_does_not_exist EXCEPTION;
        user_is_banned EXCEPTION;
        copy_not_available EXCEPTION;
    BEGIN
        SELECT COUNT(*), BAN_UP2 INTO user_count, ban_date FROM users WHERE users.user_id = current_user;
        
        IF user_count = 0 
            THEN RAISE user_does_not_exist;
        END IF;
        
        SELECT COUNT(*) INTO reservated FROM loans l
            WHERE l.signature = signature 
                AND l.user_id = current_user
                AND l.type = 'R';

        IF reservated <> 0
            THEN UPDATE LOANS l SET TYPE='L' WHERE l.user_id=current_user AND l.signature=signature;
        ELSIF SYSDATE < ban_date
            THEN RAISE user_is_banned;
        ELSE
            -- to insert new loan, we need to insert a new route and assign drv
            -- INSERT INTO LOANS VALUES(signature, user_id, SYSDATE, town, province, type, time, return);
        END IF;
        
        -- SELECT signature, user_id, stopdate, type FROM loans l
        -- WHERE l.signature = signature AND l.user_id = current_user;
        
        COMMIT;
    EXCEPTION
        WHEN user_does_not_exist 
            THEN dbms_output.put_line('Current user does not exist'); 
        WHEN user_is_banned 
            THEN dbms_output.put_line('Current user is banned'); 
    END insert_loan;
END foundicu;

    -- PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in DATE) IS
    -- BEGIN
    --     SELECT * INTO user FROM users u
    --         WHERE u.user_id = current_user;

    --     -- COMMIT;
    -- END insert_reservation;

    -- PROCEDURE record_books_returning(signature IN loans.signature%TYPE) IS
    --     signature loans.signature%TYPE;
    -- BEGIN
    --     SELECT signature, user_id, stopdate FROM loans l
    --         WHERE l.signature = signature AND l.user_id = current_user AND l.type = 'L';
    --     UPDATE loans SET return = SYSDATE 
    --         WHERE signature = signature AND user_id = current_user;
    --     -- COMMIT;
    -- EXCEPTION
    --     WHEN NO_DATA_FOUND THEN
    --         dbms_output.put_line('No data found');
    --     WHEN OTHERS THEN
    --         dbms_output.put_line('An error has occurred');
    -- END record_books_returning;

    
    -- PROCEDURE set_current_user(new_user IN CHAR(10)) IS
    -- BEGIN
    --     current_user = new_user;
    -- END set_current_user;

    -- FUNCTION get_current_user RETURN CHAR;

-- END foundicu;
-- BEGIN	
--     dbms_output.put_line('Control is now executing the package initialization part');
-- END foundicu;

-- Printing 
-- SET SERVEROUTPUT ON;
-- dbms_output.put_line('pipipupu_package.sql');
