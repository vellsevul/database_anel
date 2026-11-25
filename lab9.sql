-- ============================================================
-- Lab 9: Stored Procedures and User-Defined Functions (Parts 2-7)
-- Run lab9_setup.sql first (Part 1), then this file.
-- ============================================================

-- ---------- Verify the setup (Part 1) ----------
SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes)    AS bikes,
       (SELECT COUNT(*) FROM members)  AS members,
       (SELECT COUNT(*) FROM rentals)  AS rentals;

-- ============================================================
-- PART 2: Your first function
-- ============================================================

-- Worked example
CREATE OR REPLACE FUNCTION inc(val INTEGER) RETURNS INTEGER AS $$
DECLARE
    result INTEGER;
BEGIN
    result := val + 1;
    RETURN result;
END; $$ LANGUAGE plpgsql;
SELECT inc(10);

-- Exercise 2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date INTO v_days
      FROM rentals WHERE rental_id = p_rental_id;
    RETURN v_days;
END; $$ LANGUAGE plpgsql;
SELECT rental_days(2);
SELECT rental_days(11);
SELECT rental_days(19) AS open_rental, rental_days(999) AS missing_rental;
-- Answer: 19 -> NULL because end_date is NULL; 999 -> NULL because no row matches
-- (SELECT INTO leaves the variable NULL). Different reasons.

-- Exercise 2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    v_cnt INT;
BEGIN
    SELECT COUNT(*) INTO v_cnt FROM rentals WHERE member_id = p_member_id;
    RETURN v_cnt;
END; $$ LANGUAGE plpgsql;
SELECT member_rental_count(1), member_rental_count(5), member_rental_count(6), member_rental_count(99);
-- Answer: an aggregate without GROUP BY always returns one row; COUNT(*) over zero rows is 0
-- (SUM/MAX would give NULL). Member 99 looks the same as member 6: zero matching rows.

-- Exercise 2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city INTO v_city FROM stations WHERE station_id = p_station_id;
    RETURN v_city;
END; $$ LANGUAGE plpgsql;
SELECT station_city(30), station_city(77);

-- Exercise 2.4
SELECT rental_id, member_id, rental_days(rental_id) AS days
  FROM rentals
 WHERE rental_days(rental_id) > 4
 ORDER BY days DESC;

-- ============================================================
-- PART 3: Parameter modes
-- ============================================================

-- Exercise 3.1 (IN)
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100), 2);
END; $$ LANGUAGE plpgsql;
SELECT fee_with_discount(74.00, 15);   -- 62.90

-- Exercise 3.2 (OUT)
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id    INT,
    OUT rental_cnt INT,
    OUT total_fee  NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0), MAX(start_date)
      INTO rental_cnt, total_fee, last_start
      FROM rentals
     WHERE member_id = p_member_id;
END; $$ LANGUAGE plpgsql;
SELECT member_stats(3);          -- one composite column: (5,164.75,2025-06-01)
SELECT * FROM member_stats(3);   -- three separate columns
SELECT * FROM member_stats(6);   -- 0 | 0 | NULL
-- Answer: the FROM form is used inside larger queries (columns can be filtered/joined).

-- Exercise 3.3 (INOUT)
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN
    p_fee := p_fee + 5.00;
END; $$ LANGUAGE plpgsql;
SELECT apply_late_fee(fee) AS fee_with_late_charge FROM rentals WHERE rental_id = 1;   -- 18.50
-- Answer: OUT/INOUT parameters define the result; their final values are returned automatically.

-- Exercise 3.4 (VARIADIC)
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total   NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(x), ROUND(AVG(x), 2), MAX(x)
      INTO total, average, largest
      FROM unnest(p_fees) AS x;
END; $$ LANGUAGE plpgsql;
SELECT * FROM fee_summary(13.50, 35.00, 18.50, 74.00);
SELECT * FROM fee_summary(VARIADIC ARRAY[4.5, 7.0]);

-- ============================================================
-- PART 4: Default values and overloading
-- ============================================================

-- (re-run safety)
DROP FUNCTION IF EXISTS total_fees(INT);
DROP FUNCTION IF EXISTS total_fees(INT, DATE);
DROP FUNCTION IF EXISTS total_fees(VARCHAR);

