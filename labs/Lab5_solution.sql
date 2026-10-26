-- Lab 5: Cleaning and Transforming Data

-- Q1

SELECT
    film_id,
    title,
    rental_rate,
    CASE
        WHEN rental_rate < 1.00 THEN 'Budget'
        WHEN rental_rate >= 1.00 AND rental_rate < 3.00
            THEN 'Standard'
        WHEN rental_rate >= 3.00 THEN 'Premium'
        ELSE 'Unclassified'
    END AS price_tier
FROM film
ORDER BY rental_rate ASC;

-- Film counts by price tier:
-- Budget: 341 films
-- Standard: 323 films
-- Premium: 336 films
-- Total: 1000 films

-- Explanation for rental_rate = 0.99:
--
-- First WHEN condition:
-- Test: 0.99 < 1.00
-- Result: TRUE
-- Since 0.99 is less than 1.00, the film
-- qualifies for the Budget tier.
--
-- Second WHEN condition:
-- Test: 0.99 >= 1.00 AND 0.99 < 3.00
-- Result: FALSE
-- The first comparison (0.99 >= 1.00) is FALSE.
-- The second comparison (0.99 < 3.00) is TRUE.
-- Since both conditions must be TRUE for AND
-- to return TRUE, the overall result is FALSE.
--
-- Third WHEN condition:
-- Test: 0.99 >= 3.00
-- Result: FALSE
-- Since 0.99 is less than 3.00, this condition
-- is FALSE.
--
-- Final classification: Budget
--
-- A searched CASE expression evaluates WHEN
-- conditions in order and returns the THEN
-- value associated with the first TRUE condition.
--
-- Since 0.99 < 1.00 is TRUE, the query returns
-- 'Budget'. CASE stops at the first matching
-- condition, so the remaining WHEN conditions
-- do not need to be evaluated.
--
-- The second and third conditions are shown
-- above for explanation purposes.


-- Q2
SELECT COUNT(*) AS total_films,
       COUNT(CASE WHEN rating = 'G' THEN 1 END) AS g_rated,
       COUNT(CASE WHEN rating IN ('PG', 'PG-13') THEN 1 END) AS pg_and_pg13,
       AVG(CASE WHEN rating = 'R' THEN rental_rate END) AS r_rated_avg_rate
FROM film;
-- When the condition is false, CASE WHEN ... THEN 1 END yields NULL;
-- COUNT(expression) ignores NULL, counting only matching rows.
-- CASE WHEN ... THEN 1 ELSE 0 END yields 0 for nonmatches;
-- COUNT counts that non-NULL 0, incorrectly counting every row.
-- Check g_rated + pg_and_pg13 < total_films in the query result;
-- the remainder includes R and NC-17 (and any other/null ratings, if present).

-- Q3
-- Part A
SELECT customer_id, first_name, last_name,
       COALESCE(email, 'no email on file') AS contact
FROM customer;
-- NULL email count: 0

-- Part B
SELECT film_id, title, replacement_cost, rental_rate,
       replacement_cost / NULLIF(rental_rate, 0.00) AS cost_rate_ratio
FROM film;
-- 1. NULLIF(rental_rate, 0.00) yields NULL if rental_rate = 0.00.
-- 2. Dividing a numeric value by NULL yields NULL, avoiding division-by-zero error.

-- Q4
SELECT film_id, title, rental_duration,
       LEAST(rental_duration, 7) AS capped_duration,
       GREATEST(rental_duration, 3) AS floored_duration
FROM film
ORDER BY rental_duration ASC;
-- GREATEST(rental_duration, 3) selects the larger value within each film row,
-- imposing a floor of 3. MAX(rental_duration) aggregates across multiple rows
-- and returns the greatest rental duration in the selected group/table.

-- Q5
-- Part A
SELECT customer_id,
       INITCAP(TRIM(last_name)) || ', ' || INITCAP(TRIM(first_name)) AS display_name,
       LEFT(TRIM(first_name), 1) || '.' AS first_initial,
       CHAR_LENGTH(first_name || ' ' || last_name) AS name_length
FROM customer
ORDER BY display_name ASC;

-- Part B
SELECT film_id, title,
       rental_rate::text AS rate_text,
       CAST(rental_rate AS integer) AS rate_truncated
FROM film;
-- Prefer ANSI-standard CAST when writing portable SQL for multiple DBMSs;
-- :: is PostgreSQL-specific syntax.
-- PostgreSQL numeric-to-integer CAST rounds rather than truncates fractional
-- values.

-- Q6
-- Part A
SELECT DATE_TRUNC('month', payment_date) AS payment_month,
       COUNT(*) AS payment_count,
       SUM(amount) AS total_revenue
FROM payment
GROUP BY DATE_TRUNC('month', payment_date)
ORDER BY payment_month ASC;
-- Highest-revenue month: February

-- Part B
SELECT rental_id, rental_date, return_date,
       AGE(return_date, rental_date) AS rental_duration,
       EXTRACT(DOW FROM rental_date) AS rental_dow
FROM rental
WHERE return_date IS NOT NULL;

-- Day-of-week frequency:
SELECT EXTRACT(DOW FROM rental_date) AS rental_dow,
       COUNT(*) AS rental_count
FROM rental
WHERE return_date IS NOT NULL
GROUP BY EXTRACT(DOW FROM rental_date)
ORDER BY rental_count DESC, rental_dow ASC;
-- Most frequent DOW: 6
-- Filter incomplete rentals first so AGE is only calculated for rentals
-- with a recorded return_date; otherwise the duration would be NULL.

-- Q7

-- Error 1: COUNT(CASE ... WHEN amount <= 5.00 THEN 0 END)
-- COUNT includes every non-NULL 0, so payments <= 5.00 are wrongly counted
-- as high-value; omit ELSE / the second WHEN so nonmatches yield NULL.
-- Error 2: COALESCE('no date recorded', payment_date::text)
-- The literal is never NULL, so every row gets the fallback even with a date.
-- Put the actual date before the fallback.
-- Error 3: EXTRACT(MONTH FROM payment_date) groups by month number only.
-- Payments in e.g. May 2005 and May 2006 would be combined incorrectly.
-- Pagila's stated payment months (May-August 2005 and February 2006) have
-- no overlapping month numbers across years, so this bug is masked there.
-- A grouped query cannot select raw payment_date::text without aggregating it
-- or adding it to GROUP BY. MIN(payment_date) provides a representative
-- date label for each monthly group, retaining exactly one row per month.
SELECT DATE_TRUNC('month', payment_date) AS pay_month,
       COUNT(*) AS total_payments,
       COUNT(CASE WHEN amount > 5.00 THEN 1 END) AS high_value_count,
       COALESCE(MIN(payment_date)::text, 'no date recorded') AS safe_date
FROM payment
GROUP BY DATE_TRUNC('month', payment_date)
ORDER BY pay_month;

-- REF: VERIFICATION QUERIES
-- Q1: exact tier counts
SELECT CASE WHEN rental_rate < 1.00 THEN 'Budget'
            WHEN rental_rate < 3.00 THEN 'Standard'
            ELSE 'Premium' END AS price_tier,
       COUNT(*) AS film_count
FROM film
GROUP BY 1
ORDER BY 1;

-- Q3: exact number of missing emails
SELECT COUNT(*) AS null_email_count FROM customer WHERE email IS NULL;

-- Q6A: month with highest total revenue
SELECT DATE_TRUNC('month', payment_date) AS payment_month,
       SUM(amount) AS total_revenue
FROM payment
GROUP BY 1
ORDER BY total_revenue DESC NULLS LAST, payment_month
LIMIT 1;