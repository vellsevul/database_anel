-- Name: Anel
-- Student ID: 25B031360
-- Lab 5: Database Constraints (PostgreSQL)

-- =====================================================
-- PART 1: CHECK constraints
-- =====================================================

-- Task 1.1: employees
-- age must be 18..65, salary must be > 0
DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    employee_id INTEGER,
    first_name  TEXT,
    last_name   TEXT,
    age         INTEGER CHECK (age BETWEEN 18 AND 65),
    salary      NUMERIC CHECK (salary > 0)
);

-- Task 1.2: products_catalog
-- named constraint valid_discount checks both prices and their relation
DROP TABLE IF EXISTS products_catalog;
CREATE TABLE products_catalog (
    product_id     INTEGER,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Task 1.3: bookings
-- guests 1..10, check out must be later than check in
DROP TABLE IF EXISTS bookings;
CREATE TABLE bookings (
    booking_id      INTEGER,
    check_in_date   DATE,
    check_out_date  DATE,
    num_guests      INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- Task 1.4: testing CHECK constraints

-- valid data
INSERT INTO employees VALUES (1, 'John', 'Smith', 30, 50000);
INSERT INTO employees VALUES (2, 'Anna', 'Lee', 45, 75000.50);

INSERT INTO products_catalog VALUES (1, 'Phone', 500, 450);
INSERT INTO products_catalog VALUES (2, 'Headphones', 100, 80);

INSERT INTO bookings VALUES (1, '2025-01-10', '2025-01-15', 2);
INSERT INTO bookings VALUES (2, '2025-02-01', '2025-02-03', 5);

-- invalid data (commented out because they give errors)

-- age is 17, less than 18
-- INSERT INTO employees VALUES (3, 'Tom', 'Young', 17, 30000);
-- Result: ERROR: violates check constraint "employees_age_check"

-- salary is 0, must be greater than 0
-- INSERT INTO employees VALUES (4, 'Bob', 'Brown', 25, 0);
-- Result: ERROR: violates check constraint "employees_salary_check"

-- discount price is higher than regular price
-- INSERT INTO products_catalog VALUES (3, 'Laptop', 1000, 1200);
-- Result: ERROR: violates check constraint "valid_discount"

-- regular price is negative
-- INSERT INTO products_catalog VALUES (4, 'Mouse', -10, 5);
-- Result: ERROR: violates check constraint "valid_discount"

-- 11 guests, max is 10
-- INSERT INTO bookings VALUES (3, '2025-03-01', '2025-03-05', 11);
-- Result: ERROR: violates check constraint "bookings_num_guests_check"

-- check out is before check in
-- INSERT INTO bookings VALUES (4, '2025-03-10', '2025-03-05', 2);
-- Result: ERROR: violates check constraint "bookings_check"


-- =====================================================
-- PART 2: NOT NULL constraints
-- =====================================================

-- Task 2.1: customers (phone can be NULL)
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    customer_id       INTEGER NOT NULL,
    email             TEXT NOT NULL,
    phone             TEXT,
    registration_date DATE NOT NULL
);

-- Task 2.2: inventory (NOT NULL + CHECK together)
DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (
    item_id      INTEGER NOT NULL,
    item_name    TEXT NOT NULL,
    quantity     INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price   NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Task 2.3: testing NOT NULL

-- complete records
INSERT INTO customers VALUES (1, 'a@mail.com', '555-1111', '2025-01-01');
INSERT INTO customers VALUES (2, 'b@mail.com', '555-2222', '2025-01-02');
INSERT INTO inventory VALUES (1, 'Pen', 100, 1.50, NOW());
INSERT INTO inventory VALUES (2, 'Notebook', 50, 3.20, NOW());

-- NULL in nullable column (phone) - this works
INSERT INTO customers VALUES (3, 'c@mail.com', NULL, '2025-01-03');

-- NULL in NOT NULL columns (errors)

-- email is NULL
-- INSERT INTO customers VALUES (4, NULL, '555-4444', '2025-01-04');
-- Result: ERROR: null value in column "email" violates not-null constraint

-- registration_date is NULL
-- INSERT INTO customers VALUES (5, 'e@mail.com', '555-5555', NULL);
-- Result: ERROR: null value in column "registration_date" violates not-null constraint

-- item_name is NULL
-- INSERT INTO inventory VALUES (3, NULL, 10, 2.00, NOW());
-- Result: ERROR: null value in column "item_name" violates not-null constraint

-- negative quantity
-- INSERT INTO inventory VALUES (4, 'Eraser', -5, 1.00, NOW());
-- Result: ERROR: violates check constraint "inventory_quantity_check"


-- =====================================================
-- PART 3: UNIQUE constraints
-- =====================================================

-- Task 3.1: users with UNIQUE username and email
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id    INTEGER,
    username   TEXT UNIQUE,
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Task 3.2: course_enrollments
-- the same student can't take the same course in the same semester twice
DROP TABLE IF EXISTS course_enrollments;
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1, 100, 'CS101', 'Fall2025');
INSERT INTO course_enrollments VALUES (2, 100, 'CS102', 'Fall2025');  -- different course, ok
INSERT INTO course_enrollments VALUES (3, 101, 'CS101', 'Fall2025');  -- different student, ok

-- same student + course + semester again
-- INSERT INTO course_enrollments VALUES (4, 100, 'CS101', 'Fall2025');
-- Result: ERROR: duplicate key value violates unique constraint
--         "course_enrollments_student_id_course_code_semester_key"

-- Task 3.3: named UNIQUE constraints on users
-- first remove the automatic unnamed ones, then add named ones
ALTER TABLE users DROP CONSTRAINT users_username_key;
ALTER TABLE users DROP CONSTRAINT users_email_key;
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users VALUES (1, 'john', 'john@mail.com', NOW());
INSERT INTO users VALUES (2, 'anna', 'anna@mail.com', NOW());

-- duplicate username
-- INSERT INTO users VALUES (3, 'john', 'other@mail.com', NOW());
-- Result: ERROR: duplicate key value violates unique constraint "unique_username"

-- duplicate email
-- INSERT INTO users VALUES (4, 'newuser', 'anna@mail.com', NOW());
-- Result: ERROR: duplicate key value violates unique constraint "unique_email"


-- =====================================================
-- PART 4: PRIMARY KEY constraints
-- =====================================================

-- Task 4.1: departments
DROP TABLE IF EXISTS employees_dept;  -- depends on departments, drop first
DROP TABLE IF EXISTS departments;
CREATE TABLE departments (
    dept_id   INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location  TEXT
);

INSERT INTO departments VALUES (1, 'IT', 'Almaty');
INSERT INTO departments VALUES (2, 'HR', 'Astana');
INSERT INTO departments VALUES (3, 'Finance', 'Almaty');

-- duplicate dept_id
-- INSERT INTO departments VALUES (1, 'Marketing', 'Shymkent');
-- Result: ERROR: duplicate key value violates unique constraint "departments_pkey"

-- NULL dept_id
-- INSERT INTO departments VALUES (NULL, 'Legal', 'Almaty');
-- Result: ERROR: null value in column "dept_id" violates not-null constraint

-- Task 4.2: student_courses with composite primary key
DROP TABLE IF EXISTS student_courses;
CREATE TABLE student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (1, 10, '2025-09-01', 'A');
INSERT INTO student_courses VALUES (1, 11, '2025-09-01', 'B');  -- same student, other course, ok
INSERT INTO student_courses VALUES (2, 10, '2025-09-01', 'C');  -- other student, same course, ok

-- same pair (student_id, course_id) again
-- INSERT INTO student_courses VALUES (1, 10, '2025-09-05', 'A');
-- Result: ERROR: duplicate key value violates unique constraint "student_courses_pkey"

-- Task 4.3: UNIQUE vs PRIMARY KEY (short explanation)
--
-- 1. Difference between UNIQUE and PRIMARY KEY:
--    Both don't allow duplicate values. But PRIMARY KEY also doesn't allow NULL
--    and it is the main identifier of a row. UNIQUE allows NULL values
--    (and in PostgreSQL there can be several NULLs in a UNIQUE column).
--
-- 2. Single-column vs composite PRIMARY KEY:
--    Single-column: when one column is enough to identify a row
--    (for example dept_id, user_id).
--    Composite: when a row is identified only by a combination of columns,
--    for example student_courses (student_id, course_id) - one student can be in
--    many courses and one course has many students, but the pair is unique.
--
-- 3. Why only one PRIMARY KEY but many UNIQUE:
--    PRIMARY KEY is the main identifier of the table, so there must be only one.
--    But a table can have several other columns which must be unique
--    (email, username, phone, ...), so we can use many UNIQUE constraints.


-- =====================================================
-- PART 5: FOREIGN KEY constraints
-- =====================================================

-- Task 5.1: employees_dept references departments
CREATE TABLE employees_dept (
    emp_id    INTEGER PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    dept_id   INTEGER REFERENCES departments,
    hire_date DATE
);

-- valid dept_id
INSERT INTO employees_dept VALUES (1, 'John', 1, '2024-05-01');
INSERT INTO employees_dept VALUES (2, 'Anna', 2, '2024-06-15');
INSERT INTO employees_dept VALUES (3, 'Mike', 3, '2024-07-20');

-- dept_id 99 does not exist
-- INSERT INTO employees_dept VALUES (4, 'Sam', 99, '2024-08-01');
-- Result: ERROR: insert or update on table "employees_dept" violates
--         foreign key constraint "employees_dept_dept_id_fkey"

-- Task 5.2: library system
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS publishers;

CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    author_id        INTEGER REFERENCES authors,
    publisher_id     INTEGER REFERENCES publishers,
    publication_year INTEGER,
    isbn             TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'George Orwell', 'UK');
