-- Part 1

-- Task 1

-- The marketing team needs a list of animation movies between 2017 and 2019 to promote family-friendly content in an upcoming season in stores. 
-- Show all animation movies released during this period with rate more than 1, sorted alphabetically


-- Assumptions and business interpretation:

-- I understood this task as preparing a list of films for a seasonal marketing campaign in stores focused on family-friendly content.

-- I treated films as animation movies if they are linked to the 'Animation' category through the film_category table.

-- I interpreted "between 2017 and 2019" as an inclusive period,
-- so I filtered films with release_year between 2017 and 2019.

-- I interpreted "rate more than 1" as rental_rate > 1.

-- Since the task mentions family-friendly content, I also applied a rating-based filter.
-- I included films with ratings 'G' and 'PG', because both can be considered suitable
-- for family-oriented promotion.
-- I did not limit the result only to 'G', because that would be too strict
-- and could exclude films that are still appropriate for family viewing.
-- 'PG' fits this business need, as it allows family viewing with parental guidance.
-- I excluded 'PG-13', 'R' and 'NC-17', because they are less suitable for this type of campaign.



-- CTE Solution:

WITH animation_movies AS (
    SELECT
        f.film_id,
        f.title,
        f.release_year,
        f.rental_rate,
        f.rating
    FROM public.film AS f
    INNER JOIN public.film_category AS fc
        ON f.film_id = fc.film_id
    INNER JOIN public.category AS c
        ON fc.category_id = c.category_id
    WHERE c.name = 'Animation'
      AND f.release_year BETWEEN 2017 AND 2019
      AND f.rental_rate > 1
      AND f.rating IN ('G', 'PG')
)
SELECT
    am.title,
    am.release_year,
    am.rental_rate,
    am.rating
FROM animation_movies AS am
ORDER BY am.title ASC;

--Join type explanation:

--INNER JOIN between film and film_category returns only films that have a category assigned.
--INNER JOIN between film_category and category returns only rows with a matching category.
--As a result, only films that really belong to the Animation category are included.

--Advantages:

--This version is easy to read because the logic is split into two steps.
--It is a good option when the query becomes larger and needs to be structured more clearly.
--The CTE name makes the purpose of the first step easy to understand.

--Disadvantages:

--It is slightly longer than necessary for a simple task.
--For small queries like this one, the extra step is not always needed.



-- Subquery solution:

SELECT
    f.title,
    f.release_year,
    f.rental_rate,
    f.rating
FROM public.film AS f
WHERE f.film_id IN (
    SELECT
        fc.film_id
    FROM public.film_category AS fc
    INNER JOIN public.category AS c
        ON fc.category_id = c.category_id
    WHERE c.name = 'Animation'
)
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
  AND f.rating IN ('G', 'PG')
ORDER BY f.title ASC;

--Join type explanation:

--In the subquery, INNER JOIN returns only those film_id values that are linked to an existing category row.
--The outer query then selects only films whose film_id is in that result.

--Advantages:

--This version is compact and still easy to follow.
--It works well when the task is naturally understood as “find films that belong to a certain category”.
--The main query stays focused on the film table.

--Disadvantages:

--The logic is split between the outer query and the subquery, so it is a bit less direct than the JOIN version.
--In more complex tasks, nested queries can become harder to read.



-- JOIN solution:

SELECT
    f.title,
    f.release_year,
    f.rental_rate,
    f.rating
FROM public.film AS f
INNER JOIN public.film_category AS fc
    ON f.film_id = fc.film_id
INNER JOIN public.category AS c
    ON fc.category_id = c.category_id
WHERE c.name = 'Animation'
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
  AND f.rating IN ('G', 'PG')
ORDER BY f.title ASC;

--Join type explanation:

--INNER JOIN keeps only rows that match in both joined tables.
--This means the result includes only films that are linked to a category and where that category is Animation.
--This is the right join type here, because the task does not require films without category matches.

--Advantages:

--This is the most direct solution.
--It is easy to read and clearly shows the relationship between the tables.
--For a simple task like this, it is usually the most practical option.

--Disadvantages:

--If a query has many joins, it can become harder to read.
--If the source data contains duplicate links, duplicate rows could appear.



--Which solution I would use in production:

--For this task, I would use the JOIN solution.

--I would choose it because it is the clearest and most direct way to solve the problem. 
--It shows the table relationships clearly, does not add extra layers and is easy to maintain. 
--The CTE solution is also good, but for this task it is a bit more detailed than necessary.




-- Task 2

--The finance department requires a report on store performance to assess profitability 
--and plan resource allocation for stores after March 2017. 
--Calculate the revenue earned by each rental store after March 2017 (since April) 
--(include columns: address and address2 – as one column, revenue)


-- Assumptions and business interpretation:

-- I understood this task as a store-level revenue report for the period starting from April 1, 2017.

-- I interpreted revenue as the sum of payment.amount,
-- because the payment table stores the actual amount paid by customers.

-- I linked revenue to a store through rental and inventory,
-- because the task asks for revenue earned by each rental store.
-- I treated the rental store as the store from which the rented inventory item came.

-- I used the store address from the store table, joined to the address table.

-- I combined address and address2 into one column.
-- If address2 is NULL or empty, I returned only address.



-- CTE Solution:

WITH store_revenue_data AS (
    SELECT
        s.store_id,
        a.address,
        a.address2,
        p.amount
    FROM public.payment AS p
    INNER JOIN public.rental AS r
        ON p.rental_id = r.rental_id
    INNER JOIN public.inventory AS i
        ON r.inventory_id = i.inventory_id
    INNER JOIN public.store AS s
        ON i.store_id = s.store_id
    INNER JOIN public.address AS a
        ON s.address_id = a.address_id
    WHERE p.payment_date >= DATE '2017-04-01'
)
SELECT
    CASE
        WHEN srd.address2 IS NULL OR srd.address2 = ''
            THEN srd.address
        ELSE srd.address || ', ' || srd.address2
    END AS store_address,
    SUM(srd.amount) AS revenue
