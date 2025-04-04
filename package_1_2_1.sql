-- PACKAGE HEADER
CREATE OR REPLACE PACKAGE foundicu AS 
    -- TYPE my_type IS RECORD (...);
    current_user CHAR(10);
    PROCEDURE insert_loan(copy_signature IN loans.signature%TYPE);
    
    -- FUNCTION insert_service(town IN services.town%TYPE, province IN services.province%TYPE, taskdate IN services.taskdate%TYPE) RETURN NUMBER;
  
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
