/*
ALY6420 | Introduction to Querying
Mid-course SQL project - solution set
Database: Pagila / PostgreSQL (Neon, DBeaver)
*/

-- Q1. Which 10 customers generated the most rental revenue, and how many rentals did each complete?
/* Note:
   Business objective: Identify high-value customers using actual payments.
   Concept review: One row per customer. SUM measures revenue; COUNT measures rental events.
   Aggregate each fact table before joining to avoid multiplying rows. ORDER BY precedes LIMIT
   in result shaping.
   Reference reading: Ch. 5 pp. 87–88; Ch. 7 pp. 129–138; Ch. 8 pp. 146–157. Course topics:
   joins, grain, aggregation.
   Check one
   customer against separate payment and rental totals. Completed means returned: return_date IS NOT NULL. Revenue includes all recorded
   rental-linked payments, independently of return status.
   
*/
WITH customer_payments AS (
    SELECT customer_id, SUM(amount) AS total_revenue
    FROM payment
    WHERE rental_id IS NOT NULL
    GROUP BY customer_id
), customer_rentals AS (
    SELECT customer_id, COUNT(*) AS rental_count
    FROM rental
    WHERE return_date IS NOT NULL
    GROUP BY customer_id
)
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name,
       p.total_revenue, COALESCE(r.rental_count, 0) AS rental_count
FROM customer c
JOIN customer_payments p ON p.customer_id = c.customer_id
LEFT JOIN customer_rentals r ON r.customer_id = c.customer_id
ORDER BY p.total_revenue DESC, c.customer_id
LIMIT 10;

/* The top 10 customers by rental revenue and completed rentals are:
   1. Karl Seal        - $358.12 (89 rentals)
   2. Tim Cary         - $344.06 (94 rentals)
   3. Russell Brinson  - $324.04 (97 rentals)
   4. Harry Arce       - $323.17 (83 rentals)
   5. Daisy Bates      - $322.12 (88 rentals)
   6. Laura Rodriguez  - $320.17 (82 rentals)
   7. Max Pitt         - $320.11 (90 rentals)
   8. Curtis Irby      - $317.10 (90 rentals)
   9. Sylvia Ortiz     - $315.12 (88 rentals)
  10. Wesley Bull      - $311.18 (82 rentals)

   Karl Seal generated the most revenue, while Russell Brinson
   completed the most rentals among the top 10 customers.
   Based on the displayed query results.
*/

/* Design decision: Revenue is measured using actual payments and rental count
   means returned rental transactions, identified by a non-NULL return_date. I aggregate
   payments and rentals separately at customer grain rather than joining raw rows,
   because multiple payments or rentals could otherwise inflate the totals.
   The customer ID breaks revenue ties deterministically. */

-- Q2. What percentage of films in each rating category have never been rented?
/* Note:
   Business objective: Identify underused titles by content rating.
   Concept review: One row per rating; the denominator is all films in that rating, not
   inventory copies. DISTINCT establishes one row per rented film; LEFT JOIN preserves unmatched
   films; CASE converts missing matches into a count.
   Reference reading: Ch. 6 pp. 108–111; Ch. 7 pp. 126–136; Ch. 8 pp. 146–157. Course topics:
   derived datasets, NULL handling, outer joins.
   Percentages must be between 0 and 100. Sum total_films across
   ratings and compare with COUNT(*) FROM film. Do not filter unmatched rows out before
   computing the denominator.
*/
WITH rented_films AS (
    SELECT DISTINCT i.film_id
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
)
SELECT f.rating, COUNT(*) AS total_films,
       SUM(CASE WHEN rf.film_id IS NULL THEN 1 ELSE 0 END) AS never_rented_films,
       ROUND(100.0 * SUM(CASE WHEN rf.film_id IS NULL THEN 1 ELSE 0 END)
             / NULLIF(COUNT(*), 0), 2) AS never_rented_pct
FROM film f
LEFT JOIN rented_films rf ON rf.film_id = f.film_id
GROUP BY f.rating
ORDER BY f.rating;

