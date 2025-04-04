-- ---------------------- VIEWS -----------------------
-- ----------------------------------------------------

---- TASK 1.3.1
    CREATE OR REPLACE VIEW my_data AS
    SELECT 
        USER_ID,
        ID_CARD,
        NAME || ' ' || SURNAME1 || ' ' || SURNAME2 AS FULLNAME,
        BIRTHDATE,
        TOWN,
        PROVINCE,
        ADDRESS,
        EMAIL,
        PHONE,
        TYPE,
        BAN_UP2
    FROM users u
    WHERE u.user_id = foundicu.get_current_user()
    WITH READ ONLY;

    -- -- TESTS
    -- EXEC foundicu.set_current_user(9994309824);
    -- SELECT * FROM my_data;

---- TASK 1.3.2
    CREATE OR REPLACE VIEW my_loans AS
    SELECT 
        l.SIGNATURE,
        l.STOPDATE,
        l.TOWN,
        l.PROVINCE,
        l.TYPE,
        l.TIME,
        l.RETURN,
        p.POST_DATE,
        p.TEXT,
        p.LIKES,
        p.DISLIKES
    FROM loans l
    LEFT JOIN posts p ON l.signature = p.signature
    WHERE l.user_id = foundicu.get_current_user() AND l.type = 'L'
    WITH CHECK OPTION;

    -- TESTS
    -- SELECT USER_ID FROM posts WHERE TEXT IS NOT NULL AND ROWNUM=1;
    -- EXEC foundicu.set_current_user(9994309824);
    -- SELECT * FROM my_loans;
    -- SELECT * FROM loans WHERE user_id=9994309824;

---- TASK 1.3.3
    CREATE OR REPLACE VIEW my_reservations AS
    SELECT 
        SIGNATURE,
        STOPDATE,
        TOWN,
        PROVINCE,
        TYPE,
        TIME,
        RETURN
    FROM loans l
    WHERE l.user_id = foundicu.get_current_user() AND l.type = 'R'
    WITH CHECK OPTION;

    BEGIN
        FOUNDICU.SET_CURRENT_USER(1546522482);
    END;
    SELECT * FROM my_reservations;

    SELECT * FROM loans WHERE USER_ID=1546522482;
    UPDATE loans SET 
        STOPDATE = '20-NOV-24',
        TYPE = 'R',
        RETURN = NULL 
        WHERE USER_ID=1546522482 AND SIGNATURE='LB296';

    DELETE FROM loans WHERE USER_ID=1546522482 AND SIGNATURE='LB296' AND STOPDATE='16-NOV-24';


    CREATE OR REPLACE TRIGGER my_reservations_trigger
        INSTEAD OF INSERT OR UPDATE ON my_reservations
        FOR EACH ROW
    DECLARE
        user_data users%ROWTYPE;
        copy_signature copies.signature%TYPE;
        loan_service services%ROWTYPE;
    BEGIN   
        SELECT * INTO user_data FROM users WHERE users.user_id = current_user;
        EXCEPTION
            WHEN NO_DATA_FOUND
                THEN RAISE_APPLICATION_ERROR(-20001, 'Error. Current user does not exist.');
        END;

        -- Check if new reservation date is valid (and if user is banned)
        IF :NEW.STOPDATE < SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20031, 'Cannot allocate a reservation in the past STOPDATE!');
        ELSIF :NEW.STOPDATE < user_data.ban_up2 THEN 
            RAISE_APPLICATION_ERROR(-20002, 'Cannot allocate reservation. User is banned until ' || user_data.ban_up2 || '!');
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
       
        -- Proceed with operation 
        IF INSERTING THEN
            INSERT INTO LOANS (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, "TIME", RETURN) 
                VALUES (copy_signature, current_user, reservation_date, user_data.town, user_data.province, 'R', DEFAULT, reservation_date + 14); -- to have return date two weeks from reservation
        ELSIF UPDATING THEN
            UPDATE loans SET 
                STOPDATE = :NEW.STOPDATE, 
                TOWN = :NEW.TOWN, 
                PROVINCE = :NEW.PROVINCE,
                TIME = :NEW.TIME
                WHERE SIGNATURE = :OLD.SIGNATURE 
                    AND USER_ID = foundicu.get_current_user();
        END IF;

        -- SELECT isbn INTO book_isbn FROM copies c
        --     WHERE c.signature = :NEW.SIGNATURE;
        
        -- SELECT min(signature) INTO copy_signature FROM copies c
        --     WHERE c.isbn = book_isbn
        --     AND c.signature NOT IN (
        --         SELECT signature 
        --             FROM loans l 
        --             JOIN copies c ON c.isbn = book_isbn
        --             WHERE l.stopdate-14 <= :NEW.STOPDATE
        --                 AND l.return+14 >= :NEW.STOPDATE
        --     );

        -- -- update service or insert new one xdddd
        -- BEGIN
        --     SELECT * INTO loan_service FROM services 
        --         WHERE town=:NEW.town AND province=:NEW.province AND taskdate=:NEW.stopdate;
        -- EXCEPTION
        --     WHEN NO_DATA_FOUND THEN
        --         BEGIN
        --             INSERT INTO services (town, province, taskdate) 
        --                 VALUES (:NEW.town, :NEW.province, :NEW.stopdate);  
        --         END;
        -- END;
    END my_reservations_trigger;

    -- TESTS
    SELECT * FROM my_reservations;
    SELECT * FROM loans WHERE user_id=1546522482;
