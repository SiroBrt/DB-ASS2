-- ---------------------- TRIGGERS ---------------------
-- ----------------------------------------------------

---- TASK 1.4.A
    -- Delete posts from libraries
    DELETE FROM POSTS
        WHERE USER_ID IN (
            SELECT DISTINCT USER_ID 
                FROM USERS 
                WHERE type='L'
        );
     
    -- Trigger for restricting library posts
    CREATE OR REPLACE TRIGGER restrict_library_posts
        BEFORE INSERT OR UPDATE OF USER_ID ON posts
        FOR EACH ROW
    DECLARE
        user_type users.type%TYPE;
    BEGIN
        IF UPDATING THEN
            SELECT type INTO user_type FROM users 
                WHERE user_id=:OLD.user_id;
            IF user_type='L' THEN 
                RAISE_APPLICATION_ERROR(-20001, 'Error. Libraries cannot write posts');
                RETURN;
            END IF;
        ELSIF INSERTING THEN
            SELECT type INTO user_type FROM users 
                WHERE user_id=:NEW.user_id;
            IF user_type='L' THEN 
                RAISE_APPLICATION_ERROR(-20001, 'Error. Libraries cannot write posts');
                RETURN;
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND 
            THEN dbms_output.put_line('Data Integrity Error. User not found'); 
    END restrict_library_posts;


---- TASK 1.4.B
    -- Prevents changing status of 'D' copies
    -- Updates deregistration date when copy is deregistered
    CREATE OR REPLACE TRIGGER copy_deregistration
        FOR INSERT OR UPDATE OF CONDITION ON copies
    COMPOUND TRIGGER
        BEFORE EACH ROW IS
        BEGIN 
            IF UPDATING THEN
                IF :OLD.CONDITION='D' AND :NEW.CONDITION<>'D' THEN
                    RAISE_APPLICATION_ERROR(-20001, 'Cannot change copy condition from deregistered to another value (they are already physically destroyed)!');
                END IF;
            END IF;

            IF :NEW.CONDITION='D' THEN
                :NEW.DEREGISTERED := SYSDATE;
            END IF;
        END BEFORE EACH ROW;
    END copy_deregistration;

    SELECT * FROM copies WHERE condition='D';
    SELECT loans.signature, condition FROM loans 
        LEFT JOIN copies
        ON loans.signature=copies.signature
        WHERE ROWNUM=1;



---- TASK 1.4.D
    -- Add new constraint to loans to avoid exploits
    ALTER TABLE loans ADD CONSTRAINT ck_type CHECK (type in ('L', 'R'));

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

    --- Create trigger that updates read counter upon new loan insertion, update or deletion.
    CREATE OR REPLACE TRIGGER update_book_read
        FOR INSERT OR UPDATE OF type OR DELETE ON loans
    COMPOUND TRIGGER
        loan_title editions.title%TYPE;
        loan_author editions.author%TYPE;
        
        BEFORE EACH ROW IS
        BEGIN
            IF UPDATING THEN
                IF :NEW.type = 'R' AND :OLD.type = 'L' THEN
                    RAISE_APPLICATION_ERROR(-20001, 'Cannot change from a loan to a reservation!');
                END IF;
            END IF;
        END BEFORE EACH ROW;

        AFTER EACH ROW IS
        BEGIN
            IF DELETING THEN
                -- Obtain loan's book title and author
                SELECT e.title, e.author INTO loan_title, loan_author FROM editions e
                    JOIN copies c ON e.isbn=c.isbn
                    WHERE c.signature=:OLD.signature;

                -- Decrease reads count 
                UPDATE books 
                    SET reads=reads-1 
                    WHERE title=loan_title AND author=loan_author;

            ELSIF (UPDATING AND :OLD.TYPE <> 'L') OR INSERTING THEN
                -- Obtain loan's book title and author
                SELECT e.title, e.author INTO loan_title, loan_author FROM editions e
                    JOIN copies c ON e.isbn=c.isbn
                    WHERE c.signature=:NEW.signature;

                -- Increase reads count 
                UPDATE books 
                    SET reads=reads+1 
                    WHERE title=loan_title AND author=loan_author;
            END IF;
        END AFTER EACH ROW;
    END;