-- ---------------------- TRIGGERS ---------------------
-- ----------------------------------------------------

---- TASK 1.4.D
    -- Create new column 'reads' in table 'books'
    ALTER TABLE books ADD reads INTEGER DEFAULT 0;

    -- Counts current reads for each book and updates the counter
    BEGIN
        FOR book_reads IN (
            SELECT e.title, e.author, COUNT(*) as new_reads
            FROM editions e
            JOIN copies c ON e.isbn = c.isbn
            JOIN loans l ON l.signature = c.signature
            GROUP BY e.title, e.author
        ) LOOP
            UPDATE books
            SET reads = book_reads.new_reads
            WHERE title = book_reads.title AND author = book_reads.author;
        END LOOP;
    END;

    ---- Create trigger that updates read counter upon new loan insertion
    CREATE OR REPLACE TRIGGER update_book_read
        AFTER INSERT OR UPDATE OF type ON loans
        FOR EACH ROW 
    WHEN (NEW.TYPE='L')
    DECLARE 
        loan_title editions.title%TYPE;
        loan_author editions.author%TYPE;
    BEGIN
        -- Obtain loan's book title and author
        SELECT e.title, e.author INTO loan_title, loan_author FROM editions e
            JOIN copies c ON e.isbn=c.isbn
            WHERE c.signature=:NEW.signature;

        -- Increase reads count 
        UPDATE books 
            SET reads=reads+1 
            WHERE title=loan_title AND author=loan_author;
    END;

    -- -- TESTS
    -- SELECT title, author, reads FROM books
    --     WHERE reads > 5;