FROM store_revenue_data AS srd
GROUP BY
    srd.address,
    srd.address2
ORDER BY store_address ASC;

--Join type explanation:

--INNER JOIN between payment and rental keeps only payments linked to an existing rental.
--INNER JOIN between rental and inventory keeps only rentals linked to an inventory item.
--INNER JOIN between inventory and store identifies the store that rented out the item.
--INNER JOIN between store and address keeps only stores with a valid address.
--This means the result includes only payments that can be fully connected to a rental store.

--Advantages:

--This version is easy to read because the logic is split into two steps.
--The CTE prepares the detailed store payment data first and the main query calculates revenue.
--It is easier to extend if more store-level fields are needed later.

--Disadvantages:

--It is longer than necessary for a relatively simple report.
--For a small query, the extra step may not be needed.



-- Subquery solution:

SELECT
    CASE
        WHEN store_data.address2 IS NULL OR store_data.address2 = ''
            THEN store_data.address
        ELSE store_data.address || ', ' || store_data.address2
    END AS store_address,
    SUM(store_data.amount) AS revenue
FROM (
    SELECT
        s.store_id,
        a.address,
        a.address2,
        p.amount
    FROM public.payment AS p
    INNER JOIN public.rental AS r
        ON p.rental_id = r.rental_id
    INNER JOIN public.inventory AS i
        ON r.inventory_id = i.inventory_id
    INNER JOIN public.store AS s
        ON i.store_id = s.store_id
    INNER JOIN public.address AS a
        ON s.address_id = a.address_id
    WHERE p.payment_date >= DATE '2017-04-01'
) AS store_data
GROUP BY
    store_data.address,
    store_data.address2
ORDER BY store_address ASC;


--Join type explanation:

--The joins inside the subquery connect each payment to the rental, inventory item, store and store address.
--INNER JOIN keeps only rows where all required matches exist.
--The outer query then groups the prepared rows and calculates total revenue.

--Advantages:

--It separates the detailed data preparation from the final aggregation.
--It is still fairly easy to understand.
--It works well when you want the final query block to focus only on the result.

--Disadvantages:

--It is a bit less readable than the CTE version.
--In bigger queries, subqueries can become harder to follow.



-- JOIN solution:

SELECT
    CASE
        WHEN a.address2 IS NULL OR a.address2 = ''
            THEN a.address
        ELSE a.address || ', ' || a.address2
    END AS store_address,
    SUM(p.amount) AS revenue
FROM public.payment AS p
INNER JOIN public.rental AS r
    ON p.rental_id = r.rental_id
INNER JOIN public.inventory AS i
    ON r.inventory_id = i.inventory_id
INNER JOIN public.store AS s
    ON i.store_id = s.store_id
INNER JOIN public.address AS a
    ON s.address_id = a.address_id
WHERE p.payment_date >= DATE '2017-04-01'
GROUP BY
    a.address,
    a.address2
ORDER BY store_address ASC;


--Join type explanation:

--INNER JOIN keeps only matching rows across all connected tables.
--This means only payments that can be traced to a rental, inventory item, store and address are included.
--This fits the task because the report is about actual revenue earned by rental stores.

--Advantages:

--This is the most direct version.
--It clearly shows how the tables are connected.
--For a task like this, it is usually the easiest solution to read and maintain.

--Disadvantages:

--If more business rules are added, the query can become longer and less structured.
--All logic is written in one block, so it is slightly less organized than the CTE version.



--Which solution I would use in production:

--For this task, I would use the JOIN solution.

--I would choose it because it is the clearest and most direct way to calculate the result. 
--It shows the connection from payment to rental store clearly, 
--and for this task the logic is simple enough that an extra CTE is not necessary. 
--If the report became more detailed later, I would consider using the CTE version.



-- Task 3

--The marketing department in our stores aims to identify the most successful actors since 2015 
--to boost customer interest in their films. 
--Show top-5 actors by number of movies (released since 2015) they took part in 
--(columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)


-- Assumptions and business interpretation:

-- I understood this task as identifying the actors who appeared in the highest number of films released since 2015.

-- I counted the number of movies per actor using the links between actor, film_actor and film.

-- I assumed that each row in film_actor represents one actor's participation in one film,
-- so COUNT(f.film_id) can be used to calculate the number of movies.

-- I interpreted "top 5 actors" as returning exactly 5 rows.

-- If several actors have the same number_of_movies, I return exactly 5 rows
-- by applying additional sorting by first_name and last_name in ascending order.
-- This makes the result stable and deterministic.



-- CTE Solution:

WITH actor_movie_counts AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(f.film_id) AS number_of_movies
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
    WHERE f.release_year >= 2015
    GROUP BY
        a.actor_id,
        a.first_name,
        a.last_name
)
SELECT
    amc.first_name,
    amc.last_name,
    amc.number_of_movies
FROM actor_movie_counts AS amc
ORDER BY
    amc.number_of_movies DESC,
    amc.first_name ASC,
    amc.last_name ASC
LIMIT 5;

--Join type explanation:

--INNER JOIN between actor and film_actor keeps only actors who are linked to at least one film.
--INNER JOIN between film_actor and film keeps only those linked films that exist in the film table.
--This means the result includes only actors who took part in films released since 2015.

--Advantages:

--This version is easy to read because the counting step is separated from the final result.
--It is easier to extend if more columns or conditions are needed later.
--The logic is clear and structured.

