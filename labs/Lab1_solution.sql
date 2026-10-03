-- ALY 6420 | Lab 1 Student Solution

-- Q1
-- Row count: 200
SELECT title, rental_rate, replacement_cost
FROM film
WHERE replacement_cost > 20.00
ORDER BY replacement_cost DESC, title ASC;

-- Q2A
-- Version A row count: 162
SELECT title, rating
FROM film
WHERE (rating = 'G' OR rating = 'PG-13') AND rental_duration >= 6;

-- Q2B
-- Version B row count: 200
-- Counts differ because AND has higher precedence than OR. Without the outer
-- parentheses, all G films qualify, while only PG-13 films must satisfy rental_duration >= 6.
SELECT title, rating
FROM film
WHERE rating = 'G' OR rating = 'PG-13' AND rental_duration >= 6;

-- Q3A
SELECT title, length, rental_rate
FROM film
WHERE length BETWEEN 75 AND 105;

-- Q3B
SELECT title, rating
FROM film
WHERE rating IN ('G', 'PG', 'PG-13');

-- Q4A
SELECT title
FROM film
WHERE title LIKE 'AGENT%';

-- Q4B
SELECT first_name, last_name
FROM actor
WHERE first_name LIKE '____';

-- Q4C
SELECT title
FROM film
WHERE title LIKE '%IRON%';

-- Q5A
SELECT rental_id, customer_id
FROM rental
WHERE return_date IS NULL;

-- Q5B
SELECT COUNT(*)
FROM rental
WHERE return_date IS NOT NULL;

-- Q6
SELECT customer_id,
       amount AS payment_amount,
       amount * 1.10 AS amount_with_surcharge
FROM payment
ORDER BY amount_with_surcharge DESC
LIMIT 15;

-- Q7A
-- Distinct ratings: 5
SELECT rating
FROM (
    SELECT DISTINCT rating
    FROM film
) AS distinct_ratings
ORDER BY rating::text;


-- Q7B
SELECT address,
       address2,
       COALESCE(address2, 'No unit') AS unit
FROM address;

-- Q8
-- Error: COUNT(*) is an aggregate function but is used in WHERE.
-- WHERE is evaluated before GROUP BY and before aggregate results are calculated.
-- HAVING is evaluated after grouping, so it is the correct clause for filtering COUNT(*).
SELECT customer_id,
       COUNT(*) AS rental_count
FROM rental
GROUP BY customer_id
HAVING COUNT(*) > 15
ORDER BY rental_count DESC;











