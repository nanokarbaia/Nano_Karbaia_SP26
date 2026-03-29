-- TASK 1 / SUBTASK 1
-- Add my top-3 favorite movies to public.film


-- Why a separate transaction is used:
-- This subtask inserts new rows into public.film.
-- A separate transaction keeps this step isolated from the next subtasks,
-- so it is easier to test, validate and roll back if needed.

-- What would happen if the transaction fails:
-- If the transaction fails before COMMIT, PostgreSQL will roll back the whole subtask,
-- and none of these film rows will remain inserted.

-- Whether rollback is possible and what data would be affected:
-- Yes, rollback is possible before COMMIT.
-- Only the rows inserted in this transaction into public.film would be affected.

-- How referential integrity is preserved:
-- language_id is selected from public.language,
-- so films are inserted only with an existing parent row from the language table.
-- This keeps the foreign key relationship valid.

-- How this script avoids duplicates:
-- The script uses WHERE NOT EXISTS for each film title,
-- so rerunning it does not insert the same movie twice.

-- How data uniqueness is ensured:
-- I check film title before inserting a row.
-- If a film with the same title already exists, it is skipped.
-- This makes the script reusable and prevents duplicate film records.

-- How relationships between tables are established:
-- The relationship between public.film and public.language is established
-- by selecting language_id from public.language for ENGLISH
-- and inserting it into public.film.language_id.

-- Why INSERT INTO ... SELECT is used instead of INSERT INTO ... VALUES:
-- INSERT INTO ... SELECT makes it easier to:
-- 1. read related values from existing tables
-- 2. avoid hardcoding foreign key IDs
-- 3. add rerunnable logic with WHERE NOT EXISTS

BEGIN;

WITH films AS (
    SELECT
        'INTERSTELLAR'::text AS title,
        'A team of explorers travel through a wormhole in space in an attempt to ensure humanity''s survival.'::text AS description,
        2014::public."year" AS release_year,
        7::int2 AS rental_duration,
        4.99::numeric(4,2) AS rental_rate,
        169::int2 AS length,
        19.99::numeric(5,2) AS replacement_cost,
        'PG-13'::public.mpaa_rating AS rating,
        ARRAY['Trailers','Behind the Scenes']::text[] AS special_features

    UNION ALL

    SELECT
        'MAMMA MIA!'::text AS title,
        'The story of a bride-to-be trying to find her real father told using hit songs by ABBA.'::text AS description,
        2008::public."year" AS release_year,
        14::int2 AS rental_duration,
        9.99::numeric(4,2) AS rental_rate,
        108::int2 AS length,
        19.99::numeric(5,2) AS replacement_cost,
        'PG-13'::public.mpaa_rating AS rating,
        ARRAY['Trailers','Deleted Scenes']::text[] AS special_features

    UNION ALL

    SELECT
        'PRETTY WOMAN'::text AS title,
        'A businessman and a Hollywood escort form an unexpected bond that changes both of their lives.'::text AS description,
        1990::public."year" AS release_year,
        21::int2 AS rental_duration,
        19.99::numeric(4,2) AS rental_rate,
        119::int2 AS length,
        19.99::numeric(5,2) AS replacement_cost,
        'R'::public.mpaa_rating AS rating,
        ARRAY['Trailers']::text[] AS special_features
)
INSERT INTO public.film (
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    last_update,
    special_features
)
SELECT
    f.title,
    f.description,
    f.release_year,
    l.language_id,
    f.rental_duration,
    f.rental_rate,
    f.length,
    f.replacement_cost,
    f.rating,
    CURRENT_TIMESTAMP::timestamptz,
    f.special_features
FROM films AS f
INNER JOIN public.language AS l
    ON UPPER(TRIM(l.name::text)) = 'ENGLISH'
WHERE NOT EXISTS (
    SELECT 1
    FROM public.film AS f1
    WHERE UPPER(f1.title) = UPPER(f.title)
)
RETURNING
    film_id,
    title,
    release_year,
    rental_duration,
    rental_rate,
    last_update;

COMMIT;



-- TASK 1 / SUBTASK 2
-- Add real actors who play leading roles in my favorite movies
-- to public.actor and public.film_actor


-- Why a separate transaction is used:
-- This subtask inserts parent rows into public.actor
-- and then child rows into public.film_actor.
-- Keeping both steps in one transaction ensures that the relationship table
-- is filled only together with valid actor records.

