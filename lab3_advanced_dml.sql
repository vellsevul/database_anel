-- Laboratory Work #3 - DML Operations


-- Part A: Database and Table Setup

CREATE DATABASE "advanced_Lab";

-- Connect to advanced_Lab before running the rest of the script.

DROP TABLE IF EXISTS employee_archive CASCADE;
DROP TABLE IF EXISTS temp_employees CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;


CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    budget INTEGER,
    manager_id INTEGER
);


CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50) DEFAULT 'Unassigned',
    salary INTEGER DEFAULT 40000,
    hire_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Active'
);


CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER REFERENCES departments(dept_id) ON DELETE SET NULL,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);


-- Sample data

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT', 150000, 1),
    ('Sales', 80000, 2),
    ('HR', 50000, 3);


INSERT INTO employees
    (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('John', 'Doe', 'IT', 75000, '2019-05-12', 'Active'),
    ('Jane', 'Smith', 'IT', 85000, '2018-03-15', 'Active'),
    ('Bob', 'Johnson', 'Sales', 45000, '2021-07-20', 'Active'),
    ('Alice', 'Williams', 'Sales', 55000, '2022-01-10', 'Active'),
    ('Charlie', 'Brown', 'HR', 35000, '2023-05-01', 'Terminated'),
    ('David', 'Miller', 'IT', 62000, '2019-11-11', 'Active');


-- Part B: INSERT


-- 2. INSERT with column specification

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (DEFAULT, 'Michael', 'Scott', 'Management');


-- 3. INSERT with DEFAULT values

INSERT INTO employees
    (first_name, last_name, department, salary, status)
VALUES
    ('Dwight', 'Schrute', 'Sales', DEFAULT, DEFAULT);


-- 4. INSERT multiple rows

INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('Marketing', 60000, 4),
    ('Finance', 120000, 5),
    ('Legal', 90000, NULL);


-- 5. INSERT with expressions

INSERT INTO employees
    (first_name, last_name, department, hire_date, salary)
VALUES
    ('Jim', 'Halpert', 'Sales', CURRENT_DATE, CAST(50000 * 1.1 AS INTEGER));


-- 6. INSERT from SELECT

DROP TABLE IF EXISTS temp_employees;

CREATE TABLE temp_employees AS
SELECT *
FROM employees
WHERE 1 = 0;

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';


-- Part C: UPDATE


-- 7. UPDATE with arithmetic expression

UPDATE employees
SET salary = CAST(salary * 1.10 AS INTEGER);


-- 8. UPDATE with multiple conditions

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';


-- 12. UPDATE multiple columns

UPDATE employees
SET
    salary = CAST(salary * 1.15 AS INTEGER),
    status = 'Promoted'
WHERE department = 'Sales';


-- 9. UPDATE using CASE

UPDATE employees
SET department =
    CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
        ELSE 'Junior'
    END;


-- 10. UPDATE with DEFAULT

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';


-- 11. UPDATE with subquery

UPDATE departments d
SET budget = CAST(
    (
        SELECT AVG(e.salary) * 1.20
        FROM employees e
        WHERE e.department = d.dept_name
    ) AS INTEGER
)
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department = d.dept_name
);


-- Part D: DELETE


-- 13. DELETE with simple condition

DELETE FROM employees
WHERE status = 'Terminated';


-- 14. DELETE with complex condition

INSERT INTO employees
    (first_name, last_name, department, salary, hire_date, status)
VALUES
    ('Test', 'Delete', NULL, 30000, '2024-01-01', 'Active');

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;


-- 15. DELETE with subquery

DELETE FROM departments d
WHERE d.dept_name NOT IN (
    SELECT DISTINCT e.department
    FROM employees e
    WHERE e.department IS NOT NULL
);


-- 16. DELETE with RETURNING

INSERT INTO projects
    (project_name, dept_id, start_date, end_date, budget)