--Disadvantages:

--It is a bit longer than necessary for a simple top-5 query.
--For a small task like this, the CTE is not strictly needed.


-- Subquery solution:

SELECT
    actor_data.first_name,
    actor_data.last_name,
    actor_data.number_of_movies
FROM (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(f.film_id) AS number_of_movies
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
    WHERE f.release_year >= 2015
    GROUP BY
        a.actor_id,
        a.first_name,
        a.last_name
) AS actor_data
ORDER BY
    actor_data.number_of_movies DESC,
    actor_data.first_name ASC,
    actor_data.last_name ASC
LIMIT 5;

--Join type explanation:

--The joins inside the subquery connect actors to the films they acted in.
--INNER JOIN keeps only matching rows, so only actors with films released since 2015 are included.
--The outer query then sorts the result and returns exactly 5 rows.

--Advantages:

--It separates the counting logic from the final sorting and limiting.
--It is still fairly clear and easy to follow.
--It works well when the final query should focus only on the final output.

--Disadvantages:

--It is slightly less readable than the CTE version.
--In more complex cases, nested subqueries can become harder to maintain.


-- JOIN solution:

SELECT
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM public.actor AS a
INNER JOIN public.film_actor AS fa
    ON a.actor_id = fa.actor_id
INNER JOIN public.film AS f
    ON fa.film_id = f.film_id
WHERE f.release_year >= 2015
GROUP BY
    a.first_name,
    a.last_name
ORDER BY
    number_of_movies DESC,
    a.first_name ASC,
    a.last_name ASC
LIMIT 5;

--Join type explanation:

--INNER JOIN keeps only actors who have matching rows in film_actor and matching films in film.
--This means only actors who appeared in films released since 2015 are counted.
--This is the correct join type here because the task does not ask to include actors with no matching films.

--Advantages:

--This is the most direct solution.
--It is short, clear and easy to understand.
--For a task like this, it is usually the most practical option.

--Disadvantages:

--If more conditions are added later, one query block can become harder to read.
--It is less structured than the CTE version.



--Which solution I would use in production:

--For this task, I would use the JOIN solution.

--I would choose it because it is the clearest and most direct way to solve the task. 
--The logic is simple: connect actors to films, filter by release year, count films, 
--sort the result and return the top 5. The extra sorting by first_name and last_name 
--also makes the result stable when several actors have the same number of movies.

--If the task became more detailed later, I would consider using the CTE version.



-- Task 4

--The marketing team needs to track the production trends of Drama, Travel and Documentary films 
--to inform genre-specific marketing strategies. Show number of Drama, Travel, Documentary per year 
--(include columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), 
--sorted by release year in descending order. Dealing with NULL values is encouraged)


-- Assumptions and business interpretation:

-- I understood this task as a yearly summary of film production by category.

-- I treated Drama, Travel and Documentary films as films linked to these category names through the film_category table.

-- I assumed that one film can belong to different categories,
-- so the same film may be counted in more than one category if it is linked to more than one of them.

-- I grouped the result by release_year, because the task asks to show the number of films per year.

-- I used conditional aggregation to place all three category counts in separate columns.

-- Since the task mentions dealing with NULL values, I used COALESCE
-- so that missing values are shown as 0 instead of NULL.



-- CTE Solution:

WITH category_counts AS (
    SELECT
        f.release_year,
        SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
        SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
        SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
    FROM public.film AS f
    INNER JOIN public.film_category AS fc
        ON f.film_id = fc.film_id
    INNER JOIN public.category AS c
        ON fc.category_id = c.category_id
    WHERE c.name IN ('Drama', 'Travel', 'Documentary')
    GROUP BY
        f.release_year
)
SELECT
    cc.release_year,
    cc.number_of_drama_movies,
    cc.number_of_travel_movies,
    cc.number_of_documentary_movies
FROM category_counts AS cc
ORDER BY cc.release_year DESC;


--Join type explanation:

--INNER JOIN between film and film_category keeps only films that have a category assignment.
--INNER JOIN between film_category and category keeps only rows with a matching category.
--This means the result includes only films that are connected to at least one of the required categories.

--Advantages:

--This version is easy to read because the counting logic is separated from the final output.
--It is easier to extend if more categories or extra conditions need to be added later.
--The CTE makes the logic more structured.

--Disadvantages:

--It is a bit longer than necessary for a report of this size.
--For a simple aggregation task, the extra step is not always needed.



-- Subquery solution:

SELECT
    category_data.release_year,
    category_data.number_of_drama_movies,
    category_data.number_of_travel_movies,
    category_data.number_of_documentary_movies
FROM (
    SELECT
        f.release_year,
        SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
        SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
        SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
    FROM public.film AS f
    INNER JOIN public.film_category AS fc
        ON f.film_id = fc.film_id
    INNER JOIN public.category AS c
        ON fc.category_id = c.category_id
    WHERE c.name IN ('Drama', 'Travel', 'Documentary')
    GROUP BY
        f.release_year
) AS category_data
ORDER BY category_data.release_year DESC;

--Join type explanation:

--The joins inside the subquery connect films to their categories.
--INNER JOIN keeps only matching rows, so only films with one of the required categories are counted.
--The outer query is used to return the final result and handle nulls clearly.

--Advantages:

--It separates the aggregation step from the final output.
--It is still quite clear and readable.
--It works well when you want the main query to focus only on the final result.

--Disadvantages:

--It is slightly less readable than the CTE version.
--In more complex cases, subqueries can be harder to maintain.



-- JOIN solution:

SELECT
    f.release_year,
    SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_movies,
    SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM public.film AS f
