-- ---------------------- TRIGGERS ---------------------
-- ----------------------------------------------------

-- 1.4.d
CREATE OR REPLACE TRIGGER update_book_read
AFTER INSERT OR UPDATE ON TYPE
FOR EACH ROW WHEN (NEW.TYPE='L')
BEGIN
    -- obtain loan's book title and author

    -- increase reads count 
    UPDATE books 
        SET reads=reads+1 
        WHERE title=title AND author=author
END;