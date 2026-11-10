-- ===== Setup (Lab 6) =====
CREATE TABLE employees (emp_id INT PRIMARY KEY, emp_name VARCHAR(50), dept_id INT, salary DECIMAL(10,2));
CREATE TABLE departments (dept_id INT PRIMARY KEY, dept_name VARCHAR(50), location VARCHAR(50));
CREATE TABLE projects (project_id INT PRIMARY KEY, project_name VARCHAR(50), dept_id INT, budget DECIMAL(10,2));
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1,'John Smith',101,50000),(2,'Jane Doe',102,60000),(3,'Mike Johnson',101,55000),
(4,'Sarah Williams',103,65000),(5,'Tom Brown',NULL,45000);
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101,'IT','Building A'),(102,'HR','Building B'),(103,'Finance','Building C'),(104,'Marketing','Building D');
INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
(1,'Website Redesign',101,100000),(2,'Employee Training',102,50000),(3,'Budget Analysis',103,75000),
(4,'Cloud Migration',101,150000),(5,'AI Research',NULL,200000);

-- ===== Part 2: Basic views =====
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e JOIN departments d ON e.dept_id = d.dept_id;
SELECT * FROM employee_details; -- 4 строки; Tom Brown не виден: dept_id NULL, INNER JOIN его отбрасывает

CREATE VIEW dept_statistics AS
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count, ROUND(AVG(e.salary),2) AS avg_salary,
       MAX(e.salary) AS max_salary, MIN(e.salary) AS min_salary
FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;
SELECT * FROM dept_statistics ORDER BY employee_count DESC;

CREATE VIEW project_overview AS
SELECT p.project_name, p.budget, d.dept_name, d.location,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = d.dept_id) AS team_size
FROM projects p JOIN departments d ON p.dept_id = d.dept_id;

CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;
SELECT * FROM high_earners; -- view всегда показывает актуальные данные, видны все с salary > 55000 (Jane, Sarah)

-- ===== Part 3: Modifying views =====
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE WHEN e.salary > 60000 THEN 'High' WHEN e.salary > 50000 THEN 'Medium' ELSE 'Standard' END AS salary_grade
FROM employees e JOIN departments d ON e.dept_id = d.dept_id;

ALTER VIEW high_earners RENAME TO top_performers;
SELECT * FROM top_performers;

CREATE TEMP VIEW temp_view AS SELECT * FROM employees WHERE salary < 50000;
DROP VIEW temp_view;

-- ===== Part 4: Updatable views =====
CREATE VIEW employee_salaries AS SELECT emp_id, emp_name, dept_id, salary FROM employees;

UPDATE employee_salaries SET salary = 52000 WHERE emp_name = 'John Smith';
SELECT * FROM employees WHERE emp_name = 'John Smith'; -- да, базовая таблица обновилась (простой view обновляемый)

INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary) VALUES (6, 'Alice Johnson', 102, 58000);
SELECT * FROM employees; -- вставка успешна, Alice есть в employees

CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary FROM employees WHERE dept_id = 101
WITH LOCAL CHECK OPTION;
-- Ошибка "new row violates check option for view it_employees": dept_id=103 не удовлетворяет WHERE view. Раскомментируй для скриншота:
-- INSERT INTO it_employees (emp_id, emp_name, dept_id, salary) VALUES (7, 'Bob Wilson', 103, 60000);

-- ===== Part 5: Materialized views =====
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id, d.dept_name,
       COALESCE(e.cnt,0) AS total_employees, COALESCE(e.sal,0) AS total_salaries,
       COALESCE(p.cnt,0) AS total_projects, COALESCE(p.bud,0) AS total_budget
FROM departments d
LEFT JOIN (SELECT dept_id, COUNT(*) cnt, SUM(salary) sal FROM employees GROUP BY dept_id) e ON e.dept_id = d.dept_id
LEFT JOIN (SELECT dept_id, COUNT(*) cnt, SUM(budget) bud FROM projects GROUP BY dept_id) p ON p.dept_id = d.dept_id
WITH DATA;
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES (8, 'Charlie Brown', 101, 54000);
SELECT * FROM dept_summary_mv; -- до refresh: Charlie не учтён, mat. view хранит снимок данных
REFRESH MATERIALIZED VIEW dept_summary_mv;
SELECT * FROM dept_summary_mv; -- после refresh: IT показывает на 1 сотрудника больше

CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id ON dept_summary_mv (dept_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv; -- плюс CONCURRENTLY: view не блокируется для SELECT во время обновления

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name, p.budget, d.dept_name,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = p.dept_id) AS employee_count
FROM projects p LEFT JOIN departments d ON p.dept_id = d.dept_id
WITH NO DATA;
-- Ошибка "materialized view has not been populated". Раскомментируй для скриншота:
-- SELECT * FROM project_stats_mv;
REFRESH MATERIALIZED VIEW project_stats_mv; -- исправление: наполнить view данными
SELECT * FROM project_stats_mv;

-- ===== Part 6: Roles =====
CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user LOGIN PASSWORD 'report456';
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

CREATE ROLE db_creator LOGIN CREATEDB PASSWORD 'creator789';
CREATE ROLE user_manager LOGIN CREATEROLE PASSWORD 'manager101';
CREATE ROLE admin_user LOGIN SUPERUSER PASSWORD 'admin999';

GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;
CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';
GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

-- ===== Part 7: Advanced role management =====
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;
CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';
GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;
SELECT tablename, tableowner FROM pg_tables WHERE schemaname = 'public';

CREATE ROLE temp_owner LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;
REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

CREATE VIEW hr_employee_view AS SELECT * FROM employees WHERE dept_id = 102;
GRANT SELECT ON hr_employee_view TO hr_team;
CREATE VIEW finance_employee_view AS SELECT emp_id, emp_name, salary FROM employees;
GRANT SELECT ON finance_employee_view TO finance_team;

-- ===== Part 8: Practical scenarios =====
-- active projects = все проекты отдела (колонки статуса в таблице нет)
CREATE VIEW dept_dashboard AS
SELECT d.dept_name, d.location,
       COALESCE(e.cnt,0) AS employee_count,
       COALESCE(ROUND(e.avg_sal::numeric,2),0) AS avg_salary,
       COALESCE(p.cnt,0) AS active_projects,
       COALESCE(p.bud,0) AS total_project_budget,
       COALESCE(ROUND(p.bud::numeric / NULLIF(e.cnt,0),2),0) AS budget_per_employee -- NULLIF защищает от деления на 0
FROM departments d
LEFT JOIN (SELECT dept_id, COUNT(*) cnt, AVG(salary) avg_sal FROM employees GROUP BY dept_id) e ON e.dept_id = d.dept_id
LEFT JOIN (SELECT dept_id, COUNT(*) cnt, SUM(budget) bud FROM projects GROUP BY dept_id) p ON p.dept_id = d.dept_id;
SELECT * FROM dept_dashboard;

ALTER TABLE projects ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
CREATE VIEW high_budget_projects AS
SELECT p.project_name, p.budget, d.dept_name, p.created_date,
       CASE WHEN p.budget > 150000 THEN 'Critical Review Required'
            WHEN p.budget > 100000 THEN 'Management Approval Needed'
            ELSE 'Standard Process' END AS approval_status
FROM projects p LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;
SELECT * FROM high_budget_projects;

CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role; -- ALL TABLES включает и views
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE ROLE alice LOGIN PASSWORD 'alice123';
CREATE ROLE bob LOGIN PASSWORD 'bob123';
CREATE ROLE charlie LOGIN PASSWORD 'charlie123';
GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
