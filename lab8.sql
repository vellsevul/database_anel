-- =====================================================================
-- SETUP: таблицы из задания. DROP нужен, чтобы скрипт можно было запускать повторно.
-- CASCADE удалит и зависящие от таблиц view (например, из лабы 7)
-- =====================================================================
DROP TABLE IF EXISTS projects, employees, departments CASCADE;

CREATE TABLE departments (dept_id INT PRIMARY KEY, dept_name VARCHAR(50), location VARCHAR(50));
CREATE TABLE employees (
    emp_id INT PRIMARY KEY, emp_name VARCHAR(100), dept_id INT, salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id));
CREATE TABLE projects (
    proj_id INT PRIMARY KEY, proj_name VARCHAR(100), budget DECIMAL(12,2), dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id));

INSERT INTO departments VALUES (101,'IT','Building A'),(102,'HR','Building B'),(103,'Operations','Building C');
INSERT INTO employees VALUES (1,'John Smith',101,50000),(2,'Jane Doe',101,55000),(3,'Mike Johnson',102,48000),
                             (4,'Sarah Williams',102,52000),(5,'Tom Brown',103,60000);
INSERT INTO projects VALUES (201,'Website Redesign',75000,101),(202,'Database Migration',120000,101),(203,'HR System Upgrade',50000,102);

-- =====================================================================
-- PART 2: ПРОСТЫЕ ИНДЕКСЫ
-- Индекс это отдельная структура, по которой БД быстро находит строки, не читая всю таблицу
-- =====================================================================

-- 2.1: обычный индекс (по умолчанию B-tree) на salary
CREATE INDEX emp_salary_idx ON employees(salary);
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';
-- Ответ: 2 индекса: employees_pkey (создан автоматически для PRIMARY KEY) и emp_salary_idx

-- 2.2: индекс на внешний ключ
CREATE INDEX emp_dept_idx ON employees(dept_id);
SELECT * FROM employees WHERE dept_id = 101;
-- Ответ: индекс на FK ускоряет JOIN'ы и фильтры по внешнему ключу, а также проверки при
-- удалении/изменении строки в родительской таблице (PostgreSQL сам индекс на FK не создаёт).
-- На 5 строках планировщик всё равно выберет Seq Scan: таблица слишком мала.

-- 2.3: все индексы в базе
SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;
-- Ответ: автоматически созданы индексы под PRIMARY KEY: departments_pkey, employees_pkey, projects_pkey.
-- Остальные (emp_salary_idx, emp_dept_idx) мы создали вручную.

-- =====================================================================
-- PART 3: МНОГОКОЛОНОЧНЫЕ ИНДЕКСЫ
-- =====================================================================

-- 3.1: индекс на пару колонок (dept_id, salary)
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);
SELECT emp_name, salary FROM employees WHERE dept_id = 101 AND salary > 52000;
-- Ответ: для запроса только по salary индекс почти бесполезен: B-tree отсортирован сначала по
-- первой колонке (dept_id), поэтому без условия на неё эффективно искать по salary нельзя.

-- 3.2: индекс с обратным порядком колонок
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000; -- Query 1
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102; -- Query 2
-- Ответ: порядок колонок в индексе важен (индекс работает от первой колонки). Порядок условий в
-- WHERE неважен: планировщик сам их переставит, результат у Query 1 и Query 2 одинаковый.

-- =====================================================================
-- PART 4: УНИКАЛЬНЫЕ ИНДЕКСЫ
-- =====================================================================

-- 4.1: добавляем email и делаем его уникальным
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;
CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email); -- запрещает дубликаты email
-- Дубликат вызовет ошибку: duplicate key value violates unique constraint "emp_email_unique_idx".
-- Раскомментируй для скриншота (иначе скрипт остановится):
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email) VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- 4.2: UNIQUE constraint тоже создаёт индекс
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- Ответ: да, автоматически создан уникальный B-tree индекс employees_phone_key

-- =====================================================================
-- PART 5: ИНДЕКСЫ И СОРТИРОВКА
-- =====================================================================

-- 5.1: индекс по убыванию зарплаты
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);
SELECT emp_name, salary FROM employees ORDER BY salary DESC;
-- Ответ: данные в индексе уже отсортированы в нужном порядке, поэтому БД читает их готовыми
-- и не тратит время на отдельную сортировку.

-- 5.2: индекс с указанием, где стоят NULL
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);
SELECT proj_name, budget FROM projects ORDER BY budget NULLS FIRST; -- NULL-значения будут первыми

-- =====================================================================
-- PART 6: ИНДЕКСЫ НА ВЫРАЖЕНИЯХ
-- =====================================================================

-- 6.1: индекс на LOWER(имя) для поиска без учёта регистра
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));
SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Ответ: без такого индекса PostgreSQL пришлось бы прогонять LOWER() для каждой строки и
-- сканировать всю таблицу (Seq Scan).