-- What would happen if the transaction fails:
-- If any part of this transaction fails before COMMIT,
-- PostgreSQL will roll back both actor inserts and film_actor inserts.
-- This prevents partial data loading.

-- Whether rollback is possible and what data would be affected:
-- Yes, rollback is possible before COMMIT.
-- In that case, the rows inserted into public.actor and public.film_actor
-- in this transaction would be undone.

-- How referential integrity is preserved:
-- film_actor rows are inserted only after matching actor_id values
-- are found in public.actor and matching film_id values are found in public.film.
-- This preserves both foreign key relationships:
-- public.film_actor.actor_id -> public.actor.actor_id
-- public.film_actor.film_id  -> public.film.film_id

-- How this script avoids duplicates:
-- For public.actor, the script checks first_name + last_name before insert.
-- For public.film_actor, the script checks the (actor_id, film_id) pair before insert.
-- This makes the script rerunnable.

-- How data uniqueness is ensured:
-- Actor uniqueness is identified by first_name and last_name.
-- Film-actor relationship uniqueness is identified by the combination
-- of actor_id and film_id.

-- How relationships between tables are established:
-- First, actors are inserted into public.actor if they do not already exist.
-- Then actor_id is taken from public.actor and film_id is taken from public.film,
-- and both are inserted into public.film_actor to connect actors with movies.

-- Why INSERT INTO ... SELECT is used instead of INSERT INTO ... VALUES:
-- INSERT INTO ... SELECT makes it easier to:
-- 1. avoid hardcoding IDs
-- 2. connect data from existing tables
-- 3. keep the script rerunnable with WHERE NOT EXISTS

BEGIN;

-- ---------------------------------------------------------
-- Step 1. Insert missing actors into public.actor
-- ---------------------------------------------------------

WITH actors AS (
    SELECT
        'JESSICA'::text AS first_name,
        'CHASTAIN'::text AS last_name
    UNION ALL
    SELECT 'MATTHEW'::text, 'MCCONAUGHEY'::text
    UNION ALL
    SELECT 'TIMOTHEE'::text, 'CHALAMET'::text
    UNION ALL
    SELECT 'AMANDA'::text, 'SEYFRIED'::text
    UNION ALL
    SELECT 'MERYL'::text, 'STREEP'::text
    UNION ALL
    SELECT 'JULIA'::text, 'ROBERTS'::text
    UNION ALL
    SELECT 'RICHARD'::text, 'GERE'::text
)
INSERT INTO public.actor (
    first_name,
    last_name,
    last_update
)
SELECT
    a.first_name,
    a.last_name,
    CURRENT_TIMESTAMP::timestamptz
FROM actors AS a
WHERE NOT EXISTS (
    SELECT 1
    FROM public.actor AS a1
    WHERE UPPER(a1.first_name) = UPPER(a.first_name)
      AND UPPER(a1.last_name) = UPPER(a.last_name)
)
RETURNING
    actor_id,
    first_name,
    last_name,
    last_update;


-- Step 2. Insert links into public.film_actor

WITH actor_movie_pairs AS (
    SELECT
        'INTERSTELLAR'::text AS film_title,
        'JESSICA'::text AS first_name,
        'CHASTAIN'::text AS last_name
    UNION ALL
    SELECT 'INTERSTELLAR', 'MATTHEW', 'MCCONAUGHEY'
    UNION ALL
    SELECT 'INTERSTELLAR', 'TIMOTHEE', 'CHALAMET'
    UNION ALL
    SELECT 'MAMMA MIA!', 'AMANDA', 'SEYFRIED'
    UNION ALL
    SELECT 'MAMMA MIA!', 'MERYL', 'STREEP'
    UNION ALL
    SELECT 'PRETTY WOMAN', 'JULIA', 'ROBERTS'
    UNION ALL
    SELECT 'PRETTY WOMAN', 'RICHARD', 'GERE'
)
INSERT INTO public.film_actor (
    actor_id,
    film_id,
    last_update
)
SELECT
    a.actor_id,
    f.film_id,
    CURRENT_TIMESTAMP::timestamptz
FROM actor_movie_pairs AS amp
INNER JOIN public.actor AS a
    ON UPPER(a.first_name) = UPPER(amp.first_name)
   AND UPPER(a.last_name) = UPPER(amp.last_name)
