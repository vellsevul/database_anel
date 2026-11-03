-- ===================== LAB 6: SQL JOINs =====================

-- ---------- Part 1: Database setup ----------
CREATE DATABASE lab6;
-- \c lab6  (в psql подключиться к базе перед созданием таблиц)

CREATE TABLE employees (emp_id INT PRIMARY KEY, emp_name VARCHAR(50), dept_id INT, salary DECIMAL(10, 2));
CREATE TABLE departments (dept_id INT PRIMARY KEY, dept_name VARCHAR(50), location VARCHAR(50));
CREATE TABLE projects (project_id INT PRIMARY KEY, project_name VARCHAR(50), dept_id INT, budget DECIMAL(10, 2));

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES (1, 'John Smith', 101, 50000), (2, 'Jane Doe', 102, 60000), (3, 'Mike Johnson', 101, 55000), (4, 'Sarah Williams', 103, 65000), (5, 'Tom Brown', NULL, 45000);
INSERT INTO departments (dept_id, dept_name, location) VALUES (101, 'IT', 'Building A'), (102, 'HR', 'Building B'), (103, 'Finance', 'Building C'), (104, 'Marketing', 'Building D');
INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES (1, 'Website Redesign', 101, 100000), (2, 'Employee Training', 102, 50000), (3, 'Budget Analysis', 103, 75000), (4, 'Cloud Migration', 101, 150000), (5, 'AI Research', NULL, 200000);

-- ---------- Part 2: CROSS JOIN ----------
-- 2.1 Все комбинации сотрудников и отделов. Строк: N x M = 5 x 4 = 20
SELECT e.emp_name, d.dept_name FROM employees e CROSS JOIN departments d;

-- 2.2 Альтернативный синтаксис
-- a) запятая
SELECT e.emp_name, d.dept_name FROM employees e, departments d;
-- b) INNER JOIN ON TRUE
SELECT e.emp_name, d.dept_name FROM employees e INNER JOIN departments d ON TRUE;

-- 2.3 Матрица сотрудники x проекты
SELECT e.emp_name, p.project_name FROM employees e CROSS JOIN projects p;

-- ---------- Part 3: INNER JOIN ----------
-- 3.1 INNER JOIN с ON. Возвращается 4 строки; Tom Brown не включен, т.к. его dept_id = NULL и совпадений в departments нет
SELECT e.emp_name, d.dept_name, d.location FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 3.2 INNER JOIN с USING. Отличие: колонка dept_id объединяется в одну (при SELECT * она выводится один раз, а не два)
SELECT emp_name, dept_name, location FROM employees INNER JOIN departments USING (dept_id);

-- 3.3 NATURAL INNER JOIN (соединение по всем одноименным колонкам, здесь по dept_id)
SELECT emp_name, dept_name, location FROM employees NATURAL INNER JOIN departments;

-- 3.4 Три таблицы
SELECT e.emp_name, d.dept_name, p.project_name FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id INNER JOIN projects p ON d.dept_id = p.dept_id;

-- ---------- Part 4: LEFT JOIN ----------
-- 4.1 Все сотрудники. Tom Brown присутствует, а поля отдела (dept_dept, dept_name) у него NULL
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- 4.2 LEFT JOIN с USING
SELECT emp_name, dept_id, dept_name FROM employees LEFT JOIN departments USING (dept_id);

-- 4.3 Сотрудники без отдела
SELECT e.emp_name, e.dept_id FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id WHERE d.dept_id IS NULL;

-- 4.4 Отделы и количество сотрудников (включая 0)
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id GROUP BY d.dept_id, d.dept_name ORDER BY employee_count DESC;

-- ---------- Part 5: RIGHT JOIN ----------
-- 5.1 Все отделы с сотрудниками (включая пустые)
SELECT e.emp_name, d.dept_name FROM employees e RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 5.2 То же через LEFT JOIN (меняем таблицы местами)
SELECT e.emp_name, d.dept_name FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id;

-- 5.3 Отделы без сотрудников
SELECT d.dept_name, d.location FROM employees e RIGHT JOIN departments d ON e.dept_id = d.dept_id WHERE e.emp_id IS NULL;

-- ---------- Part 6: FULL JOIN ----------
-- 6.1 Все сотрудники и все отделы. NULL слева (в данных сотрудника): отдел Marketing. NULL справа (в данных отдела): Tom Brown
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name FROM employees e FULL JOIN departments d ON e.dept_id = d.dept_id;