INNER JOIN public.film_category AS fc
    ON f.film_id = fc.film_id
INNER JOIN public.category AS c
    ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY
    f.release_year
ORDER BY
    f.release_year DESC;


--Join type explanation:

--INNER JOIN keeps only films that are linked to category rows.
--This means only films that belong to Drama, Travel, or Documentary are included in the counts.
--This is appropriate because the task is only about these three categories.

--Advantages:

--This is the most direct solution.
--It is compact and easy to follow once the table relationships are known.
--For this kind of report, it is usually the most practical option.

--Disadvantages:

--If more logic is added later, a single query block can become harder to read.
--It is less structured than the CTE version.




--Which solution I would use in production:

--For this task, I would use the JOIN solution.

--I would choose it because it is the clearest and most direct option for this type of aggregation. 
--The logic is simple: connect films to categories, count the needed categories with CASE, group by year and sort the result. 
--If the report became more complex later, I would consider using the CTE version.

--P.S.
--I handled NULL-related situations by using conditional aggregation with CASE expressions.
--For each year, if there are no films for one of the selected categories in a given row,
--the query adds 0 instead of NULL.
--This keeps the category counts clear and makes the result easier to use in reporting.



-- Part 2

-- Task 1

--The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores revenue. 
--Show which three employees generated the most revenue in 2017? 

--Assumptions: 
--staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store; 
--take into account only payment_date



-- Assumptions and business interpretation:

-- I understood this task as finding the three employees who processed
-- the highest total payment amount in 2017.

-- Since staff could work in several stores during the year,
-- I interpreted the "last store" as the store linked to the employee's most recent payment in 2017.

-- If a staff member has more than one payment at the same latest payment_date,
-- I use the highest payment_id as a tie-breaker to keep only one final payment row.

-- I return exactly 3 rows.
-- If several employees have the same total revenue, I use additional sorting
-- by first_name and last_name in ascending order to make the result stable.



-- CTE solution:

WITH staff_revenue AS (
    SELECT
        p.staff_id,
        st.first_name,
        st.last_name,
        SUM(p.amount) AS total_revenue
    FROM public.payment AS p
    INNER JOIN public.staff AS st
        ON p.staff_id = st.staff_id
    WHERE p.payment_date >= DATE '2017-01-01'
      AND p.payment_date < DATE '2018-01-01'
    GROUP BY
        p.staff_id,
        st.first_name,
        st.last_name
),
last_payment_per_staff AS (
    SELECT
        p.staff_id,
        MAX(p.payment_date) AS last_payment_date
    FROM public.payment AS p
    WHERE p.payment_date >= DATE '2017-01-01'
      AND p.payment_date < DATE '2018-01-01'
    GROUP BY
        p.staff_id
),
last_payment_id AS (
    SELECT
        p.staff_id,
        MAX(p.payment_id) AS last_payment_id
    FROM public.payment AS p
    INNER JOIN last_payment_per_staff AS lps
        ON p.staff_id = lps.staff_id
       AND p.payment_date = lps.last_payment_date
    GROUP BY
        p.staff_id
),
last_store_per_staff AS (
    SELECT
        p.staff_id,
        i.store_id,
        CASE
            WHEN a.address2 IS NULL OR a.address2 = ''
                THEN a.address
            ELSE a.address || ', ' || a.address2
        END AS store_address
    FROM public.payment AS p
    INNER JOIN last_payment_id AS lpi
        ON p.staff_id = lpi.staff_id
       AND p.payment_id = lpi.last_payment_id
    INNER JOIN public.rental AS r
        ON p.rental_id = r.rental_id
    INNER JOIN public.inventory AS i
        ON r.inventory_id = i.inventory_id
    INNER JOIN public.store AS s
        ON i.store_id = s.store_id
    INNER JOIN public.address AS a
        ON s.address_id = a.address_id
)
SELECT
    sr.first_name,
    sr.last_name,
    lss.store_id,
    lss.store_address,
    sr.total_revenue
FROM staff_revenue AS sr
INNER JOIN last_store_per_staff AS lss
    ON sr.staff_id = lss.staff_id
ORDER BY
    sr.total_revenue DESC,
    sr.first_name ASC,
    sr.last_name ASC
LIMIT 3;


--Join type explanation:

--INNER JOIN between payment and staff keeps only payment rows that belong to an existing employee.
--INNER JOIN between payment, rental, inventory, store and address is used to identify the store connected to the employee’s last payment in 2017.
--INNER JOIN is appropriate here because the task is about employees who actually generated revenue and whose last store can be identified from the available data.

--Advantages:

--This version is the clearest because the logic is split into steps.
--Each CTE has one purpose: revenue, latest payment date, latest payment id and last store.
--It is easier to test and explain during review.

--Disadvantages:

--It is longer than the other versions.
--It reads the payment table more than once.
--For a simple task, this structure could feel too detailed, but here the extra logic makes it useful.




-- Subquery solution:

SELECT
    result_data.first_name,
    result_data.last_name,
    result_data.store_id,
    result_data.store_address,
    result_data.total_revenue
