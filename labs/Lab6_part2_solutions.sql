-- Lab 6: solution set Part 2

-- T1A: One row per customer with payments
SELECT c.customer_id, c.first_name, c.last_name,
       SUM(p.amount) AS total_paid
FROM customer AS c
JOIN payment AS p ON p.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY c.customer_id;

-- T1B: Preserve individual payment rows
SELECT p.customer_id, p.payment_date, p.amount,
       SUM(p.amount) OVER (PARTITION BY p.customer_id) AS total_paid
FROM payment AS p
ORDER BY p.customer_id, p.payment_date, p.payment_id;

-- T1 Reflection:
-- Query A collapses payments into one row per paying customer, whereas Query B
-- retains each payment and repeats the customer's lifetime total on each row.
-- A answers which customer paid the most overall; B answers which individual
-- payment dates and amounts contributed to a customer's lifetime total.

-- T2: All customers, ranked by lifetime payments within their store
WITH customer_totals AS (
    SELECT c.customer_id, c.first_name, c.last_name, c.store_id,
           COALESCE(SUM(p.amount), 0) AS total_paid
    FROM customer AS c
    LEFT JOIN payment AS p ON p.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.store_id
),
ranked_customers AS (
    SELECT customer_id, first_name, last_name, store_id, total_paid,
           ROW_NUMBER() OVER (
               PARTITION BY store_id
               ORDER BY total_paid DESC, customer_id
           ) AS store_rank
    FROM customer_totals
)
SELECT first_name, last_name, store_id, total_paid, store_rank
FROM ranked_customers
ORDER BY store_id, store_rank;

-- T3: Compare ranking functions on identical totals
WITH customer_totals AS (
    SELECT c.customer_id, c.first_name, c.last_name, c.store_id,
           COALESCE(SUM(p.amount), 0) AS total_paid
    FROM customer AS c
    LEFT JOIN payment AS p ON p.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.store_id
)
SELECT first_name, last_name, store_id, total_paid,
       ROW_NUMBER() OVER (
           PARTITION BY store_id ORDER BY total_paid DESC, customer_id
       ) AS row_number_rank,
       RANK() OVER (
           PARTITION BY store_id ORDER BY total_paid DESC
       ) AS rank_rank,
       DENSE_RANK() OVER (
           PARTITION BY store_id ORDER BY total_paid DESC
       ) AS dense_rank_rank
FROM customer_totals
ORDER BY store_id, total_paid DESC, customer_id;

-- T3 Reflection:
-- ROW_NUMBER() is the appropriate choice when each leaderboard position must
-- belong to exactly one customer; customer_id provides a reproducible tiebreaker.
-- RANK() assigns the same position to tied totals and skips subsequent positions,
-- whereas DENSE_RANK() also shares positions but does not leave gaps.
-- Note that ROW_NUMBER() resolves display/prize positions, not genuine equal performance.

-- T4: Running total for customer 1, with explicit ROWS frame
SELECT p.customer_id, p.payment_date, p.amount,
       SUM(p.amount) OVER (
           PARTITION BY p.customer_id
           ORDER BY p.payment_date, p.payment_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM payment AS p
WHERE p.customer_id = 1
ORDER BY p.payment_date, p.payment_id;

-- T4 Validation: first payment at which running total reaches $25
-- Customer 1’s cumulative payment total first reaches $25.00 after 6 payments, on 2022-02-24 at 13:41:18.230 (-08:00), with a running total of $27.94.
WITH running AS (
    SELECT p.customer_id, p.payment_id, p.payment_date, p.amount,
           ROW_NUMBER() OVER (
               PARTITION BY p.customer_id
               ORDER BY p.payment_date, p.payment_id
           ) AS payment_number,
           SUM(p.amount) OVER (
               PARTITION BY p.customer_id
               ORDER BY p.payment_date, p.payment_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS running_total
    FROM payment AS p
    WHERE p.customer_id = 1
)
SELECT payment_number, payment_date, running_total
FROM running
WHERE running_total >= 25.00
ORDER BY payment_number
LIMIT 1;

-- AI CRITIQUE: Error 1: WHERE store_rank <= 5 follows GROUP BY, which is
-- syntactically invalid (WHERE must precede GROUP BY). Moreover, WHERE cannot
-- reference a SELECT-list window-function alias: WHERE is evaluated before
-- window functions. Filter a derived ranking in an outer SELECT instead.
-- Error 2: ROW_NUMBER() OVER (ORDER BY COUNT(r.rental_id) DESC) has no
-- PARTITION BY c.store_id, so it ranks all customers globally, not per store.

-- AI CRITIQUE: Corrected top five customers in each store
WITH rental_counts AS (
    SELECT c.customer_id, c.first_name, c.last_name, c.store_id,
           COUNT(r.rental_id) AS rental_count
    FROM customer AS c
    LEFT JOIN rental AS r ON r.customer_id = c.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.store_id
),
ranked_rentals AS (
    SELECT customer_id, first_name, last_name, store_id, rental_count,
           ROW_NUMBER() OVER (
               PARTITION BY store_id
               ORDER BY rental_count DESC, customer_id
           ) AS store_rank
    FROM rental_counts
)
SELECT first_name, last_name, store_id, rental_count, store_rank
FROM ranked_rentals
WHERE store_rank <= 5
ORDER BY store_id, store_rank;

-- AI CRITIQUE Validation: expected 10 rows if both stores have >= 5 customers.
WITH rental_counts AS (
    SELECT c.customer_id, c.store_id, COUNT(r.rental_id) AS rental_count
    FROM customer c LEFT JOIN rental r ON r.customer_id = c.customer_id
    GROUP BY c.customer_id, c.store_id
), ranked AS (
    SELECT store_id,
           ROW_NUMBER() OVER (PARTITION BY store_id
                              ORDER BY rental_count DESC, customer_id) AS rn
    FROM rental_counts
)
SELECT store_id, COUNT(*) AS top_five_rows
FROM ranked WHERE rn <= 5
GROUP BY store_id ORDER BY store_id;

-- References:
-- Shan et al. (2025), SQL for Data Analytics, 4th ed., chapters 8 and 9.
-- https://www.postgresql.org/docs/current/tutorial-window.html