INNER JOIN public.film AS f
    ON UPPER(f.title) = UPPER(amp.film_title)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.film_actor AS fa
    WHERE fa.actor_id = a.actor_id
      AND fa.film_id = f.film_id
)
RETURNING
    actor_id,
    film_id,
    last_update;

COMMIT;


-- TASK 1 / SUBTASK 3
-- Add my favorite movies to a store's inventory


-- Why a separate transaction is used:
-- This subtask inserts new rows into public.inventory.
-- A separate transaction keeps this step isolated from other inserts,
-- so it is easier to validate and roll back if needed.

-- What would happen if the transaction fails:
-- If the transaction fails before COMMIT, PostgreSQL will roll back
-- all inserted inventory rows from this subtask.

-- Whether rollback is possible and what data would be affected:
-- Yes, rollback is possible before COMMIT.
-- Only the rows inserted into public.inventory in this transaction
-- would be affected.

-- How referential integrity is preserved:
-- film_id is selected from public.film and store_id is selected from public.store,
-- so inventory rows are inserted only with existing parent rows.

-- How this script avoids duplicates:
-- The script checks whether the same film already exists in the chosen store's inventory.
-- If it already exists, it is skipped.

-- How data uniqueness is ensured:
-- I identify uniqueness here by the combination of film_id and store_id,
-- because the goal of this subtask is to make sure each selected movie
-- is present in at least one store's inventory.

-- How relationships between tables are established:
-- The relationship is established by inserting existing film_id values
-- from public.film and an existing store_id from public.store into public.inventory.

-- Why INSERT INTO ... SELECT is used instead of INSERT INTO ... VALUES:
-- INSERT INTO ... SELECT makes it easier to:
-- 1. avoid hardcoding IDs
-- 2. select existing parent rows from related tables
-- 3. make the script rerunnable with WHERE NOT EXISTS

BEGIN;

WITH selected_store AS (
    SELECT
        s.store_id
    FROM public.store AS s
    ORDER BY s.store_id
    LIMIT 1
),
favorite_films AS (
    SELECT
        f.film_id,
        f.title
    FROM public.film AS f
    WHERE UPPER(f.title) IN ('INTERSTELLAR', 'MAMMA MIA!', 'PRETTY WOMAN')
)
INSERT INTO public.inventory (
    film_id,
    store_id,
    last_update
)
SELECT
    ff.film_id,
    ss.store_id,
    CURRENT_TIMESTAMP::timestamptz
FROM favorite_films AS ff
INNER JOIN selected_store AS ss
    ON 1 = 1
WHERE NOT EXISTS (
    SELECT 1
    FROM public.inventory AS i
    WHERE i.film_id = ff.film_id
      AND i.store_id = ss.store_id
)
RETURNING
    inventory_id,
    film_id,
    store_id,
    last_update;


COMMIT;



-- TASK 1 / SUBTASK 4
-- Update an existing customer with at least 43 rental and 43 payment records
-- and change their personal data to mine


-- Why a separate transaction is used:
-- This subtask updates one row in public.customer.
-- A separate transaction makes it easier to validate the selected customer
-- before committing the change.

-- What would happen if the transaction fails:
-- If the transaction fails before COMMIT, PostgreSQL will roll back the update
-- and the customer data will remain unchanged.

-- Whether rollback is possible and what data would be affected:
-- Yes, rollback is possible before COMMIT.
-- Only the updated row in public.customer would be affected.

-- How referential integrity is preserved:
-- I do not update the public.address table itself.
-- Instead, I assign an existing address_id from public.address to the customer.
-- This keeps the foreign key from public.customer.address_id valid.

-- How this script avoids duplicates:
-- To keep it reusable, the script first checks whether a customer has already
-- been updated to my data. If yes, it updates the same customer again instead
-- of selecting a different one.

-- How data uniqueness is ensured:
-- The script updates only one customer row.
-- It first tries to find the customer already updated to my name.
-- If such a customer does not exist, it selects one eligible customer
-- with at least 43 rentals and 43 payments.

-- How relationships between tables are established:
-- The relationship to public.address is preserved by assigning an existing address_id.
-- No child rows are inserted or removed in this subtask.