FROM (
    SELECT
        sr.staff_id,
        sr.first_name,
        sr.last_name,
        lss.store_id,
        lss.store_address,
        sr.total_revenue
    FROM (
        SELECT
            p.staff_id,
            st.first_name,
            st.last_name,
            SUM(p.amount) AS total_revenue
        FROM public.payment AS p
        INNER JOIN public.staff AS st
            ON p.staff_id = st.staff_id
        WHERE p.payment_date >= DATE '2017-01-01'
          AND p.payment_date < DATE '2018-01-01'
        GROUP BY
            p.staff_id,
            st.first_name,
            st.last_name
    ) AS sr
    INNER JOIN (
        SELECT
            p.staff_id,
            i.store_id,
            CASE
                WHEN a.address2 IS NULL OR a.address2 = ''
                    THEN a.address
                ELSE a.address || ', ' || a.address2
            END AS store_address
        FROM public.payment AS p
        INNER JOIN public.rental AS r
            ON p.rental_id = r.rental_id
        INNER JOIN public.inventory AS i
            ON r.inventory_id = i.inventory_id
        INNER JOIN public.store AS s
            ON i.store_id = s.store_id
        INNER JOIN public.address AS a
            ON s.address_id = a.address_id
        WHERE p.payment_id = (
            SELECT MAX(p2.payment_id)
            FROM public.payment AS p2
            WHERE p2.staff_id = p.staff_id
              AND p2.payment_date = (
                  SELECT MAX(p3.payment_date)
                  FROM public.payment AS p3
                  WHERE p3.staff_id = p.staff_id
                    AND p3.payment_date >= DATE '2017-01-01'
                    AND p3.payment_date < DATE '2018-01-01'
              )
        )
    ) AS lss
        ON sr.staff_id = lss.staff_id
) AS result_data
ORDER BY
    result_data.total_revenue DESC,
    result_data.first_name ASC,
    result_data.last_name ASC
LIMIT 3;

--Join type explanation:

--INNER JOIN is used to connect employees with their revenue and with the store from their last payment.
--Inside the nested subquery, payment is linked to rental, inventory, store and address to identify the last store.
--The nested subqueries are used to find the latest payment row in 2017 for each employee.

--Advantages:

--This version follows the same business logic as the CTE solution.
--It keeps the logic inside nested query blocks instead of separate named CTEs.

--Disadvantages:

--It is harder to read than the CTE version.
--The nested structure makes the logic less easy to explain.
--It is more difficult to maintain if the task becomes bigger.
--It takes more time to run this query.



-- JOIN Solution:

SELECT
    st.first_name,
    st.last_name,
    i.store_id,
    CASE
        WHEN a.address2 IS NULL OR a.address2 = ''
            THEN a.address
        ELSE a.address || ', ' || a.address2
    END AS store_address,
    SUM(p_all.amount) AS total_revenue
FROM public.staff AS st
INNER JOIN public.payment AS p_all
    ON st.staff_id = p_all.staff_id
INNER JOIN public.payment AS p_last
    ON st.staff_id = p_last.staff_id
INNER JOIN public.rental AS r
    ON p_last.rental_id = r.rental_id
INNER JOIN public.inventory AS i
    ON r.inventory_id = i.inventory_id
INNER JOIN public.store AS s
    ON i.store_id = s.store_id
INNER JOIN public.address AS a
    ON s.address_id = a.address_id
WHERE p_all.payment_date >= DATE '2017-01-01'
  AND p_all.payment_date < DATE '2018-01-01'
  AND p_last.payment_date >= DATE '2017-01-01'
  AND p_last.payment_date < DATE '2018-01-01'
  AND NOT EXISTS (
      SELECT 1
      FROM public.payment AS p2
      WHERE p2.staff_id = p_last.staff_id
        AND p2.payment_date >= DATE '2017-01-01'
        AND p2.payment_date < DATE '2018-01-01'
        AND (
            p2.payment_date > p_last.payment_date
            OR (
                p2.payment_date = p_last.payment_date
                AND p2.payment_id > p_last.payment_id
            )
        )
  )
GROUP BY
    st.staff_id,
    st.first_name,
    st.last_name,
    i.store_id,
    a.address,
    a.address2
ORDER BY
    total_revenue DESC,
    st.first_name ASC,
    st.last_name ASC
LIMIT 3;


--Join type explanation:

--INNER JOIN keeps only rows that match across staff, payment, rental, inventory, store and address.
--p_all is used to calculate total revenue in 2017.
--p_last is used to identify the last payment row in 2017 for each employee and then determine the last store.
--The NOT EXISTS condition keeps only the latest payment row for each employee.

--Advantages:

--This version keeps the main logic centered around joins.
--It does not use a derived table in the FROM clause.
--It still follows the same business logic as the other two solutions.

--Disadvantages:

--This version is harder to read than the CTE solution.
--It uses the payment table twice, which makes the query more complex.


--P.S.
--This solution is mainly join-based, but it still uses a correlated subquery
--in the WHERE clause to identify the last payment row for each employee.
--A fully pure JOIN-only solution is difficult here because the task requires
--selecting the latest payment per staff member without using window functions.



-- Which solution I would use in production:

-- For this task, I would use the CTE solution.

-- I would choose it because this task has several business steps:
-- 1. calculate revenue per employee,
-- 2. find the latest payment in 2017,
-- 3. resolve ties with payment_id,
-- 4. identify the last store from that payment.

-- The CTE solution separates these steps clearly,
-- so it is easier to read, test, maintain and explain during review.



-- Task 2

-- The management team wants to identify the most popular movies and their target 
-- audience age groups to optimize marketing efforts. 
-- Show which 5 movies were rented more than others (number of rentals), 
-- and what's the expected age of the audience for these movies? 
-- To determine expected age please use 'Motion Picture Association film rating system'


-- Assumptions and business interpretation:

-- I understood this task as identifying the 5 most rented films based on the number of rental records.

-- I interpreted "were rented more than others" as counting how many times each film appears
-- in the rental history through rental -> inventory -> film.

-- I mapped the expected audience age group from film.rating
-- using the Motion Picture Association film rating system provided in the task.

-- I interpreted the audience age groups as follows:
-- G      -> All ages admitted
-- PG     -> Some material may not be suitable for children
-- PG-13  -> May be inappropriate for children under 13
-- R      -> Under 17 requires accompanying parent or adult guardian
-- NC-17  -> No one 17 and under admitted