-- 6.2: индекс на год приёма на работу
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));
SELECT emp_name, hire_date FROM employees WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- =====================================================================
-- PART 7: УПРАВЛЕНИЕ ИНДЕКСАМИ
-- =====================================================================

-- 7.1: переименование индекса
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- 7.2: удаление ненужного индекса
DROP INDEX emp_salary_dept_idx;
-- Ответ: лишний индекс занимает место на диске и замедляет INSERT/UPDATE/DELETE, а пользы не даёт.

-- 7.3: перестройка индекса с нуля
REINDEX INDEX employees_salary_index;
-- Полезно после массовых вставок, при "раздутом" индексе и после больших изменений данных.

-- =====================================================================
-- PART 8: ПРАКТИКА
-- =====================================================================

-- 8.1: оптимизация частого запроса.
-- Частичный индекс хранит только строки с salary > 50000 (меньше размер, быстрее поиск).
-- Для JOIN уже есть emp_dept_idx, для ORDER BY есть emp_salary_desc_idx
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
SELECT e.emp_name, e.salary, d.dept_name FROM employees e
JOIN departments d ON e.dept_id = d.dept_id WHERE e.salary > 50000 ORDER BY e.salary DESC;

-- 8.2: частичный индекс только по дорогим проектам
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;
SELECT proj_name, budget FROM projects WHERE budget > 80000;
-- Ответ: индекс меньше по размеру, быстрее обновляется и точнее: хранит только нужное подмножество.

-- 8.3: проверка плана запроса
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Ответ: на 5 строках будет Seq Scan, т.к. читать всю крошечную таблицу дешевле, чем идти в индекс.
-- На больших таблицах планировщик выберет Index Scan. Для скриншота Index Scan можно временно
-- запретить Seq Scan:
SET enable_seqscan = off;
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
RESET enable_seqscan;

-- =====================================================================
-- PART 9: СРАВНЕНИЕ ТИПОВ ИНДЕКСОВ
-- =====================================================================

-- 9.1: HASH индекс (только для сравнения на равенство =)
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
SELECT * FROM departments WHERE dept_name = 'IT';
-- Ответ: HASH стоит брать, когда нужны только точные сравнения "=". Для диапазонов, сортировки
-- и в остальных случаях лучше B-tree (он универсален).

-- 9.2: B-tree и Hash на одной колонке
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);
SELECT * FROM projects WHERE proj_name = 'Website Redesign'; -- равенство: подойдут оба индекса
SELECT * FROM projects WHERE proj_name > 'Database';         -- диапазон: только B-tree

-- =====================================================================
-- PART 10: ОЧИСТКА И BEST PRACTICES
-- =====================================================================

-- 10.1: размеры всех индексов
SELECT schemaname, tablename, indexname, pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;
-- Ответ: на таких маленьких таблицах все индексы по 16-32 КБ (минимум структуры). Обычно крупнее
-- hash-индексы и индексы по текстовым колонкам; в твоём выводе смотри самое большое значение index_size.

-- 10.2: удаляем дублирующий индекс (для равенства достаточно B-tree)
DROP INDEX IF EXISTS proj_name_hash_idx;

-- 10.3: view с документацией по индексам с "salary" в названии
CREATE VIEW index_documentation AS
SELECT tablename, indexname, indexdef, 'Improves salary-based queries' AS purpose
FROM pg_indexes WHERE schemaname = 'public' AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;

-- =====================================================================
-- SUMMARY QUESTIONS (ответы)
-- =====================================================================
-- 1. По умолчанию создаётся B-tree.
-- 2. Создавать: колонки из частых WHERE; внешние ключи/колонки в JOIN; колонки в ORDER BY.
-- 3. Не создавать: на маленьких таблицах; на колонках, которые почти не используются в запросах
--    или часто массово обновляются (также на колонках с очень малым числом разных значений).
-- 4. При INSERT/UPDATE/DELETE индексы тоже обновляются, поэтому запись замедляется.
-- 5. Проверить использование индекса: EXPLAIN (или EXPLAIN ANALYZE) и смотреть Index Scan или Seq Scan.

-- =====================================================================
-- ADDITIONAL CHALLENGES
-- =====================================================================
-- 1. Поиск сотрудников по месяцу приёма
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));
-- 2. Составной уникальный индекс по dept_id и email
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);
-- 3. Сравнение скорости с индексом и без (смотри Execution Time в выводе)
SET enable_indexscan = off; SET enable_bitmapscan = off;
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000; -- без индекса (Seq Scan)
RESET enable_indexscan; RESET enable_bitmapscan;
SET enable_seqscan = off;
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000; -- с индексом
RESET enable_seqscan;
-- 4. Покрывающий индекс: INCLUDE добавляет колонки в индекс, и запрос читает всё только из него
CREATE INDEX emp_covering_idx ON employees(dept_id) INCLUDE (emp_name, salary);
EXPLAIN SELECT emp_name, salary FROM employees WHERE dept_id = 101;