-- Why UPDATE ... FROM / CTE-based selection is used:
-- This approach makes it possible to:
-- 1. choose the target customer dynamically
-- 2. avoid hardcoding customer_id or address_id
-- 3. make the script rerunnable

BEGIN;

WITH existing_me AS (
    SELECT
        c.customer_id
    FROM public.customer AS c
    WHERE UPPER(c.first_name) = 'NANO'
      AND UPPER(c.last_name) = 'KARBAIA'
    ORDER BY c.customer_id
    LIMIT 1
),
eligible_customers AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT r.rental_id) AS rental_count,
        COUNT(DISTINCT p.payment_id) AS payment_count
    FROM public.customer AS c
    INNER JOIN public.rental AS r
        ON c.customer_id = r.customer_id
    INNER JOIN public.payment AS p
        ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43
       AND COUNT(DISTINCT p.payment_id) >= 43
),
fallback_customer AS (
    SELECT
        ec.customer_id
    FROM eligible_customers AS ec
    ORDER BY ec.customer_id
    LIMIT 1
),
target_customer AS (
    SELECT customer_id
    FROM existing_me

    UNION ALL

    SELECT fc.customer_id
    FROM fallback_customer AS fc
    WHERE NOT EXISTS (
        SELECT 1
        FROM existing_me
    )
),
selected_address AS (
    SELECT
        a.address_id
    FROM public.address AS a
    ORDER BY a.address_id
    LIMIT 1
)
UPDATE public.customer AS c
SET
    first_name = 'NANO',
    last_name = 'KARBAIA',
    email = 'NANO.KARBAIA@sakilacustomer.org',
    address_id = sa.address_id,
    last_update = CURRENT_TIMESTAMP::timestamptz
FROM target_customer AS tc
INNER JOIN selected_address AS sa
    ON 1 = 1
WHERE c.customer_id = tc.customer_id
RETURNING
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.address_id,
    c.last_update;


COMMIT;



-- TASK 1 / SUBTASK 5
-- Remove any records related to me as a customer
-- from all tables except public.customer and public.inventory


-- Why a separate transaction is used:
-- This subtask deletes data from transactional tables.
-- A separate transaction makes it easier to validate the rows to be deleted
-- before committing the change.

-- What would happen if the transaction fails:
-- If the transaction fails before COMMIT, PostgreSQL will roll back all deletes
-- from this subtask and no data will be permanently removed.

-- Whether rollback is possible and what data would be affected:
-- Yes, rollback is possible before COMMIT.
-- Only rows deleted from public.payment and public.rental in this transaction
-- would be affected.

-- Why deleting from tables is safe:
-- This delete is limited only to records related to me as a customer.
-- It does not delete from public.customer or public.inventory,
-- as required in the task.

-- How referential integrity is preserved:
-- I delete from public.payment first and then from public.rental.
-- This order is safe because payment records reference customer and rental activity,
-- while rental records reference customer and inventory.
-- The customer row itself remains unchanged.

-- How this script avoids unintended data loss:
-- The target customer is identified explicitly by first_name and last_name.
-- All DELETE statements are filtered by that customer only.
-- Validation SELECT queries are included before COMMIT.

-- How this script avoids duplicates / remains reusable:
-- DELETE is naturally rerunnable here.
-- If the same rows were already removed, rerunning the script simply deletes zero rows.

BEGIN;

-- Validation before delete
-- Check which rows belong to me as a customer


WITH my_customer AS (
    SELECT
        c.customer_id
    FROM public.customer AS c
    WHERE UPPER(c.first_name) = 'NANO'
      AND UPPER(c.last_name) = 'KARBAIA'
)
SELECT
    'PAYMENT' AS table_name,
    COUNT(*) AS row_count
FROM public.payment AS p
INNER JOIN my_customer AS mc
    ON p.customer_id = mc.customer_id

UNION ALL

SELECT
    'RENTAL' AS table_name,
    COUNT(*) AS row_count
FROM public.rental AS r
INNER JOIN my_customer AS mc
    ON r.customer_id = mc.customer_id;


-- Step 1. Delete payment records related to me as a customer