-- I return exactly 5 rows.
-- If several films have the same number of rentals, I still return only 5 rows
-- and use additional sorting by title in ascending order to make the result stable.


-- CTE Solution:

WITH film_rental_counts AS (
    SELECT
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS number_of_rentals
    FROM public.film AS f
    INNER JOIN public.inventory AS i
        ON f.film_id = i.film_id
    INNER JOIN public.rental AS r
        ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id,
        f.title,
        f.rating
)
SELECT
    frc.title,
    frc.number_of_rentals,
    CASE
        WHEN frc.rating = 'G'
            THEN 'All ages admitted'
        WHEN frc.rating = 'PG'
            THEN 'Some material may not be suitable for children'
        WHEN frc.rating = 'PG-13'
            THEN 'May be inappropriate for children under 13'
        WHEN frc.rating = 'R'
            THEN 'Under 17 requires accompanying parent or adult guardian'
        WHEN frc.rating = 'NC-17'
            THEN 'No one 17 and under admitted'
        ELSE 'Unknown rating'
    END AS expected_audience_age
FROM film_rental_counts AS frc
ORDER BY
    frc.number_of_rentals DESC,
    frc.title ASC
LIMIT 5;


--Join type explanation:

--INNER JOIN between film and inventory keeps only films that exist in store inventory.
--INNER JOIN between inventory and rental keeps only inventory items that were actually rented.
--This means only films with real rental activity are included in the result.

--Advantages:

--This version is easy to read because the rental counting step is separated from the final mapping of rating to audience age.
--It is a good option if more business rules need to be added later.
--The logic is clear and structured.

--Disadvantages:

--It is a bit longer than necessary for a task of this size.
--For a straightforward top-5 query, the extra CTE is not always needed.



-- Subquery solution:

SELECT
    film_data.title,
    film_data.number_of_rentals,
    CASE
        WHEN film_data.rating = 'G'
            THEN 'All ages admitted'
        WHEN film_data.rating = 'PG'
            THEN 'Some material may not be suitable for children'
        WHEN film_data.rating = 'PG-13'
            THEN 'May be inappropriate for children under 13'
        WHEN film_data.rating = 'R'
            THEN 'Under 17 requires accompanying parent or adult guardian'
        WHEN film_data.rating = 'NC-17'
            THEN 'No one 17 and under admitted'
        ELSE 'Unknown rating'
    END AS expected_audience_age
FROM (
    SELECT
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS number_of_rentals
    FROM public.film AS f
    INNER JOIN public.inventory AS i
        ON f.film_id = i.film_id
    INNER JOIN public.rental AS r
        ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id,
        f.title,
        f.rating
) AS film_data
ORDER BY
    film_data.number_of_rentals DESC,
    film_data.title ASC
LIMIT 5;


--Join type explanation:

--The joins inside the subquery connect films to their rentals through inventory.
--INNER JOIN keeps only films that were actually rented.
--The outer query then maps the rating to the audience age description and returns the top 5.

--Advantages:

--It separates the aggregation logic from the final output.
--It is still clear and fairly easy to follow.
--It works well when the outer query should focus on presentation of the final result.

--Disadvantages:

--It is a bit less readable than the CTE version.
--In larger tasks, nested queries can become harder to maintain.



-- JOIN solution:

SELECT
    f.title,
    COUNT(r.rental_id) AS number_of_rentals,
    CASE
        WHEN f.rating = 'G'
            THEN 'All ages admitted'
        WHEN f.rating = 'PG'
            THEN 'Some material may not be suitable for children'
        WHEN f.rating = 'PG-13'
            THEN 'May be inappropriate for children under 13'
        WHEN f.rating = 'R'
            THEN 'Under 17 requires accompanying parent or adult guardian'
        WHEN f.rating = 'NC-17'
            THEN 'No one 17 and under admitted'
        ELSE 'Unknown rating'
    END AS expected_audience_age
FROM public.film AS f
INNER JOIN public.inventory AS i
    ON f.film_id = i.film_id
INNER JOIN public.rental AS r
    ON i.inventory_id = r.inventory_id
GROUP BY
    f.film_id,
    f.title,
    f.rating
ORDER BY
    number_of_rentals DESC,
    f.title ASC
LIMIT 5;


--Join type explanation:

--INNER JOIN between film, inventory and rental keeps only films that have rental activity.
--This is the correct join type here because the task asks for the most rented films, so films with no rentals should not be included.

--Advantages:

--This is the most direct solution.
--It is short, clear and easy to read.
--For this task, it is usually the most practical option.

--Disadvantages:

--If more business rules are added later, one query block can become harder to read.
--It is less structured than the CTE version.



--Which solution I would use in production:

-- For this task, I would use the JOIN solution.

-- I would choose it because the task is straightforward:
-- connect films to rentals, count the number of rentals,
-- map the rating to an audience age description, sort the result,
-- and return the top 5 films.

-- The CTE and subquery versions also work,
-- but the JOIN version is the clearest and most direct here.



-- Part 3

--The stores’ marketing team wants to analyze actors' inactivity periods to select those 
--with notable career breaks for targeted promotional campaigns, highlighting their comebacks 
--or consistent appearances to engage customers with nostalgic or reliable film stars 


--The task can be interpreted in various ways and here are a few options (provide solutions for each one): 

--V1: gap between the latest release_year and current year per each actor; 

--V2: gaps between sequential films per each actor




-- V1

-- Assumptions and business interpretation:

-- I understood V1 as measuring recent inactivity:
-- the number of years between the actor's latest film release_year
-- and the current year.

