-- Lab 4: Subqueries, CTEs, and Set Operations

-- Q1
-- Average film length: 115.272
SELECT title, length, rating
FROM film
WHERE length > (SELECT AVG(length) FROM film)
ORDER BY length DESC;

-- Q2
SELECT AVG(total_spent) AS avg_customer_spend
FROM (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
) AS customer_totals;

-- Q3
/*
The JOIN version is easier to read for this question because the relationship
from films through inventory to rental events is explicit. I would prefer the
JOIN version when I need to select additional columns from inventory or rental,
or when reviewing the relationships among those tables.

JOIN result row count: 63
Subquery result row count: 63
Both counts should agree. Each rental must be retained, including repeat rentals
of the same title. An IN filter on film alone would lose rental dates.
*/
-- Subquery form: correlate each rental event to its film using IN.
SELECT f.title, r.rental_date
FROM film AS f
CROSS JOIN rental AS r
WHERE r.customer_id = 130
  AND f.film_id IN (
      SELECT i.film_id
      FROM inventory AS i
      WHERE i.inventory_id = r.inventory_id
  )
ORDER BY r.rental_date ASC;

-- Q3 validation: JOIN version (run to compare results)
-- SELECT f.title, r.rental_date
-- FROM film AS f
-- JOIN inventory AS i ON i.film_id = f.film_id
-- JOIN rental AS r ON r.inventory_id = i.inventory_id
-- JOIN customer AS c ON c.customer_id = r.customer_id
-- WHERE c.customer_id = 130
-- ORDER BY r.rental_date ASC;

-- Q4
WITH film_rental_counts AS (
    SELECT i.film_id, COUNT(r.rental_id) AS rental_count
    FROM inventory AS i
    JOIN rental AS r ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
)
SELECT f.title, frc.rental_count
FROM film AS f
JOIN film_rental_counts AS frc ON frc.film_id = f.film_id
WHERE frc.rental_count > 30
ORDER BY frc.rental_count DESC;

-- Q5
WITH customer_totals AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
),
avg_spend AS (
    SELECT AVG(total_spent) AS avg_spend
    FROM customer_totals
)
SELECT ct.customer_id, ct.total_spent, a.avg_spend
FROM customer_totals AS ct
CROSS JOIN avg_spend AS a
WHERE ct.total_spent > a.avg_spend
ORDER BY ct.total_spent DESC;

-- Q6
/*
Query A: UNION ALL
Total rows: 1,199
This combines actor and customer names vertically and retains every source
row, including repeated full names.
*/
SELECT first_name, last_name FROM actor
UNION ALL
SELECT first_name, last_name FROM customer;

/*
Query B: INTERSECT
Shared full-name pairs: 1 (JENNIFER DAVIS)
A zero-row result means no identical (first_name, last_name) pair appears in
both tables; it does not prove no actor is also a customer.
*/
SELECT first_name, last_name FROM actor
INTERSECT
SELECT first_name, last_name FROM customer;

/*
Query C: EXCEPT
This identifies distinct actor (first_name, last_name) pairs not present
in the customer table. Matching names alone do not establish identity.
*/
SELECT first_name, last_name FROM actor
EXCEPT
SELECT first_name, last_name FROM customer
ORDER BY last_name ASC;

-- Q7
/*
The error is AVG(total_spent) inside the WHERE clause of above_average.
The WHERE clause filters rows before aggregation at the same query level, so
an aggregate function cannot be evaluated directly there. Calculating the
average in its own CTE makes it available as a scalar column for filtering.
*/
WITH spending AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
),
avg_spending AS (
    SELECT AVG(total_spent) AS avg_spent
    FROM spending
),
above_average AS (
    SELECT s.customer_id, s.total_spent
    FROM spending AS s
    CROSS JOIN avg_spending AS a
    WHERE s.total_spent > a.avg_spent
)
SELECT c.first_name, c.last_name, aa.total_spent
FROM customer AS c
JOIN above_average AS aa ON aa.customer_id = c.customer_id
ORDER BY aa.total_spent DESC;