-- Exercise 4.1
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((SELECT SUM(fee) FROM rentals WHERE member_id = p_member_id), 0);
END; $$ LANGUAGE plpgsql;
SELECT total_fees(1), total_fees(6);

-- Exercise 4.2
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((SELECT SUM(fee) FROM rentals
                      WHERE member_id = p_member_id AND start_date >= p_from_date), 0);
END; $$ LANGUAGE plpgsql;
SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');
SELECT proname, pg_get_function_identity_arguments(oid) AS signature
  FROM pg_proc WHERE proname = 'total_fees' ORDER BY 2;

-- Exercise 4.3
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT,
                                      p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((SELECT SUM(fee) FROM rentals
                      WHERE member_id = p_member_id AND start_date >= p_from_date), 0);
END; $$ LANGUAGE plpgsql;
-- SELECT total_fees(1);   -- fails, caught below so the script keeps running
DO $$
DECLARE
    v_hint TEXT;
BEGIN
    PERFORM total_fees(1);
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_hint = PG_EXCEPTION_HINT;
    RAISE NOTICE 'ERROR: %', SQLERRM;
    RAISE NOTICE 'HINT:  %', v_hint;
END $$;
-- Exact error (psql):
--   ERROR:  function total_fees(integer) is not unique
--   LINE 1: SELECT total_fees(1);
--   HINT:  Could not choose a best candidate function. You might need to add explicit type casts.
-- Answer: total_fees(INT) and total_fees(INT, DATE DEFAULT ...) both match total_fees(1)
-- equally well, and no rule prefers one, so PostgreSQL refuses to guess.

-- Exercise 4.4
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);   -- 50.00
-- Answer: the (INT, DATE DEFAULT '2025-01-01') version answers: 18.50 + 31.50 = 50.00.
-- Dropping the other version instead would leave total_fees(INT) and return 98.50. Not the same.

-- Exercise 4.5
CREATE OR REPLACE FUNCTION total_fees(p_name VARCHAR) RETURNS NUMERIC AS $$
BEGIN
    RETURN COALESCE((SELECT SUM(r.fee) FROM rentals r
                       JOIN members m ON m.member_id = r.member_id
                      WHERE m.full_name = p_name), 0);
END; $$ LANGUAGE plpgsql;
SELECT total_fees('Aisha Nurlanova');   -- 98.50
SELECT total_fees(1);                   -- 50.00
-- Answer: the argument TYPES differ (string literal -> VARCHAR version, integer -> INT version),
-- so no call matches two candidates. The name call returns the all-time total (98.50); the id call
-- uses the DEFAULT date 2025-01-01, so only 2025+ fees (50.00).

-- ============================================================
-- PART 5: Functions that return a table
-- ============================================================

-- Exercise 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model, b.daily_rate
      FROM bikes b
     WHERE b.model ILIKE p_pattern
     ORDER BY b.bike_id;
END; $$ LANGUAGE plpgsql;
SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');   -- one column with composite values like (105,"Road Sprint",9.25)

