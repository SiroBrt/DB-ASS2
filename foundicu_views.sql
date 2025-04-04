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

---- TASK 1.3.2
    CREATE OR REPLACE VIEW my_loans AS
    SELECT 
        l.signature,
        l.STOPDATE,
        l.TOWN,
        l.PROVINCE,
        l.TYPE,
        l.TIME,
        l.RETURN,
        p.POST_DATE,
        p.TEXT,
        p.likes,
        p.dislikes
    FROM loans l
    LEFT JOIN posts p ON l.signature = p.signature AND l.user_id = p.user_id AND l.stopdate = p.stopdate
    WHERE l.user_id = foundicu.get_current_user() AND l.type = 'L' AND l.return < SYSDATE
    WITH CHECK OPTION;

    -- Allow update post attribute
    -- Disallow insertion and deletion
    CREATE OR REPLACE TRIGGER my_loans_trigger
        INSTEAD OF INSERT OR UPDATE
        ON my_loans
        FOR EACH ROW
    BEGIN
        IF :OLD.text IS NULL THEN
            -- IF INSERTING THEN
            INSERT INTO POSTS (SIGNATURE, USER_ID, STOPDATE, TEXT, POST_DATE, LIKES, DISLIKES)
                VALUES (:NEW.SIGNATURE, foundicu.get_current_user(), :NEW.STOPDATE, :NEW.TEXT, SYSDATE, 0, 0);
        ELSE
            -- IF UPDATING THEN
            UPDATE POSTS
                SET POST_DATE = SYSDATE,
                    TEXT = :NEW.text
                WHERE SIGNATURE = :NEW.SIGNATURE
                    AND USER_ID = foundicu.get_current_user();
        END IF;
    END my_loans_trigger;
    /

    -- -- TESTS
    -- SELECT USER_ID FROM posts WHERE TEXT IS NOT NULL AND ROWNUM=1;
    -- EXEC foundicu.set_current_user(9994309824);
    -- SELECT * FROM my_loans;
    -- SELECT * FROM loans WHERE user_id=9994309824;

---- TASK 1.3.3
    -- CREATE VIEW TABLE
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

    -- ALLOW INSERTION, DELETION AND UPDATE ONLY ON DATES AND TIME
    CREATE OR REPLACE TRIGGER my_reservations_trigger
        INSTEAD OF INSERT OR UPDATE ON my_reservations
        FOR EACH ROW
    BEGIN   
        IF INSERTING THEN
            INSERT INTO LOANS (SIGNATURE, USER_ID, STOPDATE, TOWN, PROVINCE, TYPE, TIME, RETURN) 
                VALUES (:NEW.SIGNATURE, foundicu.get_current_user(), :NEW.STOPDATE, :NEW.TOWN, :NEW.PROVINCE, :NEW.TYPE, :NEW.TIME, :NEW.RETURN); 
        ELSIF UPDATING THEN
            IF :OLD.SIGNATURE!=:NEW.SIGNATURE OR :OLD.TYPE!=:NEW.TYPE OR :OLD.TOWN!=:NEW.TOWN OR :OLD.PROVINCE!=:NEW.PROVINCE
                THEN RAISE_APPLICATION_ERROR(-20043, 'Error. Only date and time from my_reservations are allowed to be changed');
            END IF;

            UPDATE loans SET 
                STOPDATE = :NEW.STOPDATE, 
                TIME = :NEW.TIME
                WHERE SIGNATURE = :OLD.SIGNATURE 
                    AND USER_ID = foundicu.get_current_user();
        END IF;
    END my_reservations_trigger;
    /