WITH my_customer AS (
    SELECT
        c.customer_id
    FROM public.customer AS c
    WHERE UPPER(c.first_name) = 'NANO'
      AND UPPER(c.last_name) = 'KARBAIA'
)
DELETE FROM public.payment AS p
USING my_customer AS mc
WHERE p.customer_id = mc.customer_id
RETURNING
    p.payment_id,
    p.customer_id,
    p.rental_id,
    p.amount,
    p.payment_date;

-- ---------------------------------------------------------
-- Step 2. Delete rental records related to me as a customer
-- ---------------------------------------------------------

WITH my_customer AS (
    SELECT
        c.customer_id
    FROM public.customer AS c
    WHERE UPPER(c.first_name) = 'NANO'
      AND UPPER(c.last_name) = 'KARBAIA'
)
DELETE FROM public.rental AS r
USING my_customer AS mc
WHERE r.customer_id = mc.customer_id
RETURNING
    r.rental_id,
    r.customer_id,
    r.inventory_id,
    r.rental_date,
    r.return_date;


-- Validation after delete, before commit
-- Confirm that no payment or rental rows remain for me


WITH my_customer AS (
    SELECT
        c.customer_id
    FROM public.customer AS c
    WHERE UPPER(c.first_name) = 'NANO'
      AND UPPER(c.last_name) = 'KARBAIA'
)
SELECT
    'PAYMENT' AS table_name,
    COUNT(*) AS row_count
FROM public.payment AS p
INNER JOIN my_customer AS mc
    ON p.customer_id = mc.customer_id

UNION ALL

SELECT
    'RENTAL' AS table_name,
    COUNT(*) AS row_count
FROM public.rental AS r
INNER JOIN my_customer AS mc
    ON r.customer_id = mc.customer_id;

COMMIT;



-- TASK 1 / SUBTASK 6
-- Rent my favorite movies from the store they are in
-- and add matching payment records


-- Why a separate transaction is used:
-- This subtask inserts rows into public.rental and public.payment.
-- A separate transaction keeps these related changes together,
-- so either both rentals and payments are inserted successfully,
-- or neither of them is saved.

-- What would happen if the transaction fails:
-- If the transaction fails before COMMIT, PostgreSQL will roll back
-- both the rental inserts and the payment inserts.

-- Whether rollback is possible and what data would be affected:
-- Yes, rollback is possible before COMMIT.
-- Only rows inserted into public.rental and public.payment
-- in this transaction would be affected.

-- How referential integrity is preserved:
-- rental rows are inserted only with existing inventory_id, customer_id and staff_id values.
-- payment rows are inserted only for rental rows that exist.
-- This preserves the foreign key relationships.

-- How this script avoids duplicates:
-- For rental, the script checks whether the same customer already rented
-- the same inventory item at the same rental_date.
-- For payment, the script checks whether a payment already exists
-- for the same customer, staff, rental, amount and payment_date.

-- How data uniqueness is ensured:
-- Rental uniqueness is based on the business event:
-- customer + inventory item + rental_date.
-- Payment uniqueness is based on the inserted rental and payment details.

-- How relationships between tables are established:
-- The relationship to public.rental is established by selecting:
-- 1. inventory_id from public.inventory
-- 2. customer_id from public.customer
-- 3. staff_id from the same store as the inventory item
-- Then public.payment is linked to the inserted rental row through rental_id.

-- Why INSERT INTO ... SELECT is used instead of INSERT INTO ... VALUES:
-- INSERT INTO ... SELECT makes it possible to:
-- 1. avoid hardcoding IDs
-- 2. select valid parent rows from existing tables
-- 3. keep the script rerunnable with NOT EXISTS logic

BEGIN;

-- Step 1. Insert rental records


