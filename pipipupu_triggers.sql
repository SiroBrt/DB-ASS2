-- ---------------------- TRIGGERS ---------------------
-- ----------------------------------------------------

---- TASK 1.4.A
    CREATE OR REPLACE TRIGGER restrict_library_posts
        BEFORE INSERT OR UPDATE OF USER_ID ON posts
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
    END copy_deregistration;


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
        END BEFORE EACH ROW;

        -- Update deregistration date
        AFTER EACH ROW IS
        BEGIN
            IF :NEW.DEREGISTERED='D' THEN
                UPDATE copies
                    SET DEREGISTERED = SYSDATE
                    WHERE SIGNATURE = :NEW.SIGNATURE;
            END IF;
        END AFTER EACH ROW;
    END copy_deregistration;


---- TASK 1.4.D
    -- Add new constraint to loans to avoid exploits
    ALTER TABLE loans ADD CONSTRAINT ck_type CHECK (condition in ('L', 'R') )

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

    ---- Create trigger that updates read counter upon new loan insertion, update or deletion.
    CREATE OR REPLACE TRIGGER update_book_read
        FOR INSERT OR UPDATE OF types OR DELETE ON employees
    COMPOUND TRIGGER
        loan_title editions.title%TYPE;
        loan_author editions.author%TYPE;
        
        BEFORE EACH ROW IS
        BEGIN
            IF UPDATING THEN
                IF :NEW.type = 'R' AND :OLD.type = 'L' THEN
                    RAISE_APPLICATION_ERROR(-20001, 'Cannot change froma loan to a reservation!');
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

                RETURN; -- Skip processing if the previous type was 'L'
            ELSIF UPDATING THEN
                IF :OLD.TYPE = 'L' THEN
                    RETURN; -- Skip processing if the previous type was 'L'
                END IF;
            ELSE
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