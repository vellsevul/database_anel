-- ============================================================================
-- Laboratory Work #3 - DML Operations
-- File: lab3_advanced_dml.sql
-- ============================================================================

-- ============================================================================
-- Part A: Database and Table Setup
-- ============================================================================

-- 1. Create database and tables
CREATE DATABASE "advanced_Lab";
-- \c "advanced_Lab"

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

-- Тестовые данные для правильной работы зависимых запросов
INSERT INTO departments (dept_name, budget, manager_id) VALUES
('IT', 150000, 1),
('Sales', 80000, 2),
('HR', 50000, 3);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
('John', 'Doe', 'IT', 75000, '2019-05-12', 'Active'),
('Jane', 'Smith', 'IT', 85000, '2018-03-15', 'Active'),
('Bob', 'Johnson', 'Sales', 45000, '2021-07-20', 'Active'),
('Alice', 'Williams', 'Sales', 55000, '2022-01-10', 'Active'),
('Charlie', 'Brown', 'HR', 35000, '2023-05-01', 'Terminated'),
('David', 'Miller', 'IT', 62000, '2019-11-11', 'Active');


-- ============================================================================
-- Part B: Advanced INSERT Operations
-- ============================================================================

-- 2. INSERT with column specification
INSERT INTO employees (emp_id, first_name, last_name, department) 
VALUES (DEFAULT, 'Michael', 'Scott', 'Management');

-- 3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, salary, status) 
VALUES ('Dwight', 'Schrute', 'Sales', DEFAULT, DEFAULT);

-- 4. INSERT multiple rows in single statement[cite: 1]
INSERT INTO departments (dept_name, budget, manager_id) VALUES 
('Marketing', 60000, 4),
('Finance', 120000, 5),
('Legal', 90000, NULL);

-- 5. INSERT with expressions[cite: 1]
INSERT INTO employees (first_name, last_name, department, hire_date, salary) 
VALUES ('Jim', 'Halpert', 'Sales', CURRENT_DATE, CAST(50000 * 1.1 AS INTEGER));

-- 6. INSERT from SELECT (subquery)[cite: 1]
DROP TABLE IF EXISTS temp_employees;
CREATE TABLE temp_employees AS SELECT * FROM employees WHERE 1=0; -- создание структуры

INSERT INTO temp_employees
SELECT * FROM employees 
WHERE department = 'IT';


-- ============================================================================
-- Part C: Complex UPDATE Operations
-- ============================================================================

-- 7. UPDATE with arithmetic expressions[cite: 1]
UPDATE employees 
SET salary = CAST(salary * 1.10 AS INTEGER);

-- 8. UPDATE with WHERE clause and multiple conditions[cite: 1]
UPDATE employees 
SET status = 'Senior' 
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 9. UPDATE using CASE expression[cite: 1]
UPDATE employees 
SET department = CASE 
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10. UPDATE with DEFAULT[cite: 1]
UPDATE employees 
SET department = DEFAULT 
WHERE status = 'Inactive';

-- 11. UPDATE with subquery[cite: 1]
UPDATE departments d
SET budget = CAST((
    SELECT AVG(e.salary) * 1.20 
    FROM employees e 
    WHERE e.department = d.dept_name
) AS INTEGER)
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.department = d.dept_name
);

-- 12. UPDATE multiple columns[cite: 1]
UPDATE employees 
SET salary = CAST(salary * 1.15 AS INTEGER), 
    status = 'Promoted' 
WHERE department = 'Sales';


-- Part D, Task 15 & 16 (с предзаполнением данных)
INSERT INTO departments (dept_id, dept_name, budget, manager_id) 
VALUES (99, 'Empty Dept', 10000, NULL)
ON CONFLICT (dept_id) DO NOTHING;

-- 15. DELETE with subquery
DELETE FROM departments 
WHERE dept_name NOT IN (
    SELECT DISTINCT department 
    FROM employees 
    WHERE department IS NOT NULL
);

-- 16. DELETE with RETURNING clause
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Old Legacy App', (SELECT dept_id FROM departments LIMIT 1), '2021-01-01', '2022-12-31', 30000);

DELETE FROM projects 
WHERE end_date < '2023-01-01' 
RETURNING *;

-- ============================================================================
-- Part F: RETURNING Clause Operations
-- ============================================================================

-- 20. INSERT with RETURNING[cite: 1]
INSERT INTO employees (first_name, last_name, department, salary) 
VALUES ('Ryan', 'Howard', 'Junior', 42000) 
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- 21. UPDATE with RETURNING[cite: 1]
UPDATE employees 
SET salary = salary + 5000 
WHERE department = 'IT' 
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

-- 22. DELETE with RETURNING all columns[cite: 1]
DELETE FROM employees 
WHERE hire_date < '2020-01-01' 
RETURNING *;


-- ============================================================================
-- Part G: Advanced DML Patterns (Задания 26-27)
-- ============================================================================

-- 26. Data migration simulation
CREATE TABLE IF NOT EXISTS employee_archive (LIKE employees INCLUDING ALL);

INSERT INTO employees (first_name, last_name, status) VALUES ('Old', 'Worker', 'Inactive');

WITH moved_rows AS (
    DELETE FROM employees 
    WHERE status = 'Inactive' 
    RETURNING *
)
INSERT INTO employee_archive 
SELECT * FROM moved_rows;

-- 27. Complex business logic (Гарантируем существование отдела DevOps и его dept_id)
INSERT INTO departments (dept_name, budget) 
VALUES ('DevOps', 60000)
ON CONFLICT DO NOTHING;

-- Наполняем отдел DevOps сотрудниками
INSERT INTO employees (first_name, last_name, department) VALUES 
('Dev1', 'Test', 'DevOps'),
('Dev2', 'Test', 'DevOps'),
('Dev3', 'Test', 'DevOps'),
('Dev4', 'Test', 'DevOps');

-- Безопасный INSERT в projects с подзапросом существующего dept_id
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES (
    'Cloud Migration', 
    (SELECT dept_id FROM departments WHERE dept_name = 'DevOps' LIMIT 1),
    '2025-01-01', 
    '2026-12-31', 
    70000
);

-- Обновление даты окончания проекта
UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000 
  AND dept_id IN (
      SELECT d.dept_id
      FROM departments d
      JOIN employees e ON e.department = d.dept_name
      GROUP BY d.dept_id
      HAVING COUNT(e.emp_id) > 3
  );