-- I interpreted the actor's latest release_year as the maximum release_year
-- among all films linked to that actor through film_actor.

-- I calculated the inactivity period as:
-- current_year - latest_release_year

-- I return all actors and sort them by inactivity period in descending order,
-- so the actors with the longest recent break appear first.

-- If several actors have the same inactivity period,
-- I use additional sorting by first_name and last_name in ascending order
-- to make the result stable and deterministic.


-- CTE Solution:

WITH actor_latest_release AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS latest_release_year
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
    GROUP BY
        a.actor_id,
        a.first_name,
        a.last_name
)
SELECT
    alr.first_name,
    alr.last_name,
    alr.latest_release_year,
    EXTRACT(YEAR FROM NOW()) - alr.latest_release_year AS inactivity_years
FROM actor_latest_release AS alr
ORDER BY
    inactivity_years DESC,
    alr.first_name ASC,
    alr.last_name ASC;


--Join type explanation:

--INNER JOIN between actor and film_actor keeps only actors linked to at least one film.
--INNER JOIN between film_actor and film keeps only valid film records for those actors.
--This means only actors with actual film history are included in the result.

--Advantages:

--This version is easy to read because the latest release year is calculated first and the inactivity gap is calculated after that.
--It separates the logic into clear steps.
--It is easy to explain during review.

--Disadvantages:

--It is a bit longer than necessary for this version of the task.
--For a simple calculation like this, the extra CTE is not always needed.



-- Subquery solution:

SELECT
    actor_data.first_name,
    actor_data.last_name,
    actor_data.latest_release_year,
    EXTRACT(YEAR FROM NOW()) - actor_data.latest_release_year AS inactivity_years
FROM (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS latest_release_year
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
    GROUP BY
        a.actor_id,
        a.first_name,
        a.last_name
) AS actor_data
ORDER BY
    inactivity_years DESC,
    actor_data.first_name ASC,
    actor_data.last_name ASC;


--Join type explanation:

--The joins inside the subquery connect each actor to the films they appeared in.
--INNER JOIN keeps only matching rows, so only actors with films are included.
--The outer query then calculates the inactivity period and sorts the final result.

--Advantages:

--It keeps the aggregation step separate from the final calculation.
--It is still clear and fairly easy to follow.
--It works well when the final output logic is simple.

--Disadvantages:

--It is slightly less readable than the CTE version.
--In more complex tasks, nested queries can become harder to maintain.



-- JOIN solution:

SELECT
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS latest_release_year,
    EXTRACT(YEAR FROM NOW()) - MAX(f.release_year) AS inactivity_years
FROM public.actor AS a
INNER JOIN public.film_actor AS fa
    ON a.actor_id = fa.actor_id
INNER JOIN public.film AS f
    ON fa.film_id = f.film_id
GROUP BY
    a.actor_id,
    a.first_name,
    a.last_name
ORDER BY
    inactivity_years DESC,
    a.first_name ASC,
    a.last_name ASC;


--Join type explanation:

--INNER JOIN keeps only actors who have matching film records through film_actor.
--This is the correct join type here because the task is about inactivity after acting, so actors without any films are outside this calculation.
--The query calculates the latest release year directly and then derives the inactivity gap.

--Advantages:

--This is the most direct solution.
--It is short and easy to read.
--For this version of the task, it is usually the most practical option.

--Disadvantages:

--If more business rules are added later, the query can become less readable.
--It is less structured than the CTE version.



--Which solution I would use in production:

-- For this task, I would use the JOIN solution.

-- I would choose it because it is a simple calculation:
-- find the latest release year per actor,
-- compare it with the current year,
-- and sort the result.

-- The CTE and subquery versions also work,
-- but the JOIN version is the clearest and most direct here.



-- V2

-- Assumptions and business interpretation:

-- I understood V2 as total inactivity across the actor's career.

-- I treated the gap between two sequential release years as the number of full years
-- without releases between them.

-- I calculated each gap as:
-- next_release_year - current_release_year - 1

-- If two films were released in the same year, the gap is treated as 0.

-- If two films were released in consecutive years, the gap is also treated as 0.

-- I also included the gap between the actor's latest release_year
-- and the current year.

-- For the gap between the latest release_year and the current year,
-- I counted only missing years without releases.
-- Because of that, I used:
-- current_year - latest_release_year - 1

-- I return all actors and sort them by total inactivity gap in descending order.

-- If several actors have the same total inactivity gap,
-- I use additional sorting by first_name and last_name in ascending order
-- to make the result stable and deterministic.



-- CTE Solution:

WITH actor_years AS (
    SELECT DISTINCT
        a.actor_id,
        a.first_name,
        a.last_name,
        f.release_year
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
),
next_release_years AS (
    SELECT
        ay.actor_id,
        ay.first_name,
        ay.last_name,
        ay.release_year,
        MIN(ay2.release_year) AS next_release_year
    FROM actor_years AS ay
    LEFT JOIN actor_years AS ay2
        ON ay.actor_id = ay2.actor_id
       AND ay2.release_year > ay.release_year
    GROUP BY
        ay.actor_id,
        ay.first_name,
        ay.last_name,
        ay.release_year
),
internal_gaps AS (
    SELECT
        nry.actor_id,
        nry.first_name,
        nry.last_name,
        CASE
            WHEN nry.next_release_year IS NULL THEN 0
            WHEN nry.next_release_year - nry.release_year - 1 < 0 THEN 0
            ELSE nry.next_release_year - nry.release_year - 1
        END AS gap_years
    FROM next_release_years AS nry
),
latest_release_per_actor AS (
    SELECT
        ay.actor_id,
        ay.first_name,
        ay.last_name,
        MAX(ay.release_year) AS latest_release_year
    FROM actor_years AS ay
    GROUP BY
        ay.actor_id,
        ay.first_name,
        ay.last_name
),
latest_to_current_gap AS (
    SELECT
        lra.actor_id,
        CASE
            WHEN EXTRACT(YEAR FROM NOW()) - lra.latest_release_year - 1 < 0 THEN 0
            ELSE EXTRACT(YEAR FROM NOW()) - lra.latest_release_year - 1
        END AS latest_gap_years
    FROM latest_release_per_actor AS lra
),
total_internal_gaps AS (
    SELECT
        ig.actor_id,
        ig.first_name,
        ig.last_name,
        SUM(ig.gap_years) AS total_internal_gap_years
    FROM internal_gaps AS ig
    GROUP BY
        ig.actor_id,
        ig.first_name,
        ig.last_name
)
SELECT
    tig.first_name,
    tig.last_name,
    tig.total_internal_gap_years + ltcg.latest_gap_years AS total_inactivity_years