INSERT INTO authors VALUES (2, 'Leo Tolstoy', 'Russia');
INSERT INTO authors VALUES (3, 'Mukhtar Auezov', 'Kazakhstan');

INSERT INTO publishers VALUES (1, 'Penguin', 'London');
INSERT INTO publishers VALUES (2, 'Eksmo', 'Moscow');
INSERT INTO publishers VALUES (3, 'Zhazushy', 'Almaty');

INSERT INTO books VALUES (1, '1984', 1, 1, 1949, '978-0-452-28423-4');
INSERT INTO books VALUES (2, 'War and Peace', 2, 2, 1869, '978-5-04-000001-1');
INSERT INTO books VALUES (3, 'Abai Zholy', 3, 3, 1942, '978-601-00-0003-3');

-- wrong author_id
-- INSERT INTO books VALUES (4, 'Test', 99, 1, 2000, '111-1');
-- Result: ERROR: violates foreign key constraint "books_author_id_fkey"

-- duplicate isbn
-- INSERT INTO books VALUES (5, 'Copy', 1, 1, 2000, '978-0-452-28423-4');
-- Result: ERROR: duplicate key value violates unique constraint "books_isbn_key"

-- Task 5.3: ON DELETE options
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS products_fk;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id    INTEGER PRIMARY KEY,
    order_id   INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk,
    quantity   INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO categories VALUES (2, 'Books');

