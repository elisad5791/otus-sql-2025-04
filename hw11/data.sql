-- 100 актеров
INSERT INTO actors (actor_id, first_name, last_name, birth_date, nationality)
SELECT 
    gs.id,
    random_word(),
    random_word(),
    date_trunc('day', timestamp '1970-01-01' + (random() * 10000)::integer * interval '1 day'),
    random_word()
FROM generate_series(1, 100) AS gs(id);

-- 1000 фильмов
INSERT INTO movies (movie_id, title, release_year, genre, rating, duration, description, additional_info)
SELECT
    gs.id,
    random_word()||' '||random_word(),
    (1990 + random() * 35)::integer,
    CASE 
        WHEN gs.id % 10 = 0 THEN 'Sci-Fi'
        WHEN gs.id % 10 = 1 THEN 'Action'
        WHEN gs.id % 10 = 2 THEN 'Drama'
        WHEN gs.id % 10 = 3 THEN 'Romance'
        WHEN gs.id % 10 = 4 THEN 'Crime'
        WHEN gs.id % 10 = 5 THEN 'Biography'
        WHEN gs.id % 10 = 6 THEN 'Animation'
        WHEN gs.id % 10 = 7 THEN 'Mystery'
        WHEN gs.id % 10 = 8 THEN 'Adventure'
        ELSE 'Thriller'
    END,
    (7.0 + random() * 2.8)::numeric,
    (80 + random() * 60)::integer,
    random_sentence(),
    '{"languages": ["English"], "budget": 25000000, "box_office": 28341469, "director": "Frank Darabont", "awards": ["Oscar"]}'
FROM generate_series(1, 1000) AS gs(id);

-- 1000 клиентов
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, address, registration_date, preferences)
SELECT
    gs.id,
    random_word(),
    random_word(),
    random_word()||'@.mail.ru',
    '1234567890',
    '123 Main St',
    date_trunc('day', timestamp '2021-01-01' + (2200 * random())::integer * interval '1 day'), 
    '{"preferred_genres": ["Comedy"], "preferred_actors": ["Will Smith"], "newsletter": false}'
FROM generate_series(1, 1000) AS gs(id);

-- 5000 записей movie-actor
INSERT INTO movie_actors (movie_actor_id, movie_id, actor_id)
SELECT
    gs.id,
    gs.id % 1000 + 1,
    (1 + random() * 99)::integer
FROM generate_series(1, 5000) AS gs(id);

-- 10000 записей аренд
WITH cte AS (
    SELECT
        gs.id AS date_id,
        date_trunc('day', timestamp '2021-01-01' + (2200 * random())::integer * interval '1 day') AS  r_date
    FROM generate_series(1, 20000) AS gs(id)
)
INSERT INTO rentals (rental_id, customer_id, movie_id, rental_date, return_date)
SELECT
    gs.id,
    gs.id % 1000 + 1,
    (1 + random() * 999)::integer,
    cte.r_date,
    cte.r_date + (1 + random() * 10)::integer * interval '1 day'
FROM generate_series(1, 20000) AS gs(id)
LEFT JOIN cte ON cte.date_id = gs.id;    