-- 6.2 Все отделы и все проекты
SELECT d.dept_name, p.project_name, p.budget FROM departments d FULL JOIN projects p ON d.dept_id = p.dept_id;

-- 6.3 Записи-"сироты"
SELECT CASE WHEN e.emp_id IS NULL THEN 'Department without employees' WHEN d.dept_id IS NULL THEN 'Employee without department' ELSE 'Matched' END AS record_status, e.emp_name, d.dept_name FROM employees e FULL JOIN departments d ON e.dept_id = d.dept_id WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

-- ---------- Part 7: ON vs WHERE ----------
-- 7.1 Фильтр в ON (LEFT JOIN): все сотрудники остаются, отдел подставляется только для Building A, у остальных NULL
SELECT e.emp_name, d.dept_name, e.salary FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- 7.2 Фильтр в WHERE (LEFT JOIN): сотрудники не из Building A (и без отдела) отсеиваются после соединения
SELECT e.emp_name, d.dept_name, e.salary FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id WHERE d.location = 'Building A';

-- 7.3 То же с INNER JOIN
-- Фильтр в ON
SELECT e.emp_name, d.dept_name, e.salary FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';
-- Фильтр в WHERE
SELECT e.emp_name, d.dept_name, e.salary FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id WHERE d.location = 'Building A';
-- Результаты одинаковые: INNER JOIN и так отбрасывает несовпавшие строки, поэтому позиция условия не важна

-- ---------- Part 8: Complex JOIN scenarios ----------
-- 8.1 Все отделы + сотрудники + проекты
SELECT d.dept_name, e.emp_name, e.salary, p.project_name, p.budget FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id LEFT JOIN projects p ON d.dept_id = p.dept_id ORDER BY d.dept_name, e.emp_name;

-- 8.2 Self join
ALTER TABLE employees ADD COLUMN manager_id INT;
UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;
SELECT e.emp_name AS employee, m.emp_name AS manager FROM employees e LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- 8.3 Отделы со средней зарплатой > 50000
SELECT d.dept_name, AVG(e.salary) AS avg_salary FROM departments d INNER JOIN employees e ON d.dept_id = e.dept_id GROUP BY d.dept_id, d.dept_name HAVING AVG(e.salary) > 50000;

-- ---------- Lab Questions (ответы) ----------
-- 1. INNER JOIN возвращает только совпавшие строки; LEFT JOIN возвращает все строки левой таблицы + совпавшие справа (иначе NULL)
-- 2. CROSS JOIN: матрицы доступности/расписания, генерация всех комбинаций (размер x цвет), тестовые данные
-- 3. В outer join условие в ON влияет на сопоставление (несовпавшие строки сохраняются с NULL), а WHERE фильтрует уже готовый результат; в inner join несовпавшие строки отбрасываются в любом случае, поэтому разницы нет
-- 4. 5 x 10 = 50
-- 5. NATURAL JOIN соединяет по всем колонкам с одинаковыми именами в обеих таблицах
-- 6. Риски: при добавлении/переименовании колонок соединение молча меняется; случайные совпадения имен дают неверный результат; нечитаемо
-- 7. SELECT * FROM B RIGHT JOIN A ON A.id = B.id;
-- 8. FULL OUTER JOIN: когда нужны все строки из обеих таблиц, например поиск несоответствий/сирот в данных, сверка двух источников

-- ---------- Additional Challenges ----------
-- 1. Эмуляция FULL JOIN через UNION LEFT и RIGHT
SELECT e.emp_name, d.dept_name FROM employees e LEFT JOIN departments d ON e.dept_id = d.dept_id UNION SELECT e.emp_name, d.dept_name FROM employees e RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 2. Сотрудники из отделов, где больше одного проекта
SELECT e.emp_name, d.dept_name, COUNT(p.project_id) AS project_count FROM employees e INNER JOIN departments d ON e.dept_id = d.dept_id INNER JOIN projects p ON d.dept_id = p.dept_id GROUP BY e.emp_id, e.emp_name, d.dept_name HAVING COUNT(p.project_id) > 1;

-- 3. Иерархия: сотрудник -> руководитель -> руководитель руководителя
SELECT e.emp_name AS employee, m.emp_name AS manager, mm.emp_name AS managers_manager FROM employees e LEFT JOIN employees m ON e.manager_id = m.emp_id LEFT JOIN employees mm ON m.manager_id = mm.emp_id;

-- 4. Все пары сотрудников из одного отдела
SELECT e1.emp_name AS employee1, e2.emp_name AS employee2, e1.dept_id FROM employees e1 INNER JOIN employees e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id;
