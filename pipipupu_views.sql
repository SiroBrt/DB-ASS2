-- ---------------------- VIEWS ---------------------
-- ----------------------------------------------------

CREATE OR REPLACE FUNCTION current_user() IS
BEGIN
    RETURN
END;

CREATE VIEW my_data AS
SELECT 
    B3.TITLE, 
    B3.AUTHOR
FROM B3
WITH READ ONLY;

CREATE VIEW my_loans AS
SELECT 
    B3.TITLE, 
    B3.AUTHOR
FROM B3
WITH CHECK OPTION;

CREATE VIEW my_reservations AS
SELECT 
    B3.TITLE, 
    B3.AUTHOR
FROM B3
WITH CHECK OPTION;