WITH my_customer AS (
    SELECT
        c.customer_id
    FROM public.customer AS c
    WHERE UPPER(c.first_name) = 'NANO'
      AND UPPER(c.last_name) = 'KARBAIA'
    ORDER BY c.customer_id
    LIMIT 1
),
favorite_inventory AS (
    SELECT
        f.title,
        MIN(i.inventory_id) AS inventory_id
    FROM public.film AS f
    INNER JOIN public.inventory AS i
        ON f.film_id = i.film_id
    WHERE UPPER(f.title) IN ('INTERSTELLAR', 'MAMMA MIA!', 'PRETTY WOMAN')
    GROUP BY
        f.title
),
inventory_with_store AS (
    SELECT
        fi.title,
        i.inventory_id,
        i.store_id
    FROM favorite_inventory AS fi
    INNER JOIN public.inventory AS i
        ON fi.inventory_id = i.inventory_id
),
staff_per_store AS (
    SELECT
        st.store_id,
        MIN(st.staff_id) AS staff_id
    FROM public.staff AS st
    GROUP BY
        st.store_id
),
rentals_to_add AS (
    SELECT
        iws.title,
        iws.inventory_id,
        mc.customer_id,
        sps.staff_id,
        CASE
            WHEN UPPER(iws.title) = 'INTERSTELLAR'
                THEN TIMESTAMPTZ '2017-05-15 12:40:33.000 +0400'
            WHEN UPPER(iws.title) = 'MAMMA MIA!'
                THEN TIMESTAMPTZ '2017-05-16 20:00:00.000 +0400'
            WHEN UPPER(iws.title) = 'PRETTY WOMAN'
                THEN TIMESTAMPTZ '2017-05-17 16:00:00.000 +0400'
        END AS rental_date,
        CASE
            WHEN UPPER(iws.title) = 'INTERSTELLAR'
                THEN TIMESTAMPTZ '2017-05-22 20:40:33.000 +0400'
            WHEN UPPER(iws.title) = 'MAMMA MIA!'
                THEN TIMESTAMPTZ '2017-05-30 20:00:00.000 +0400'
            WHEN UPPER(iws.title) = 'PRETTY WOMAN'
                THEN TIMESTAMPTZ '2017-06-07 16:00:00.000 +0400'
        END AS return_date
    FROM inventory_with_store AS iws
    INNER JOIN staff_per_store AS sps
        ON iws.store_id = sps.store_id
    INNER JOIN my_customer AS mc
        ON 1 = 1
)
INSERT INTO public.rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id,
    last_update
)
SELECT
    rta.rental_date,
    rta.inventory_id,
    rta.customer_id,
    rta.return_date,
    rta.staff_id,
    CURRENT_TIMESTAMP::timestamptz
FROM rentals_to_add AS rta
WHERE NOT EXISTS (
    SELECT 1
    FROM public.rental AS r
    WHERE r.rental_date = rta.rental_date
      AND r.inventory_id = rta.inventory_id
      AND r.customer_id = rta.customer_id
)
RETURNING
    rental_id,
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id,
    last_update;


-- Step 2. Insert payment records for these rentals


WITH my_customer AS (
    SELECT
        c.customer_id
    FROM public.customer AS c
    WHERE UPPER(c.first_name) = 'NANO'
      AND UPPER(c.last_name) = 'KARBAIA'
    ORDER BY c.customer_id
    LIMIT 1
),
my_rentals AS (
    SELECT
        r.rental_id,
        r.customer_id,
        r.staff_id,
        r.rental_date,
        f.title,
        f.rental_rate
    FROM public.rental AS r
    INNER JOIN public.inventory AS i
        ON r.inventory_id = i.inventory_id
    INNER JOIN public.film AS f
        ON i.film_id = f.film_id
    INNER JOIN my_customer AS mc
        ON r.customer_id = mc.customer_id
    WHERE UPPER(f.title) IN ('INTERSTELLAR', 'MAMMA MIA!', 'PRETTY WOMAN')
      AND r.rental_date IN (
          TIMESTAMPTZ '2017-05-15 12:40:33.000 +0400',
          TIMESTAMPTZ '2017-05-16 20:00:00.000 +0400',
          TIMESTAMPTZ '2017-05-17 16:00:00.000 +0400'
      )
),
payments_to_add AS (
    SELECT
        mr.customer_id,
        mr.staff_id,
        mr.rental_id,
        mr.rental_rate AS amount,
        mr.rental_date AS payment_date
    FROM my_rentals AS mr
)
INSERT INTO public.payment (
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date
)
SELECT
    pta.customer_id,
    pta.staff_id,
    pta.rental_id,
    pta.amount,
    pta.payment_date
FROM payments_to_add AS pta
WHERE NOT EXISTS (
    SELECT 1
    FROM public.payment AS p
    WHERE p.customer_id = pta.customer_id
      AND p.staff_id = pta.staff_id
      AND p.rental_id = pta.rental_id
      AND p.amount = pta.amount
      AND p.payment_date = pta.payment_date
)
RETURNING
    payment_id,
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date;


COMMIT;