-- Exercise 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (h_rental_id INT, h_model VARCHAR, h_station VARCHAR, h_days INT, h_fee NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id, b.model, s.station_name, r.end_date - r.start_date, r.fee
      FROM rentals r
      JOIN bikes b ON b.bike_id = r.bike_id
      LEFT JOIN stations s ON s.station_id = b.station_id
     WHERE r.member_id = p_member_id
     ORDER BY r.start_date;
END; $$ LANGUAGE plpgsql;
SELECT * FROM member_history(3);

-- Exercise 5.3 (broken version: CREATE succeeds, the call fails)
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;
-- SELECT * FROM bike_list(10);   -- fails
DO $$
BEGIN
    PERFORM * FROM bike_list(10);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR: %', SQLERRM;
END $$;
-- Exact error:
--   ERROR:  column reference "bike_id" is ambiguous
--   DETAIL:  It could refer to either a PL/pgSQL variable or a table column.
-- Answer: CREATE only checks PL/pgSQL syntax; the SQL inside is analysed at first call, when the
-- output columns exist as variables clashing with the table columns.

-- Fix 1: rename the output columns
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END; $$ LANGUAGE plpgsql;
SELECT * FROM bike_list(10);

-- Fix 2: keep names, qualify table columns with an alias
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT b.bike_id, b.model FROM bikes b WHERE b.station_id = p_station_id;
END; $$ LANGUAGE plpgsql;
SELECT * FROM bike_list(10);

-- Exercise 5.4 (without the cast: error at call time)
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name, COUNT(b.bike_id), s.capacity - COUNT(b.bike_id)
      FROM stations s LEFT JOIN bikes b ON b.station_id = s.station_id
     WHERE s.city = p_city
     GROUP BY s.station_id, s.station_name, s.capacity
     ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;
-- SELECT * FROM station_board('Almaty');   -- fails
DO $$
BEGIN
    PERFORM * FROM station_board('Almaty');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR: %', SQLERRM;
END $$;
-- Exact error:
--   ERROR:  structure of query does not match function result type
--   DETAIL:  Returned type bigint does not match expected type integer in column 2.

-- Fixed version (explicit casts)
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name, COUNT(b.bike_id)::INT, (s.capacity - COUNT(b.bike_id))::INT
      FROM stations s LEFT JOIN bikes b ON b.station_id = s.station_id
     WHERE s.city = p_city
     GROUP BY s.station_id, s.station_name, s.capacity
     ORDER BY s.station_id;
END; $$ LANGUAGE plpgsql;
SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');

-- ============================================================
-- PART 6: Blocks, DO blocks, subblocks
-- ============================================================

-- Exercise 6.1
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;
-- Mismatched label: DO $$ <<a>> BEGIN NULL; END b $$;
--   ERROR:  end label "b" differs from block's label "a"

-- Exercise 6.2
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
    fee_total NUMERIC;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
    SELECT SUM(fee) INTO fee_total FROM rentals;
    RAISE NOTICE '1) outer fee_total before subblock: %', fee_total;

    <<inner_block>>
    DECLARE
        fee_total NUMERIC;
    BEGIN
        SELECT SUM(fee) INTO fee_total FROM rentals WHERE start_date >= DATE '2025-01-01';
        RAISE NOTICE '2) subblock fee_total (own):       %', fee_total;
        RAISE NOTICE '3) outer fee_total via label:      %', rental_report.fee_total;
    END inner_block;

    RAISE NOTICE '4) outer fee_total after subblock:  %', fee_total;
END rental_report $$;
-- Printed: 621.50 / 369.00 / 621.50 / 621.50. The subblock's assignment did NOT change the outer
-- variable: it declares a new variable that hides the outer one; a declaration lives only to its END.

-- Exercise 6.3 (a): second subblock reads a variable of the first -> error
DO $$
BEGIN
    BEGIN
        <<first_sub>>
        DECLARE
            hidden_val INT := 42;
        BEGIN
            RAISE NOTICE 'first subblock sees hidden_val = %', hidden_val;
        END first_sub;

        <<second_sub>>
        BEGIN
            RAISE NOTICE 'second subblock sees hidden_val = %', hidden_val;
        END second_sub;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: %', SQLERRM;   -- column "hidden_val" does not exist
    END;
END $$;

-- Exercise 6.3 (b): declaration moved to the outer block -> both subblocks see it
DO $$
DECLARE
    shared_val INT := 42;
BEGIN
    BEGIN
        RAISE NOTICE 'first subblock sees shared_val = %', shared_val;
    END;
    BEGIN
        RAISE NOTICE 'second subblock sees shared_val = %', shared_val;
    END;
END $$;

-- Exercise 6.4
CREATE OR REPLACE FUNCTION fee_split(p_from_date DATE,
                                     OUT before_total NUMERIC,
                                     OUT after_total  NUMERIC) AS $$
BEGIN
    SELECT COALESCE(SUM(fee) FILTER (WHERE start_date <  p_from_date), 0),
           COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
      INTO before_total, after_total
      FROM rentals;
END; $$ LANGUAGE plpgsql;
SELECT * FROM fee_split(DATE '2025-01-01');   -- 252.50 | 369.00
SELECT before_total + after_total AS sum_of_parts, (SELECT SUM(fee) FROM rentals) AS whole_table
  FROM fee_split(DATE '2025-01-01');          -- 621.50 = 621.50

-- ============================================================
-- PART 7: Practical scenarios
-- ============================================================

-- Exercise 7.1 (capacity = 0 -> NULL: the percentage is undefined; 0 % would be misleading)
CREATE OR REPLACE FUNCTION station_load(p_station_id INT,
                                        OUT bikes_parked INT,
                                        OUT capacity_pct NUMERIC) AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT COUNT(*)::INT INTO bikes_parked FROM bikes WHERE station_id = p_station_id;
    SELECT capacity INTO v_capacity FROM stations WHERE station_id = p_station_id;
    capacity_pct := ROUND(100.0 * bikes_parked / NULLIF(v_capacity, 0), 1);
END; $$ LANGUAGE plpgsql;
SELECT s.station_id, s.station_name, l.*
  FROM stations s, LATERAL station_load(s.station_id) l
 ORDER BY s.station_id;

-- Exercise 7.2
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (t_name VARCHAR, t_rentals INT, t_spent NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name, COUNT(r.rental_id)::INT, COALESCE(SUM(r.fee), 0)
      FROM members m LEFT JOIN rentals r ON r.member_id = m.member_id
     GROUP BY m.member_id, m.full_name
     ORDER BY COALESCE(SUM(r.fee), 0) DESC, m.member_id
     LIMIT p_limit;
END; $$ LANGUAGE plpgsql;
SELECT * FROM top_members();
SELECT * FROM top_members(6);
-- Answer: Aisha Nurlanova has 5 rentals but only 98.50 spent, so she ranks below Chen Wei and
-- Daniyar Serik (4 rentals each). Ranking is by money, not by count; one of her rentals is open
-- with a NULL fee. Not a bug.

-- Exercise 7.3
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (i_member VARCHAR, i_model VARCHAR, i_days INT, i_amount NUMERIC, i_status VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           b.model,
           COALESCE(r.end_date, CURRENT_DATE) - r.start_date,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2),
           (CASE WHEN r.end_date IS NULL THEN 'OPEN' ELSE 'CLOSED' END)::VARCHAR
      FROM rentals r
      JOIN members m ON m.member_id = r.member_id
      JOIN bikes   b ON b.bike_id   = r.bike_id
     WHERE r.rental_id = p_rental_id;
END; $$ LANGUAGE plpgsql STABLE;
SELECT * FROM rental_invoice(11);   -- 8 days x 9.25 = 74.00 = stored fee: yes
SELECT * FROM rental_invoice(19);
SELECT fee AS stored_fee_rental_11 FROM rentals WHERE rental_id = 11;
-- Answer: rental 19 is open, so days = CURRENT_DATE - start_date grows every day. A function that
-- reads CURRENT_DATE cannot be IMMUTABLE; STABLE is correct (constant within one statement).

-- Exercise 7.4
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT, COUNT(r.rental_id)::INT, COALESCE(SUM(r.fee), 0)
      FROM members m LEFT JOIN rentals r ON r.member_id = m.member_id
     WHERE m.city = p_city;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (c_members INT, c_rentals INT, c_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT, COUNT(r.rental_id)::INT, COALESCE(SUM(r.fee), 0)
      FROM members m
      LEFT JOIN rentals r ON r.member_id = m.member_id
                         AND r.start_date >= p_from_date   -- in ON: members without rentals are kept
     WHERE m.city = p_city;
END; $$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');                       -- 3 members, 9 rentals, 236.50
SELECT * FROM city_report('Almaty', DATE '2025-01-01');    -- 3 members, 5 rentals, 135.50

-- Same condition in WHERE: members without matching rentals disappear (LEFT JOIN becomes inner)
SELECT COUNT(DISTINCT m.member_id) AS members_with_date_in_where   -- 2 instead of 3
  FROM members m LEFT JOIN rentals r ON r.member_id = m.member_id
 WHERE m.city = 'Almaty' AND r.start_date >= DATE '2025-01-01';
