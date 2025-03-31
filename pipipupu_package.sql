-- FOUNDICU PACKAGE -------------------------------------------------------------------
-- ------------------------------------------------------------------------------------

-- PACKAGE HEADER
CREATE OR REPLACE PACKAGE foundicu AS 
    -- TYPE my_type IS RECORD (...);
    current_user CHAR(10);
    PROCEDURE insert_loan(copy_signature IN loans.signature%TYPE);
    PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in date);
    PROCEDURE record_books_returning(copy_signature IN loans.signature%TYPE);
    
    -- FUNCTION insert_service(town IN services.town%TYPE, province IN services.province%TYPE, taskdate IN services.taskdate%TYPE) RETURN NUMBER;

    PROCEDURE set_current_user(new_user IN current_user%TYPE);
    FUNCTION get_current_user RETURN current_user%TYPE;
END foundicu;

-- PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY foundicu AS

    -- THIS SHIT IS NOT FINISHED AND I HATE THIS PUTA MIERDA
    PROCEDURE insert_loan(copy_signature IN loans.signature%TYPE) IS
        --reservated NUMBER;
        ban_date users.BAN_UP2%TYPE;
        count_users NUMBER;
        count_reservations NUMBER;

        user_is_banned EXCEPTION;
        copy_not_available EXCEPTION;
    BEGIN
        /*
        -- CHECK IF USER EXISTS (THROUGH USER_COUNT VALUE) AND IF THE USER IS BANNED
        BEGIN
            SELECT BAN_UP2 INTO ban_date,  FROM users 
                WHERE users.user_id = current_user
                GROUP BY BAN_UP2;
        EXCEPTION
            WHEN NO_DATA_FOUND
                THEN dbms_output.put_line('Error. Current user does not exist'); 
        END;
        */
        -- go through users and check by primary key if there is such user as current
        SELECT BAN_UP2, COUNT (*) INTO ban_date, count_users FROM USERS
            WHERE USER_ID = current_user;
        IF count_users = 0 THEN
            -- if nUot, raise error
            dbms_output.put_line('Error. Current user does not exist');
            RETURN;
        ELSE
            dbms_output.put_line('Current user exists');
        END IF;

        -- check reservations and if there is a reservation for the current user
        -- if there is a reservation, update the loan type to 'L'
        SELECT COUNT(*) INTO count_reservations FROM LOANS
            WHERE USER_ID = current_user
            AND SIGNATURE = copy_signature
            AND TYPE = 'R';

        IF count_reservations <> 0
            -- if there is a reservation, update the loan type to 'L'
            --THEN UPDATE LOANS l SET TYPE='L' WHERE l.user_id=current_user AND l.signature=signature;
            THEN UPDATE LOANS SET TYPE = 'L' 
                WHERE USER_ID = current_user
                AND SIGNATURE = copy_signature;
            dbms_output.put_line('Loan updated from reservation to loan');
        
        -- if the user has not reached the upper limit for loans, check if the user is not sanctioned
        ELSIF SYSDATE < ban_date
            THEN RAISE user_is_banned;
        ELSE
            -- to insert new loan, we need to insert a new route and assign drv
            -- INSERT INTO LOANS VALUES(signature, user_id, SYSDATE, town, province, type, time, return);
            dbms_output.put_line('No reservation found for this user');
            -- if there is no reservation, check reservations with this book comparing time and stop dates to check if the copy is available for two weeks
            SELECT COUNT(*) INTO count_reservations FROM LOANS 
                WHERE SIGNATURE = copy_signature
                AND RETURN > SYSDATE + 14;

            IF count_reservations = 0 THEN
            -- if the copy is available, check if the user has not reached the upper limit for loans by counting his loans
                SELECT COUNT(*) INTO count_reservations FROM LOANS 
                    WHERE USER_ID = current_user
                    AND TYPE = 'L'
                    AND RETURN > SYSDATE; -- meaning the book loaned and not returned yet
                IF count_reservations < 3 THEN
                    -- if the user is not sanctioned(and it is not as at the very beginning the error would be raised), insert a new loan row
                    INSERT INTO LOANS (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
                        VALUES (copy_signature, current_user, SYSDATE, 
                        (SELECT TOWN FROM USERS WHERE USER_ID = current_user), 
                        (SELECT PROVINCE FROM USERS WHERE USER_ID = current_user), 
                        'L', DEFAULT, SYSDATE + 14); -- to have return date two weeks from now
                    dbms_output.put_line('New loan inserted');
                ELSE
                    -- if the user has reached the upper limit for loans, raise error
                    dbms_output.put_line('Error. Current user has reached the upper limit for loans');
                    RETURN;
                END IF;
            -- if the copy is not available, raise error
            ELSE
                dbms_output.put_line('Error. Copy is not available for two weeks');
                RETURN;
            END IF;
        END IF;
        
        COMMIT;
    EXCEPTION
        WHEN user_is_banned 
            THEN dbms_output.put_line('Abort. Current user is banned'); 
    END insert_loan;

    -- beautifu
    -- Insert Reservation Procedure: 
    PROCEDURE insert_reservation(isbn IN editions.isbn%TYPE, reservation_date in DATE) IS
        -- receives an ISBN and a date; 
        copy_signature copies.signature%TYPE;
        user_data users%ROWTYPE;

        stop_time stops.time%TYPE;
        loan_count NUMBER;
        date_of_service services.taskdate%TYPE;
    /*
        existing_service NUMBER;
        user_is_banned EXCEPTION;
        no_available_copies EXCEPTION;
        loan_limit_exceeded EXCEPTION;
        fuck_you EXCEPTION;
    BEGIN
        BEGIN
            SELECT * INTO user_data FROM users WHERE users.user_id = current_user;
        EXCEPTION
            WHEN NO_DATA_FOUND
                THEN dbms_output.put_line('Error. Current user does not exist.');
            WHEN TOO_MANY_ROWS
                THEN dbms_output.put_line('Error. Multiple current users found with the same primary key.');
        END;
        
        IF SYSDATE < user_data.ban_up2
            THEN RAISE user_is_banned;
        END IF;

        SELECT COUNT(*) INTO loan_count FROM loans l
            WHERE l.user_id = current_user
                AND l.return IS NULL
                AND l.type = 'L';

        -- some copy that is available 14 days after reservation_date
            -- excludes copy with reservation within 14 days after reservation_date 
            -- excludes copy with a reservation/loan within 14 days before reservation_data
        SELECT min(signature) INTO copy_signature FROM copies c
            WHERE c.isbn = isbn
            AND c.signature NOT IN (
                SELECT signature 
                    FROM loans l 
                    JOIN copies c ON c.isbn = isbn
                    WHERE l.stopdate-14 <= reservation_date
                        AND l.return+14 >= reservation_date
            );

        -- IF ELSE .......      
        IF loan_count > 1
            THEN RAISE loan_limit_exceeded;
        ELSIF copy_signature IS NULL
            THEN RAISE no_available_copies;
        END IF;

        SELECT COUNT(*), time INTO existing_service, stop_time FROM SERVICES
            JOIN stops ON SERVICES.town = stops.town AND SERVICES.province = stops.province
            WHERE town = user_data.town
                AND province = user_data.province
                AND taskdate = reservation_date; 
        
        IF existing_service = 0 
            THEN RAISE FUCK_YOU;
            -- 💀
            -- insert a stop route that goes to the user municipality (if it doesnt exist)
                -- if it does not exist, then also create route 
            -- create assign_drv and services
            -- INSERT INTO assign_bus VALUES('plate', reservation_date, 'route');
            -- INSERT INTO assign_drv VALUES('passport', reservation_date, 'route');
            -- INSERT INTO services VALUES(user_data.town, user_data.province, 'bus', reservation_date, 'driver_passport');
            -- assign a loan to the service
        ELSE
            INSERT INTO LOANS VALUES(copy_signature, current_user, reservation_date, user_data.town, user_data.province, stop_time, 'R', NULL);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN fuck_you
            THEN dbms_output.put_line('FUCK YOU. Dont insert a reservation when we dont have a bus to deliver it to you.');
        WHEN user_is_banned
            THEN dbms_output.put_line('Abort. User is currently banned.');
        WHEN loan_limit_exceeded
            THEN dbms_output.put_line('Abort. User loan limit exceeded.');
        WHEN no_available_copies
            THEN dbms_output.put_line('Abort. No available copies for loaning.');
    END insert_reservation;
    */
    BEGIN
        BEGIN
        -- checks that the current USER exists 
            SELECT * INTO user_data FROM users WHERE users.user_id = current_user;
        EXCEPTION
            WHEN NO_DATA_FOUND
                THEN dbms_output.put_line('Error. Current user does not exist.');
            WHEN TOO_MANY_ROWS
                THEN dbms_output.put_line('Error. Multiple current users found with the same primary key.');
        END;
        -- and has quota for reserving (has not reached the upper borrowing limit
        SELECT COUNT(*) INTO loan_count FROM LOANS l
            WHERE l.user_id = current_user
                AND l.return > SYSDATE
                AND l.type = 'L';
        IF loan_count > 2
            THEN dbms_output.put_line('Error. Current user has reached the upper limit for loans');
            RETURN;
        END IF;

        -- and they are not sanctioned); 
        IF SYSDATE < user_data.ban_up2
            THEN dbms_output.put_line('Error. Current user is banned.');
            RETURN;
        END IF;

        -- checks the availability of a copy of that edition for two weeks (14 days) from the date provided, 
        SELECT min(SIGNATURE) INTO copy_signature FROM COPIES c
            WHERE c.isbn = isbn -- find all copies of the book
            AND c.signature NOT IN ( -- exclude the copies that are not available; could be done by LEFT JOIN
                SELECT SIGNATURE 
                    FROM LOANS l 
                    JOIN COPIES c ON c.isbn = isbn
                    WHERE l.stopdate-14 <= reservation_date
                        AND l.return+14 >= reservation_date
            );
        IF copy_signature IS NULL
            THEN dbms_output.put_line('Error. No available copies for loaning.');
            RETURN;
        END IF;
        -- and then places the hold (else, reports the hinder). 
        
        SELECT min(TASKDATE), COUNT(*) INTO date_of_service, count_reservations FROM SERVICES
            JOIN STOPS ON SERVICES.town = stops.town AND SERVICES.province = stops.province
            WHERE TOWN = user_data.town
                AND PROVINCE = user_data.province
                AND TASKDATE > reservation_date; 
        IF count_reservations = 0 
            THEN dbms_output.put_line('Error. No service available for the following dates.');
            RETURN;
        END IF;
        INSERT INTO LOANS (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
            VALUES (copy_signature, current_user, date_of_service, user_data.town, user_data.province, 'R', DEFAULT, date_of_service + 14); -- to have return date two weeks from reservation
        

    END insert_reservation;

    
    -- IT SHOULD BE OK
    PROCEDURE record_books_returning(copy_signature IN loans.signature%TYPE) IS
        loan_count NUMBER;
        no_loan_found EXCEPTION;
        multiple_loans_found EXCEPTION;
    BEGIN   
        -- CHECK IF THE BOOK IS BEING LOANED BY CURRENT USER
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
