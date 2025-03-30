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

    -- TESTS
    EXEC foundicu.set_current_user(9994309824);
    SELECT * FROM my_data;

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

    -- CREATE OR REPLACE TRIGGER my_reservations_trigger
    -- BEFORE INSERT OR UPDATE OF TIME ON my_reservations
    -- FOR EACH ROW
    -- BEGIN
    --     IF :NEW.TIME < 0 OR :NEW.TIME > 30 THEN
    --         RAISE_APPLICATION_ERROR(-20001, 'Time must be between 0 and 30 days');
    --     END IF;
    -- END;

    -- TESTS
    SELECT * FROM my_reservations;
    SELECT * FROM loans WHERE user_id=1546522482;