INSERT INTO products_fk VALUES (1, 'Phone', 1);
INSERT INTO products_fk VALUES (2, 'Novel', 2);

INSERT INTO orders VALUES (1, '2025-03-01');
INSERT INTO orders VALUES (2, '2025-03-02');

INSERT INTO order_items VALUES (1, 1, 1, 2);
INSERT INTO order_items VALUES (2, 1, 2, 1);
INSERT INTO order_items VALUES (3, 2, 1, 1);

-- Test 1: delete a category that has products (RESTRICT)
-- DELETE FROM categories WHERE category_id = 1;
-- Result: ERROR: update or delete on table "categories" violates foreign key
--         constraint "products_fk_category_id_fkey" on table "products_fk"
-- Explanation: category 1 still has products, so RESTRICT blocks the delete.

-- Test 2: delete an order (CASCADE)
DELETE FROM orders WHERE order_id = 1;
-- Result: order 1 is deleted and its order_items (item 1 and 2) are deleted automatically.
SELECT * FROM order_items;
-- Result: only item 3 (order 2) is left.

-- Test 3: category without products can be deleted
-- (first remove its products)
DELETE FROM products_fk WHERE product_id = 2;
DELETE FROM categories WHERE category_id = 2;
-- Result: works, because no products reference category 2 anymore.
--
-- Summary:
-- RESTRICT - can't delete the parent row if child rows exist.
-- CASCADE  - deleting the parent row also deletes all its child rows.


-- =====================================================
-- PART 6: E-commerce database
-- =====================================================

-- remove old tables with same names from previous tasks
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id       INTEGER PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE,          -- email must be unique
    phone             TEXT,                          -- phone is optional
    registration_date DATE NOT NULL
);

