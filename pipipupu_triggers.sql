-- ---------------------- TRIGGERS ---------------------
-- ----------------------------------------------------






---- TASK D
ALTER TABLE books ADD reads INTEGER DEFAULT 0;

-- option 1 works
MERGE INTO books b
USING (
    SELECT b.title, b.author, COUNT(*) AS new_reads
    FROM books b
    JOIN editions e ON b.title = e.title AND b.author = e.author
    JOIN copies c ON e.isbn = c.isbn
    JOIN loans l ON l.signature = c.signature
    GROUP BY b.title, b.author
) src
ON (b.title = src.title AND b.author = src.author)
WHEN MATCHED THEN
    UPDATE SET b.reads = src.new_reads;

-- option 2 untested
UPDATE books b
SET reads = (
    SELECT COUNT(*)
        FROM editions e -- ON b.title = e.title AND b.author = e.author
        JOIN copies c ON e.isbn = c.isbn
        JOIN loans l ON l.signature = c.signature
        WHERE e.title = b.title
        AND e.author = b.author
        GROUP BY e.title, e.author
);

UPDATE books SET reads=0 WHERE reads IS NULL;

-- TESTS
SELECT COUNT(*) FROM (
    SELECT e.title, e.author, COUNT(*) AS new_reads
        FROM editions e -- ON b.title = e.title AND b.author = e.author
        JOIN copies c ON e.isbn = c.isbn
        JOIN loans l ON l.signature = c.signature
        GROUP BY e.title, e.author
);



-- SELECT e.title, e.author, COUNT(*)
-- FROM editions e
-- JOIN copies c ON e.isbn = c.isbn
-- JOIN loans l ON l.signature = c.signature
-- GROUP BY e.title, e.author
-- HAVING COUNT(*) > 5;

CREATE OR REPLACE TRIGGER update_book_read
AFTER INSERT OR UPDATE OF type ON loans
FOR EACH ROW WHEN (NEW.TYPE='L')
DECLARE 
    loan_title editions.title%TYPE;
    loan_author editions.author%TYPE;
BEGIN
    -- obtain loan's book title and author
    SELECT e.title, e.author INTO loan_title, loan_author FROM editions e
        JOIN copies c
        ON e.isbn=c.isbn
        WHERE c.signature=NEW.signature

    -- increase reads count 
    UPDATE books 
        SET reads=reads+1 
        WHERE title=loan_edition.title AND author=loan_edition.author
END;