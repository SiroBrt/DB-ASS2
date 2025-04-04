-- PACKAGE HEADER
CREATE OR REPLACE PACKAGE foundicu AS 
    -- TYPE my_type IS RECORD (...);
    current_user CHAR(10);
    PROCEDURE insert_loan(copy_signature IN loans.signature%TYPE);
    PROCEDURE insert_reservation(v_isbn IN editions.isbn%TYPE, reservation_date in date);
    PROCEDURE record_books_returning(copy_signature IN loans.signature%TYPE);
  
    PROCEDURE set_current_user(new_user IN current_user%TYPE);
    FUNCTION get_current_user RETURN current_user%TYPE;
END foundicu;
/


-- PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY foundicu AS
    -- THIS SHIT IS NOT FINISHED AND I HATE THIS PUTA MIERDA
    PROCEDURE insert_loan(copy_signature IN loans.signature%TYPE) IS
        --reservated NUMBER;
        ban_date users.BAN_UP2%TYPE;
        count_users NUMBER;
        count_reservations NUMBER;
        v_taskdate SERVICES.TASKDATE%TYPE;
        v_user_type USERS.TYPE%TYPE;
        v_town USERS.TOWN%TYPE;
        v_province USERS.PROVINCE%TYPE;
        v_population MUNICIPALITIES.POPULATION%TYPE;

        user_is_banned EXCEPTION;
        copy_not_available EXCEPTION;
    BEGIN
        -- go through users and check by primary key if there is such user as current
        SELECT MAX(BAN_UP2), COUNT (*) INTO ban_date, count_users FROM USERS
            WHERE USER_ID = current_user;
        IF count_users = 0 THEN
            -- if nUot, raise error
            dbms_output.put_line('Error. Current user does not exist');
            RETURN;
        ELSE
            dbms_output.put_line('Current user exists');
        END IF;

        IF SYSDATE < ban_date -- even if user has reservation, we do not allow to make them loans 
            THEN RAISE user_is_banned;
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

            -- get some data for simplicity
            SELECT TYPE, TOWN, PROVINCE
                INTO v_user_type, v_town, v_province
                FROM USERS
                WHERE USER_ID = current_user;

            IF count_reservations = 0 THEN
            -- if the copy is available, check if the user has not reached the upper limit for loans by counting his loans
                SELECT COUNT(*) INTO count_reservations FROM LOANS 
                    WHERE USER_ID = current_user
                    AND TYPE = 'L'
                    AND RETURN > SYSDATE; -- meaning the book loaned and not returned yet
                
                IF v_user_type = 'L' THEN
                    SELECT POPULATION
                    INTO v_population
                    FROM MUNICIPALITIES
                    WHERE TOWN = v_town AND PROVINCE = v_province;
                END IF;

                IF (v_user_type = 'P' AND count_reservations < 2)
                    OR (v_user_type = 'L' AND count_reservations < 2 * v_population) THEN
                    -- if the user is not sanctioned(and it is not as at the very beginning the error would be raised), insert a new loan row
                    SELECT MIN(TASKDATE) INTO v_taskdate FROM SERVICES
                        WHERE TASKDATE > SYSDATE
                        AND TOWN = v_town
                        AND PROVINCE = v_province;
                    
                    INSERT INTO LOANS (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, "TIME", RETURN)  -- in quotes as TIME is a reserved word
                        VALUES (copy_signature, current_user, v_taskdate, 
                        v_town, v_province, 'R', DEFAULT, v_taskdate + 14); -- to have return date two weeks from now
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

    PROCEDURE insert_reservation(v_isbn IN editions.isbn%TYPE, reservation_date in DATE) IS
        -- receives an ISBN and a date; 
        copy_signature copies.signature%TYPE;
        user_data users%ROWTYPE;

        loan_count NUMBER;
        date_of_service services.taskdate%TYPE;
        count_reservations NUMBER;
        v_population MUNICIPALITIES.POPULATION%TYPE;
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
        
        IF user_data.type = 'L' THEN
            SELECT POPULATION
            INTO v_population
            FROM MUNICIPALITIES
            WHERE TOWN = user_data.town AND PROVINCE = user_data.province;
        END IF;

        IF (user_data.type = 'P' AND loan_count >= 2) or (user_data.type = 'L' AND loan_count >= 2*v_population)
            THEN dbms_output.put_line('Error. Current user has reached the upper limit for loans');
            RETURN;
        END IF;

        -- and they are not sanctioned); 
        IF SYSDATE < user_data.ban_up2
            THEN dbms_output.put_line('Error. Current user is banned.');
            RETURN;
        END IF;

        -- checks the availability of a copy of that edition for two weeks (14 days) from the date provided, 
        SELECT min(c.signature) INTO copy_signature FROM COPIES c
            WHERE c.isbn = v_isbn -- find all copies of the book
            AND c.signature NOT IN ( -- exclude the copies that are not available; could be done by LEFT JOIN
                SELECT l.signature 
                    FROM LOANS l 
                    JOIN COPIES c ON c.isbn = v_isbn
                    WHERE l.stopdate-14 <= reservation_date
                        AND l.return+14 >= reservation_date
            );
        IF copy_signature IS NULL
            THEN dbms_output.put_line('Error. No available copies for loaning.');
            RETURN;
        END IF;
        -- and then places the hold (else, reports the hinder). 
        
        SELECT COUNT(*) INTO count_reservations FROM SERVICES s
            JOIN STOPS st ON s.town = st.town AND s.province = st.province
            WHERE s.town = user_data.town
                AND s.province = user_data.province
                AND s.taskdate = reservation_date; 
        IF count_reservations = 0 
            THEN dbms_output.put_line('Error. No service available for the following dates.');
            RETURN;
        END IF;
        -- if found, it is only one as TOWN, PROVINCE AND TASKDATE are the primary key that is unique
        INSERT INTO LOANS (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, "TIME", RETURN) 
            VALUES (copy_signature, current_user, reservation_date, user_data.town, user_data.province, 'R', DEFAULT, reservation_date + 14); -- to have return date two weeks from reservation
        
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
/

