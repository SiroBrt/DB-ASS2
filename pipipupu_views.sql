-- ---------------------- VIEWS ---------------------
-- ----------------------------------------------------

CREATE VIEW my_data AS
SELECT 
    *
FROM users u
WHERE u.user_id = current_user
WITH READ ONLY;


CREATE VIEW my_loans AS
SELECT 
    l.SIGNATURE,
    l.STOPDATE,
    l.TOWN,
    l.PROVINCE,
    l.TYPE,
    l.TIME,
    l.RETURN,
    p.POST
FROM loans l
JOIN posts p ON l.signature = p.signature
WHERE loans.user_id = current_user AND loans.type = 'L'
WITH CHECK OPTION;


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
WHERE loans.user_id = current_user AND loans.type = 'R'
WITH CHECK OPTION;

-- CREATE OR REPLACE TRIGGER my_reservations_trigger
-- BEFORE INSERT OR UPDATE OF TIME ON my_reservations
-- FOR EACH ROW
-- BEGIN
--     IF :NEW.TIME < 0 OR :NEW.TIME > 30 THEN
--         RAISE_APPLICATION_ERROR(-20001, 'Time must be between 0 and 30 days');
--     END IF;
-- END;