/* The percentage of films never rented by rating category is:
   G     - 3.93% (7 of 178 films)
   PG    - 5.67% (11 of 194 films)
   PG-13 - 4.48% (10 of 223 films)
   R     - 3.08% (6 of 195 films)
   NC-17 - 3.81% (8 of 210 films)

   PG-rated films have the highest percentage of never-rented
   films (5.67%), while R-rated films have the lowest (3.08%).
   Overall, 4.20% (42 of 1,000 films) have never been rented.
*/
/* Design decision: I create a distinct list of rented film IDs so each film is
   counted once regardless of the number of copies or rentals. A LEFT JOIN keeps
   films without inventory as well as films with inventory but no rentals, unlike
   an INNER JOIN. CASE WHEN identifies unmatched films and a numeric multiplier
   prevents integer division when calculating percentages. */

-- Q3. For each film category, show the total rental revenue and its share of overall revenue as a percentage.
/* Note:
   Business objective: Measure category contribution to rental receipts.
   Concept review: One row per category. Follow payment -> rental -> inventory -> film_category
   -> category. GROUP BY collapses rows; SUM OVER () computes the grand total without collapsing
   category rows.
   Reference reading: Ch. 7 pp. 129–138; Ch. 8 pp. 146–157; Ch. 9 pp. 166–171. Course topics:
   join cardinality and window functions.
   Check category assignments and payment coverage before
   comparing summed category revenue to SUM(amount) FROM payment. Shares should total
   approximately 100% after rounding if all revenue is classified once.
*/
WITH category_revenue AS (
    SELECT c.category_id, c.name AS category_name,
           COALESCE(SUM(p.amount), 0) AS total_revenue
    FROM category c
    LEFT JOIN film_category fc ON fc.category_id = c.category_id
    LEFT JOIN inventory i ON i.film_id = fc.film_id
    LEFT JOIN rental r ON r.inventory_id = i.inventory_id
    LEFT JOIN payment p ON p.rental_id = r.rental_id
    GROUP BY c.category_id, c.name
)
SELECT category_name, total_revenue,
       ROUND(100.0 * total_revenue / NULLIF(SUM(total_revenue) OVER (), 0), 2)
           AS revenue_share_pct
FROM category_revenue
ORDER BY total_revenue DESC, category_name;

/* Total rental revenue and percentage share by film category:
   Action      - $26,505.44 (6.54%)
   Animation   - $26,460.31 (6.53%)
   Children    - $26,399.88 (6.52%)
   Foreign     - $26,387.22 (6.51%)
   Documentary - $26,078.46 (6.44%)
   Music       - $26,036.49 (6.43%)
   Sci-Fi      - $25,944.08 (6.40%)
   Sports      - $25,583.19 (6.32%)
   New         - $25,403.41 (6.27%)
   Horror      - $25,241.89 (6.23%)
   Games       - $25,132.16 (6.20%)
   Travel      - $24,934.43 (6.16%)
   Classics    - $24,390.25 (6.02%)
   Drama       - $23,757.57 (5.86%)
   Family      - $23,714.46 (5.85%)
   Comedy      - $23,131.48 (5.71%)

   Action generated the highest revenue (6.54%), while Comedy
   generated the lowest (5.71%). Revenue is relatively evenly
   distributed across all 16 film categories.
*/
/* Design decision: I trace actual payments through rentals and inventory to
   film categories, retaining categories with no revenue using LEFT JOIN.
   SUM OVER gives the grand total while retaining each category row, avoiding
   a separate grand-total subquery. */

-- Q4. Identify customers who rented from at least five different film categories. List the customer name and distinct category count.
/* Note:
   Business objective: Identify customers with broad viewing interests.
   Concept review: One row per customer. COUNT(DISTINCT category_id) measures variety, not
   frequency. WHERE filters input rows; HAVING filters groups after aggregation.
   Reference reading: Ch. 8 pp. 152–162; Ch. 7 pp. 129–138. Course topics: multi-table joins,
   aggregate filters.
   Every output count must be at least five and no greater than
   the number of categories. Repeated rentals in a category must not increase the distinct
   count.
*/
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name,
       COUNT(DISTINCT fc.category_id) AS distinct_category_count
FROM customer c
JOIN rental r ON r.customer_id = c.customer_id
JOIN inventory i ON i.inventory_id = r.inventory_id
JOIN film_category fc ON fc.film_id = i.film_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT fc.category_id) >= 5
ORDER BY distinct_category_count DESC, c.customer_id;

