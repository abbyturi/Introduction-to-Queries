-- Lab 6, Part I: Aggregate Functions 

-- T1.1: Five aggregate functions on payment
SELECT
    COUNT(*) AS total_payments,
    SUM(amount) AS total_revenue,
    ROUND(AVG(amount), 2) AS average_payment,
    MIN(amount) AS minimum_payment,
    MAX(amount) AS maximum_payment
FROM payment;

-- T1.2: Rental count variants
SELECT
    COUNT(*) AS total_rentals,
    COUNT(return_date) AS returned_rentals,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM rental;
-- total_rentals counts all rental transactions, including those without a return date.
-- returned_rentals counts rentals with a non-NULL return date.
-- unique_customers counts distinct customers with at least one rental.

-- T2.1: Customers with total payments exceeding $150
SELECT
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_paid,
    COUNT(p.payment_id) AS number_of_payments
FROM payment p
JOIN customer c ON p.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(p.amount) > 150
ORDER BY total_paid DESC;

-- T2.2a: Count customers whose payments exceed $150
SELECT COUNT(*) AS qualifying_customers
FROM (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    HAVING SUM(amount) > 150
) AS customer_totals;

-- T2.2b: Count all customers
SELECT COUNT(*) AS total_customers
FROM customer;

-- T2.3: HAVING versus WHERE
-- HAVING filters grouped customer totals, while WHERE filters individual rows before aggregation.
-- In SQL's logical execution order, WHERE precedes GROUP BY and HAVING follows grouping.

-- T3.1: Revenue and payment count by customer's assigned store
SELECT
    c.store_id,
    SUM(p.amount) AS total_revenue,
    COUNT(p.payment_id) AS number_of_payments
FROM payment p
JOIN customer c ON p.customer_id = c.customer_id
GROUP BY c.store_id
ORDER BY total_revenue DESC;

-- T3.2a: Count customer rows
SELECT COUNT(*) AS customer_rows
FROM customer;

-- T3.2b: Count rows after joining customer to payment
SELECT COUNT(*) AS joined_rows
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id;
-- The join has more rows because each customer can match multiple payment records.

-- T3.3: JOIN direction and aggregation
-- Joining customer to payment repeats customer attributes for each matching payment.
-- However, reversing the order of these INNER JOIN tables does not change SUM(p.amount):
-- without GROUP BY, SUM(p.amount) is a valid overall total, not a per-store total.
-- Incorrect inflation occurs if other joins multiply payment rows.

-- T4.1: COUNT variants on rental
SELECT
    COUNT(*) AS all_rentals,
    COUNT(return_date) AS returned,
    COUNT(*) - COUNT(return_date) AS still_out
FROM rental;
-- COUNT(*) counts all rows; COUNT(return_date) skips rows where return_date is NULL.

-- T4.2a: Compare two averages
SELECT
    AVG(amount) AS avg_ignores_null,
    SUM(amount) / COUNT(*) AS avg_includes_null_denom
FROM payment;

-- T4.2b: Profile NULL payment amounts
SELECT
    COUNT(*) AS total_payments,
    COUNT(amount) AS non_null_amounts,
    COUNT(*) - COUNT(amount) AS null_amounts
FROM payment;
-- In production, prefer AVG(amount) when measuring known payment amounts because
-- it excludes NULLs from the denominator; separately monitor missing amounts.

-- T5.1: Critique error 1
-- f.title appears in SELECT but is neither grouped nor aggregated, so PostgreSQL rejects it.

-- T5.2: Critique error 2
-- AVG(f.rental_duration) cannot appear in WHERE because WHERE runs before aggregation;
-- aggregate conditions belong in HAVING.

-- T5.3: Corrected query 
SELECT
    f.rating,
    COUNT(r.rental_id) AS rental_count,
    AVG(f.rental_duration) AS avg_duration
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.rating
HAVING AVG(f.rental_duration) > 5
ORDER BY avg_duration DESC;
-- Note: This average is weighted by rental frequency, not one observation per film.

