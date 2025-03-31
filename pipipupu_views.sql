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

    CREATE OR REPLACE TRIGGER my_reservations_trigger
        BEFORE INSERT OR UPDATE OF STOPDATE ON my_reservations
        FOR EACH ROW
    DECLARE
        copy_signature copies.signature%TYPE;
        loan_service services%ROWTYPE;
    BEGIN   
        -- IF INSERTING THEN
        --     -- WE NEED YOUR CODE IVAN!!!!!!!!!!!!!!
        -- ELS
        IF NOT UPDATING THEN
            RETURN;
        END IF;

        IF :NEW.STOPDATE < SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20001, 'STOPDATE cannot be in the past!');
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
    END copy_deregistration;

    -- TESTS
    SELECT * FROM my_reservations;
    SELECT * FROM loans WHERE user_id=1546522482;