/* Result: 986 customers rented films from at least five distinct
   categories. Mary Smith, Patricia Johnson, and Linda Williams
   are among the customers who rented from all 16 categories.
   The results identify customers with broad viewing interests,
   which can support personalized recommendations and promotions.
*/
/* Design decision: COUNT(DISTINCT) measures category variety. I use HAVING instead of WHERE because the threshold
   applies to an aggregate calculated for each customer. Grouping by the ID
   and name prevents customers with identical names from being combined. */

-- Q5. Show month-by-month rental counts for 2022, with a running total column accumulating across months.
/* Note:
   Business objective: Track monthly demand and cumulative rental activity.
   Concept review: One row per calendar month. DATE_TRUNC groups timestamps into months;
   generate_series supplies missing months. An ordered SUM window adds the current month to all
   prior months.
   Reference reading: Ch. 9 pp. 166–179; Ch. 12 pp. 232–239. Course topics: date
   transformations, running totals and frames.
*/
WITH months AS (
    SELECT generate_series(TIMESTAMP '2022-01-01',
                           TIMESTAMP '2022-12-01', INTERVAL '1 month') AS month_start
), monthly_rentals AS (
    SELECT DATE_TRUNC('month', rental_date) AS month_start,
           COUNT(*) AS rental_count
    FROM rental
    WHERE rental_date >= DATE '2022-01-01'
      AND rental_date < DATE '2023-01-01'
    GROUP BY DATE_TRUNC('month', rental_date)
)
SELECT m.month_start::date AS rental_month,
       COALESCE(r.rental_count, 0) AS rental_count,
       SUM(COALESCE(r.rental_count, 0)) OVER (
           ORDER BY m.month_start ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM months m
LEFT JOIN monthly_rentals r ON r.month_start = m.month_start
ORDER BY m.month_start;
/* Design decision: I aggregate rentals by month before applying the window
   function, which preserves one row per month. I use a calendar series instead
   of reporting only months present in rental so months with zero rentals are
   visible. A half-open date range avoids applying a function to the filtered
   timestamp column and the explicit window frame accumulates through each month. */

-- Q6. For each actor, calculate the average rental rate of films they appeared in. Return only those above the overall film average.
/* Note:
   Business objective: Compare actor filmographies with the catalog pricing benchmark.
   Concept review: One row per actor. AVG uses film rental_rate, not payment amount. An
   uncorrelated scalar subquery supplies the catalog-wide average; HAVING compares the group
   average with the benchmark.
   Reference reading: Ch. 7 pp. 124–128; Ch. 8 pp. 146–162. Course topics: bridge tables,
   subqueries, HAVING.
   Compute SELECT AVG(rental_rate) FROM film separately. Compare
   unrounded actor averages to it; rounded displayed values can look equal to the threshold.
*/
SELECT a.actor_id, a.first_name || ' ' || a.last_name AS actor_name,
       ROUND(AVG(f.rental_rate), 2) AS average_rental_rate
FROM actor a
JOIN film_actor fa ON fa.actor_id = a.actor_id
JOIN film f ON f.film_id = fa.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING AVG(f.rental_rate) > (SELECT AVG(rental_rate) FROM film)
ORDER BY AVG(f.rental_rate) DESC, a.actor_id;

/* Gene Hopkins has the highest average film rental rate ($3.81),
   followed by Fay Kilmer and Chris Depp ($3.79 each).
   The qualifying actors have average rental rates ranging from
   $2.99 to $3.81, all above the overall film average.
*/
/* Design decision: I use the film_actor bridge so the average represents films
   in an actor's filmography rather than rental transactions. A scalar subquery
   supplies the overall film average without weighting it by actor appearances.
   HAVING compares unrounded averages, while ROUND is limited to presentation. */

-- Q7. List all films rented in June 2023 but not in July 2023.
/* Note:
   Business objective: Find titles whose recorded June demand did not continue in July.
   Concept review: One row per film. EXCEPT returns distinct rows in the first set absent from
   the second. Compare film IDs, not copies or titles. Use inclusive lower and exclusive upper
   timestamp bounds.
   Reference reading: Ch. 7 pp. 140–143; Ch. 12 pp. 232–239. Course topics: set operations and
   date filtering.
   For each sampled result, confirm at least one June rental and
   no July rental. EXCEPT is directional; reversing the two inputs answers a different question.
*/
WITH june_only AS (
    SELECT i.film_id
    FROM rental r
    JOIN inventory i ON i.inventory_id = r.inventory_id
    WHERE r.rental_date >= DATE '2023-06-01'
      AND r.rental_date < DATE '2023-07-01'
    EXCEPT
    SELECT i.film_id
    FROM rental r
    JOIN inventory i ON i.inventory_id = r.inventory_id
    WHERE r.rental_date >= DATE '2023-07-01'
      AND r.rental_date < DATE '2023-08-01'
)
SELECT f.film_id, f.title
FROM june_only j
JOIN film f ON f.film_id = j.film_id
ORDER BY f.title, f.film_id;

/* Design decision: EXCEPT expresses the difference between two sets of film
   IDs and removes duplicates from repeated rentals. I chose it over NOT IN
   because the set operation directly matches the business question and avoids
   NOT IN's NULL-related pitfalls. Half-open date ranges include every timestamp
   in each month without including the first day of the next month. */

-- Q8. For each customer, show their most recent rental date and the number of days since that rental (as of query execution).
/* Note:
   Business objective: Measure customer inactivity for retention analysis.
   Concept review: One row per customer. MAX finds the latest timestamp; CURRENT_DATE minus a
   date returns calendar days. LEFT JOIN keeps customers with no rental history, producing NULL
   recency.
   Reference reading: Ch. 7 pp. 133–136; Ch. 8 pp. 146–157; Ch. 12 pp. 232–239. Course topics:
   outer joins, date arithmetic.
   Expect one row per customer. Compare a sampled MAX with that
   customer’s rental history. Recency changes with execution date; NULL is not zero days.
*/
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name,
       MAX(r.rental_date) AS most_recent_rental_date,
       CURRENT_DATE - MAX(r.rental_date)::date AS days_since_last_rental
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY days_since_last_rental DESC NULLS LAST, c.customer_id;
/* Design decision: MAX produces one latest rental timestamp per customer
   without the extra sorting and filtering required by a ranking approach.
   I use LEFT JOIN to retain customers who have never rented, leaving their
   recency NULL rather than assigning a misleading zero. Casting to date makes
   the subtraction return calendar days relative to the execution date. */

-- Q9. Which five stores had the highest rental revenue in the most recently recorded month of data?
/* Note:
   Business objective: Compare store receipts in the latest recorded payment month.
   Concept review: MAX identifies the latest payment date; DATE_TRUNC finds its month.
   Use payment_date for revenue timing and inventory.store_id for the rental outlet.
   GROUP BY establishes one row per store, and LIMIT is a maximum.
   Reference reading: Ch. 5 pp. 87–88; Ch. 7 pp. 124–138; Ch. 8 pp. 146–157;
   Ch. 12 pp. 232–239. Course topics: derived datasets, joins, dates and aggregation.
*/
WITH latest_month AS (
    SELECT DATE_TRUNC('month', MAX(payment_date)) AS month_start
    FROM payment
    WHERE rental_id IS NOT NULL
), store_revenue AS (
    SELECT i.store_id, SUM(p.amount) AS total_revenue
    FROM payment p
    JOIN rental r ON r.rental_id = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    CROSS JOIN latest_month lm
    WHERE p.payment_date >= lm.month_start
      AND p.payment_date < lm.month_start + INTERVAL '1 month'
    GROUP BY i.store_id
)
SELECT s.store_id, lm.month_start::date AS revenue_month,
       COALESCE(sr.total_revenue, 0) AS total_revenue
FROM store s
CROSS JOIN latest_month lm
LEFT JOIN store_revenue sr ON sr.store_id = s.store_id
WHERE lm.month_start IS NOT NULL
ORDER BY total_revenue DESC, s.store_id
LIMIT 5;

/* Store 2 generated the highest rental revenue ($1,248.81),
   followed by Store 1 ($1,161.07). Stores 0, 3, and 4 recorded
   zero rental revenue during the period under consideration
   (July 2026).
*/
/* Design decision: I use the latest rental-linked payment month rather than
   CURRENT_DATE because the database is historical and revenue is recognized here
   on the payment date. Inventory identifies the outlet providing the rental rather
   than the customer's home store or the staff member's assigned store. A CTE
   defines the month once instead of repeating a scalar subquery, and LEFT JOIN
   retains stores with zero receipts. LIMIT 5 returns up to five available stores. */

-- Q10. Find film categories where the average replacement cost of films exceeds the overall average replacement cost by more than 10%.
/* Note:
   Business objective: Identify categories with unusually high replacement costs.
   Concept review: AVG computes the mean per category; the overall benchmark must
   be calculated from film, not inventory or film_category, to avoid weighting films
   by copies or category membership. A relative increase of 10% means multiplying
   the benchmark by 1.10; HAVING filters groups using unrounded averages.
   Reference reading: Ch. 7 pp. 124–128; Ch. 8 pp. 146–162. Course topics:
   scalar subqueries, CTEs, aggregation and group-level filtering.
   Validation: Every qualifying unrounded category mean must exceed 1.10 times
   the catalog mean. An empty result is valid; do not weaken the threshold.
*/
WITH overall_cost AS (
    SELECT AVG(replacement_cost) AS overall_avg
    FROM film
)
SELECT c.category_id, c.name AS category_name,
       ROUND(AVG(f.replacement_cost), 2) AS category_avg_cost,
       ROUND(o.overall_avg, 2) AS overall_avg_cost,
       ROUND(100.0 * (AVG(f.replacement_cost) - o.overall_avg)
             / NULLIF(o.overall_avg, 0), 2) AS pct_above_overall
FROM category c
JOIN film_category fc ON fc.category_id = c.category_id
JOIN film f ON f.film_id = fc.film_id
CROSS JOIN overall_cost o
GROUP BY c.category_id, c.name, o.overall_avg
HAVING AVG(f.replacement_cost) > 1.10 * o.overall_avg
ORDER BY AVG(f.replacement_cost) DESC, c.category_id;

/* Result: No film category has an average replacement cost
   exceeding the overall average ($19.98) by more than 10%.
   Classics has the highest average replacement cost ($20.63),
   which is only 3.23% above the overall average. Documentary
   has the lowest ($19.49), at 2.45% below the overall average.
 */
/* Design decision: I calculate the overall average directly from film to give
   every title equal weight rather than weighting by inventory copies. I use a
   single-row CTE instead of repeating scalar subqueries so the benchmark can be
   reused for the filter and displayed comparison. HAVING applies the strict
   threshold before rounding, and NULLIF protects the percentage denominator. */

-- EXPLAIN ANALYZE: Question 8 (same query as above).
/* Note: Textbook Ch. 10, pp. 188–195, 204–207.
   EXPLAIN shows estimated costs and rows; ANALYZE executes the query and
   reports actual time, rows and loops. Costs are not milliseconds and parent
   timings include child work. For repeated nodes consider time and loops.
   Identify the costly operation using the actual plan.
*/
EXPLAIN ANALYZE
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name,
       MAX(r.rental_date) AS most_recent_rental_date,
       CURRENT_DATE - MAX(r.rental_date)::date AS days_since_last_rental
FROM customer c
LEFT JOIN rental r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY days_since_last_rental DESC NULLS LAST, c.customer_id;

/* Performance Annotation -- Question 8

   The Hash Right Join is the primary observed performance bottleneck,
   with an estimated cost of 39.48..1301.68 and an actual execution time
   of 0.231..11.778 ms over one loop, including its child operations.
   This execution plan indicates that PostgreSQL performs a sequential
   scan of all 51,805 rental records and joins them with 999 customers,
   producing 51,807 intermediate rows before aggregation.
   Although the query completes efficiently in 18.409 ms, with all
   618 shared buffer accesses resulting in cache hits, processing
   the entire rental table could become increasingly expensive as
   the dataset grows.
   If the rental table were 100 times larger, I would test a composite
   B-tree index on rental(customer_id, rental_date DESC) and rewrite
   the query using LEFT JOIN LATERAL with ORDER BY and LIMIT 1 to
   retrieve each customer's most recent rental, thereby avoiding
   the need to scan and aggregate the entire rental history.
   Before adopting this optimization, I would verify whether an
   equivalent index already exists and compare the actual execution
   plans and timings to determine whether the proposed approach
   improves performance.
*/

/* References
   -- Shan, J., Li, H., Goldwasser, M., Malik, U., & Johnston, B. (2025).
   SQL for Data Analytics (4th ed.). Packt Publishing. Chapters 5–10, 12.
   -- PostgreSQL Global Development Group. (n.d.). PostgreSQL documentation
      https://www.postgresql.org/docs/
   
*/
