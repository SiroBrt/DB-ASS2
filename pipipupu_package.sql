-- FOUNDICU PACKAGE -------------------------------------------------------------------
-- ------------------------------------------------------------------------------------

-- PACKAGE HEADER
CREATE OR REPLACE PACKAGE foundicu AS 
    -- TYPE my_type IS RECORD (...);
    current_user CHAR(10);
    PROCEDURE insert_loan(signature IN loans.signature%TYPE);
    PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in date);
    PROCEDURE record_books_returning(signature IN loans.signature%TYPE);

    -- PROCEDURE set_current_user(new_user IN current_user%TYPE);
    -- FUNCTION get_current_user RETURN CHAR;
END foundicu;

-- PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY foundicu AS

    -- THIS SHIT IS NOT FINISHED AND I HATE THIS PUTA MIERDA
    PROCEDURE insert_loan(signature IN loans.signature%TYPE) IS
        user_count NUMBER;
        reservated NUMBER;
        ban_date users.BAN_UP2%TYPE;

        user_does_not_exist EXCEPTION;
        user_is_banned EXCEPTION;
        copy_not_available EXCEPTION;
    BEGIN
        -- CHECK IF USER EXISTS (THROUGH USER_COUNT VALUE) AND IF THE USER IS BANNED
        SELECT COUNT(*), BAN_UP2 INTO user_count, ban_date FROM users WHERE users.user_id = current_user;
        
        IF user_count = 0 
            THEN RAISE user_does_not_exist;
        END IF;
        
        -- CHECK IS THERE IS AN EXISTING RESERVATION FOR THE BOOK
        SELECT COUNT(*) INTO reservated FROM loans l
            WHERE l.signature = signature 
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
        WHEN user_does_not_exist 
            THEN dbms_output.put_line('Current user does not exist'); 
        WHEN user_is_banned 
            THEN dbms_output.put_line('Current user is banned'); 
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

    -- IT SHOULD BE OK UNLESS WE THINK OF OTHER IMPEDIMENTS
    PROCEDURE record_books_returning(signature IN loans.signature%TYPE) IS
        existing_loan NUMBER;
        return_value loans.return%TYPE;
        no_loan EXCEPTION;
        book_already_returned EXCEPTION;
    BEGIN
        -- CHECK IF THE BOOK IS BEING LOANED BY CURRENT USER
        SELECT COUNT(*), return INTO existing_loan, return_value FROM loans l
            WHERE l.signature = signature 
                AND l.user_id = current_user 
                AND l.type = 'L';
        IF existing_loan = 0
            THEN RAISE no_loan;
        ELSIF return_value IS NOT NULL
            THEN RAISE book_already_returned;
        END IF;
        -- UPDATE RETURN OF LOAN
        UPDATE loans SET return = SYSDATE 
            WHERE signature = signature AND user_id = current_user;
        COMMIT;
    EXCEPTION
        WHEN no_loan THEN
            dbms_output.put_line('Error. Current user has not borrowed this copy of the book.');
        WHEN book_already_returned THEN
            dbms_output.put_line('Aborted. The book has already been returned.');
    END record_books_returning;

    
    -- PROCEDURE set_current_user(new_user IN CHAR(10)) IS
    -- BEGIN
    --     current_user = new_user;
    -- END set_current_user;

    -- FUNCTION get_current_user RETURN CHAR;
END foundicu;
-- BEGIN	
--     dbms_output.put_line('Control is now executing the package initialization part');
-- END foundicu;

-- Printing 
-- SET SERVEROUTPUT ON;
-- dbms_output.put_line('pipipupu_package.sql');