CREATE TABLE products (
    product_id     INTEGER PRIMARY KEY,
    name           TEXT NOT NULL,
    description    TEXT,
    price          NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL
                 REFERENCES customers ON DELETE CASCADE,  -- delete customer -> delete his orders
    order_date   DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status       TEXT NOT NULL CHECK (
                     status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')
                 )
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL
                    REFERENCES orders ON DELETE CASCADE,    -- delete order -> delete its details
    product_id      INTEGER NOT NULL
                    REFERENCES products ON DELETE RESTRICT, -- can't delete a product that was ordered
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- sample data (5+ rows per table)
INSERT INTO customers VALUES (1, 'Aidar Nurlan', 'aidar@mail.com', '555-0001', '2025-01-05');
INSERT INTO customers VALUES (2, 'Dana Sarsen', 'dana@mail.com', '555-0002', '2025-01-12');
INSERT INTO customers VALUES (3, 'Timur Bek', 'timur@mail.com', NULL, '2025-02-03');
INSERT INTO customers VALUES (4, 'Aigerim Omar', 'aigerim@mail.com', '555-0004', '2025-02-20');
INSERT INTO customers VALUES (5, 'Marat Kasym', 'marat@mail.com', '555-0005', '2025-03-01');

INSERT INTO products VALUES (1, 'Laptop', 'Office laptop', 1200.00, 10);
INSERT INTO products VALUES (2, 'Mouse', 'Wireless mouse', 25.00, 100);
INSERT INTO products VALUES (3, 'Keyboard', 'Mechanical keyboard', 60.00, 50);
INSERT INTO products VALUES (4, 'Monitor', '27 inch monitor', 300.00, 20);
INSERT INTO products VALUES (5, 'Headset', 'Headset with mic', 80.00, 40);

INSERT INTO orders VALUES (1, 1, '2025-03-05', 1225.00, 'pending');
INSERT INTO orders VALUES (2, 2, '2025-03-06', 120.00, 'processing');
INSERT INTO orders VALUES (3, 3, '2025-03-07', 300.00, 'shipped');
INSERT INTO orders VALUES (4, 4, '2025-03-08', 160.00, 'delivered');
INSERT INTO orders VALUES (5, 5, '2025-03-09', 25.00, 'cancelled');

INSERT INTO order_details VALUES (1, 1, 1, 1, 1200.00);
INSERT INTO order_details VALUES (2, 1, 2, 1, 25.00);
INSERT INTO order_details VALUES (3, 2, 3, 2, 60.00);
INSERT INTO order_details VALUES (4, 3, 4, 1, 300.00);
INSERT INTO order_details VALUES (5, 4, 5, 2, 80.00);
INSERT INTO order_details VALUES (6, 5, 2, 1, 25.00);

-- Test queries (all of these should fail, so they are commented out)

-- 1. duplicate primary key
-- INSERT INTO customers VALUES (1, 'Test', 'test@mail.com', NULL, '2025-03-10');
-- Result: ERROR: duplicate key value violates unique constraint "customers_pkey"

-- 2. duplicate email (UNIQUE)
-- INSERT INTO customers VALUES (6, 'Test', 'aidar@mail.com', NULL, '2025-03-10');
-- Result: ERROR: duplicate key value violates unique constraint "customers_email_key"

-- 3. NULL name (NOT NULL)
-- INSERT INTO customers VALUES (6, NULL, 'new@mail.com', NULL, '2025-03-10');
-- Result: ERROR: null value in column "name" violates not-null constraint

-- 4. negative price
-- INSERT INTO products VALUES (6, 'Bad', 'x', -5, 10);
-- Result: ERROR: violates check constraint "products_price_check"

-- 5. negative stock
-- INSERT INTO products VALUES (6, 'Bad', 'x', 5, -1);
-- Result: ERROR: violates check constraint "products_stock_quantity_check"

-- 6. wrong order status
-- INSERT INTO orders VALUES (6, 1, '2025-03-10', 50, 'lost');
-- Result: ERROR: violates check constraint "orders_status_check"

-- 7. order for customer that does not exist
-- INSERT INTO orders VALUES (6, 99, '2025-03-10', 50, 'pending');
-- Result: ERROR: violates foreign key constraint "orders_customer_id_fkey"

-- 8. quantity is 0
-- INSERT INTO order_details VALUES (7, 1, 1, 0, 1200);
-- Result: ERROR: violates check constraint "order_details_quantity_check"

-- 9. delete product that is used in orders (RESTRICT)
-- DELETE FROM products WHERE product_id = 1;
-- Result: ERROR: update or delete on table "products" violates foreign key
--         constraint "order_details_product_id_fkey" on table "order_details"

-- 10. delete order -> its details are deleted too (CASCADE) - this one works
DELETE FROM orders WHERE order_id = 5;
SELECT * FROM order_details WHERE order_id = 5;
-- Result: 0 rows, detail 6 was deleted automatically.

-- 11. delete customer -> his orders and details are deleted (CASCADE) - this one works
DELETE FROM customers WHERE customer_id = 4;
SELECT * FROM orders WHERE customer_id = 4;
-- Result: 0 rows, order 4 and its detail were deleted automatically.
