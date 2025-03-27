-- FOUNDICU PACKAGE -------------------------------------------------------------------
-- ------------------------------------------------------------------------------------

-- PACKAGE HEADER
CREATE OR REPLACE PACKAGE foundicu AS 
    -- TYPE my_type IS RECORD (...);
    current_user CHAR(10);
    PROCEDURE insert_loan(copy_signature IN loans.signature%TYPE);
    PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in date);
    PROCEDURE record_books_returning(copy_signature IN loans.signature%TYPE);

    PROCEDURE set_current_user(new_user IN current_user%TYPE);
    FUNCTION get_current_user RETURN current_user%TYPE;
END foundicu;

-- PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY foundicu AS

    -- THIS SHIT IS NOT FINISHED AND I HATE THIS PUTA MIERDA
    PROCEDURE insert_loan(copy_signature IN loans.signature%TYPE) IS
        reservated NUMBER;
        ban_date users.BAN_UP2%TYPE;

        user_is_banned EXCEPTION;
        copy_not_available EXCEPTION;
    BEGIN
        -- CHECK IF USER EXISTS (THROUGH USER_COUNT VALUE) AND IF THE USER IS BANNED
        BEGIN
            SELECT BAN_UP2 INTO ban_date FROM users 
                WHERE users.user_id = current_user
                GROUP BY BAN_UP2;
        EXCEPTION
            WHEN NO_DATA_FOUND
                THEN dbms_output.put_line('Error. Current user does not exist'); 
        END;
        
        -- CHECK IS THERE IS AN EXISTING RESERVATION FOR THE BOOK
        SELECT COUNT(*) INTO reservated FROM loans l
            WHERE l.signature = copy_signature 
                AND l.user_id = current_user
                AND l.type = 'R';

        IF reservated <> 0
            THEN UPDATE LOANS l SET TYPE='L' WHERE l.user_id=current_user AND l.signature=signature;
        ELSIF SYSDATE < ban_date
            THEN RAISE user_is_banned;
        -- ELSE
            -- to insert new loan, we need to insert a new route and assign drv
            -- INSERT INTO LOANS VALUES(signature, user_id, SYSDATE, town, province, type, time, return);
        END IF;
        
        -- SELECT signature, user_id, stopdate, type FROM loans l
        -- WHERE l.signature = signature AND l.user_id = current_user;
        COMMIT;
    EXCEPTION
        WHEN user_is_banned 
            THEN dbms_output.put_line('Abort. Current user is banned'); 
    END insert_loan;

    
    PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in DATE) IS
        loan_count NUMBER;
        user_count NUMBER;
        ban_date users.BAN_UP2%TYPE;
    BEGIN
        SELECT COUNT(*), BAN_UP2 INTO user_count, ban_date FROM users WHERE users.user_id = current_user;
        SELECT COUNT(*) INTO loan_count FROM loans l
            WHERE l.user_id = current_user
                AND l.return IS NULL
                AND l.type = 'L';

        -- IF ELSE........

        -- COMMIT;
    END insert_reservation;

    -- IT SHOULD BE OK
    PROCEDURE record_books_returning(copy_signature IN loans.signature%TYPE) IS
        loan_count NUMBER;
        no_loan_found EXCEPTION;
        multiple_loans_found EXCEPTION;
    BEGIN   
        -- CHECK IF THE BOOK IS BEING LOANED BY CURRENT USER#
        SELECT COUNT(1) INTO loan_count FROM loans l
            WHERE l.signature = copy_signature 
                AND l.user_id = current_user
                AND l.return IS NULL;
        
        IF loan_count = 0
            THEN RAISE no_loan_found;
        ELSIF loan_count > 1
            THEN RAISE multiple_loans_found;
        END IF;

        -- UPDATE RETURN OF LOAN
        UPDATE loans SET return = SYSDATE 
            WHERE signature = signature AND user_id = current_user;
        COMMIT;
    EXCEPTION
        WHEN no_loan_found THEN
            dbms_output.put_line('Error. No unreturned loan of this copy by current user has been found.');
        WHEN multiple_loans_found THEN
            dbms_output.put_line('Error. Found multiple unreturned loans of the same book by current user.');
    END record_books_returning;

    
    PROCEDURE set_current_user(new_user IN current_user%TYPE) IS
    BEGIN
        current_user := new_user;
    END set_current_user;

    FUNCTION get_current_user RETURN current_user%TYPE IS 
    BEGIN
        RETURN current_user;
    END get_current_user;
END foundicu;
-- BEGIN	
--     dbms_output.put_line('Control is now executing the package initialization part');
-- END foundicu;

-- Printing 
-- SET SERVEROUTPUT ON;
-- dbms_output.put_line('pipipupu_package.sql');
