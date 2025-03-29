-- ---------------------- TRIGGERS ---------------------
-- ----------------------------------------------------






---- TASK D
ALTER TABLE books ADD reads INTEGER;

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


SELECT COUNT(*) FROM (
    SELECT e.title, e.author, COUNT(*) AS new_reads
        FROM editions e -- ON b.title = e.title AND b.author = e.author
        JOIN copies c ON e.isbn = c.isbn
        JOIN loans l ON l.signature = c.signature
        GROUP BY e.title, e.author
);

-- UPDATE books b
-- SET b.reads = (
--     SELECT COUNT(*)
--     FROM editions e
--     JOIN copies c ON e.isbn = c.isbn
--     JOIN loans l ON l.signature = c.signature
--     WHERE e.title = b.title AND e.author = b.author
-- );

-- UPDATE (
--     SELECT b.reads, COUNT(*) OVER (PARTITION BY b.title, b.author) AS new_reads
--     FROM books b
--     JOIN editions e ON b.title = e.title AND b.author = e.author
--     JOIN copies c ON e.isbn = c.isbn
--     JOIN loans l ON l.signature = c.signature
-- ) 
-- SET reads = new_reads;


-- SELECT e.title, e.author, COUNT(*)
-- FROM editions e
-- JOIN copies c ON e.isbn = c.isbn
-- JOIN loans l ON l.signature = c.signature
-- GROUP BY e.title, e.author
-- HAVING COUNT(*) > 5;