VALUES
    (
        'Old Legacy App',
        (SELECT dept_id FROM departments LIMIT 1),
        '2021-01-01',
        '2022-12-31',
        30000
    );

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


-- Part E: NULL values


-- 17. INSERT with NULL

INSERT INTO employees
    (first_name, last_name, department, salary)
VALUES
    ('Null', 'Employee', NULL, NULL);

INSERT INTO employees
    (first_name, last_name, department, salary)
VALUES
    ('NoDept', 'Employee', NULL, 45000);


-- 18. UPDATE NULL values

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;


-- 19. DELETE with NULL

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;


-- Part F: RETURNING


-- 20. INSERT with RETURNING

INSERT INTO employees
    (first_name, last_name, department, salary)
VALUES
    ('Ryan', 'Howard', 'Junior', 42000)
RETURNING
    emp_id,
    (first_name || ' ' || last_name) AS full_name;


-- 21. UPDATE with RETURNING

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING
    emp_id,
    salary - 5000 AS old_salary,
    salary AS new_salary;


-- 22. DELETE with RETURNING

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


-- Part G: Advanced DML


-- 23. Conditional INSERT

INSERT INTO employees
    (first_name, last_name, department, salary)
SELECT
    'John',
    'Doe',
    'IT',
    70000
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'John'
      AND last_name = 'Doe'
);


-- 24. UPDATE based on department budget

UPDATE employees e
SET salary =
    CAST(
        e.salary *
        CASE
            WHEN d.budget > 100000 THEN 1.10
            ELSE 1.05
        END
        AS INTEGER
    )
FROM departments d
WHERE e.department = d.dept_name;


-- 25. Bulk operations

INSERT INTO employees
    (first_name, last_name, department, salary)
VALUES
    ('Bulk1', 'Test', 'IT', 40000),
    ('Bulk2', 'Test', 'IT', 40000),
    ('Bulk3', 'Test', 'IT', 40000),
    ('Bulk4', 'Test', 'IT', 40000),
    ('Bulk5', 'Test', 'IT', 40000);


UPDATE employees
SET salary = CAST(salary * 1.10 AS INTEGER)
WHERE first_name IN (
    'Bulk1',
    'Bulk2',
    'Bulk3',
    'Bulk4',
    'Bulk5'
);


-- 26. Data migration

CREATE TABLE IF NOT EXISTS employee_archive
(LIKE employees INCLUDING ALL);

INSERT INTO employees
    (first_name, last_name, status)
VALUES
    ('Old', 'Worker', 'Inactive');

WITH moved_rows AS (
    DELETE FROM employees
    WHERE status = 'Inactive'
    RETURNING *
)
INSERT INTO employee_archive
SELECT *
FROM moved_rows;


-- 27. Complex business logic

INSERT INTO departments (dept_name, budget)
SELECT
    'DevOps',
    60000
WHERE NOT EXISTS (
    SELECT 1
    FROM departments
    WHERE dept_name = 'DevOps'
);


INSERT INTO employees
    (first_name, last_name, department)
VALUES
    ('Dev1', 'Test', 'DevOps'),
    ('Dev2', 'Test', 'DevOps'),
    ('Dev3', 'Test', 'DevOps'),
    ('Dev4', 'Test', 'DevOps');


INSERT INTO projects
    (project_name, dept_id, start_date, end_date, budget)
VALUES
    (
        'Cloud Migration',
        (
            SELECT dept_id
            FROM departments
            WHERE dept_name = 'DevOps'
            LIMIT 1
        ),
        '2025-01-01',
        '2026-12-31',
        70000
    );


UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND dept_id IN (
      SELECT d.dept_id
      FROM departments d
      JOIN employees e
        ON e.department = d.dept_name
      GROUP BY d.dept_id
      HAVING COUNT(e.emp_id) > 3
  );


-- Check results

SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM projects;
SELECT * FROM employee_archive;
