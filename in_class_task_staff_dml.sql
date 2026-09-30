-- Setup for In-Class Task: Company Staff (run before the task)
DROP TABLE IF EXISTS employee_archive;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name  VARCHAR(50),
    department VARCHAR(30),
    salary     INTEGER,
    status     VARCHAR(15) DEFAULT 'Active',
    bonus_pct  SMALLINT DEFAULT 0
);

CREATE TABLE departments (
    dept_id   SERIAL PRIMARY KEY,
    dept_name VARCHAR(30),
    budget    INTEGER
);

INSERT INTO employees (first_name, last_name, department, salary, status) VALUES
    ('Aigerim', 'Sadykova',  'IT',    900000, 'Active'),
    ('Nurlan',  'Bekov',     'IT',    600000, 'Active'),
    ('Dana',    'Omarova',   'Sales', 450000, 'Inactive'),
    ('Yerlan',  'Tulegenov', 'Sales', 820000, 'Active'),
    ('Saule',   'Akhmetova', 'HR',    500000, 'Active'),
    ('Marat',   'Ispanov',   NULL,    380000, 'Inactive');

INSERT INTO departments (dept_name, budget) VALUES
    ('IT',        2000000),
    ('Sales',     1500000),
    ('HR',         700000),
    ('Marketing',  900000);
INSERT INTO employees ( first_name, last_name, department, salary )
    SELECT
    ( 'Timur', 'Zhakenov', 'sales',550000 )
WHERE NOT EXISTS ( SELECT 1 from employees WHERE first_name='Timur' AND last_name='Zhakenov')

UPDATE employees
SET bonus_pct =
    CASE
        WHEN salary > 800000 THEN 15
        WHEN salary > 500000 THEN 10
        ELSE 5
    END;

UPDATE departments
SET budget = (
    SELECT SUM(e.salary) * 1.20
    FROM employees e
    WHERE e.department = departments.dept_name
)
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department = departments.dept_name
);

CREATE TABLE employee_archive (
    LIKE employees INCLUDING ALL
);

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive'
RETURNING emp_id,
          first_name || ' ' || last_name AS full_name;