FROM total_internal_gaps AS tig
INNER JOIN latest_to_current_gap AS ltcg
    ON tig.actor_id = ltcg.actor_id
ORDER BY
    total_inactivity_years DESC,
    tig.first_name ASC,
    tig.last_name ASC;


--Join type explanation:

--INNER JOIN between actor, film_actor and film keeps only actors who have film records.
--LEFT JOIN in next_release_years is used so that the actor’s latest release year is still kept even when there is no later film.
--INNER JOIN in the final step connects each actor’s total internal gaps with the gap from latest release year to current year.

--Advantages:

--This version is the clearest for such a complex task.
--The logic is separated into understandable steps.
--It is easier to test and explain each part one by one.
--It uses only CTEs, which makes the structure consistent.

--Disadvantages:

--It is the longest version.
--It reads like a step-by-step process, so it is more detailed than simpler tasks.
--It may feel heavier than the other versions.



-- Subquery solution:

SELECT
    actor_list.first_name,
    actor_list.last_name,
    COALESCE(SUM(gap_data.gap_years), 0)
        + CASE
            WHEN EXTRACT(YEAR FROM NOW()) - latest_data.latest_release_year - 1 < 0 THEN 0
            ELSE EXTRACT(YEAR FROM NOW()) - latest_data.latest_release_year - 1
          END AS total_inactivity_years
FROM (
    SELECT DISTINCT
        a.actor_id,
        a.first_name,
        a.last_name
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
) AS actor_list
INNER JOIN (
    SELECT
        ay.actor_id,
        MAX(ay.release_year) AS latest_release_year
    FROM (
        SELECT DISTINCT
            a.actor_id,
            f.release_year
        FROM public.actor AS a
        INNER JOIN public.film_actor AS fa
            ON a.actor_id = fa.actor_id
        INNER JOIN public.film AS f
            ON fa.film_id = f.film_id
    ) AS ay
    GROUP BY
        ay.actor_id
) AS latest_data
    ON actor_list.actor_id = latest_data.actor_id
LEFT JOIN (
    SELECT
        ay.actor_id,
        CASE
            WHEN MIN(ay2.release_year) IS NULL THEN 0
            WHEN MIN(ay2.release_year) - ay.release_year - 1 < 0 THEN 0
            ELSE MIN(ay2.release_year) - ay.release_year - 1
        END AS gap_years
    FROM (
        SELECT DISTINCT
            a.actor_id,
            f.release_year
        FROM public.actor AS a
        INNER JOIN public.film_actor AS fa
            ON a.actor_id = fa.actor_id
        INNER JOIN public.film AS f
            ON fa.film_id = f.film_id
    ) AS ay
    LEFT JOIN (
        SELECT DISTINCT
            a.actor_id,
            f.release_year
        FROM public.actor AS a
        INNER JOIN public.film_actor AS fa
            ON a.actor_id = fa.actor_id
        INNER JOIN public.film AS f
            ON fa.film_id = f.film_id
    ) AS ay2
        ON ay.actor_id = ay2.actor_id
       AND ay2.release_year > ay.release_year
    GROUP BY
        ay.actor_id,
        ay.release_year
) AS gap_data
    ON actor_list.actor_id = gap_data.actor_id
GROUP BY
    actor_list.actor_id,
    actor_list.first_name,
    actor_list.last_name,
    latest_data.latest_release_year
ORDER BY
    total_inactivity_years DESC,
    actor_list.first_name ASC,
    actor_list.last_name ASC;


--Join type explanation:

--INNER JOIN is used where actors must have film records.
--LEFT JOIN is used in the gap calculation so the latest release year is not lost when no next release exists.
--LEFT JOIN from actor list to gap data keeps actors even if they have zero internal career gaps.

--Advantages:

--It follows the same business logic as the CTE version.
--It is a valid subquery-based approach.
--It shows that the same result can be built without WITH.

--Disadvantages:

--It is much harder to read than the CTE version.
--The repeated nested subqueries make it less practical.
--It is harder to debug and maintain.



-- JOIN solution:

-- A fully separate pure JOIN-only solution is not practical here
-- because the task requires finding the next release year per actor
-- and summing all yearly gaps without using window functions.
-- Because of that, the CTE and subquery versions are the more appropriate solutions.



-- Which solution I would use in production:

-- For this task, I would use the CTE solution.

-- I would choose it because V2 has several logical steps:
-- 1. get distinct release years per actor,
-- 2. find the next release year,
-- 3. calculate the gap between sequential release years,
-- 4. sum all internal gaps,
-- 5. add the gap between the latest release year and the current year.

-- The CTE solution separates these steps clearly,
-- so it is easier to read, test, maintain and explain.


