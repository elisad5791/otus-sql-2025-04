-- 1. Напишите запрос, который выводит список фильмов вместе с именами и фамилиями актеров, сыгравших в них. 
--    Отсортируйте результат по названию фильма и фамилии актера.
SELECT m.title, a.first_name, a.last_name
FROM movies m
JOIN movie_actors ma USING(movie_id)
JOIN actors a USING(actor_id)
ORDER BY m.title, a.last_name;

-- 2. Напишите запрос, который выводит список всех клиентов и, если они совершали аренды, то укажите дату последней аренды. 
--    Если клиент не совершал аренды, дата аренды должна быть NULL.
SELECT c.first_name, c.last_name, MAX(r.rental_date) as last_rental
FROM customers c
LEFT JOIN rentals r USING(customer_id)
GROUP BY c.customer_id
ORDER BY 3 DESC NULLS LAST;

-- 3. Напишите запрос, который выводит название фильмов, чья продолжительность больше средней продолжительности всех фильмов в базе данных.
SELECT title, duration
FROM movies
WHERE duration > (SELECT AVG(duration) FROM movies)
ORDER BY duration DESC;

-- 4. Используя CTE, напишите запрос, который вычисляет количество аренд для каждого жанра и выводит жанры с общим количеством аренд, отсортированных по количеству аренд в порядке убывания.
WITH genre_rental AS (
	SELECT m.genre, COUNT(*) AS rental_count
	FROM movies m
	LEFT JOIN rentals r USING(movie_id)
	GROUP BY m.genre
)
SELECT * 
FROM genre_rental
ORDER BY rental_count DESC;

-- 5. Напишите запрос, который выводит список всех уникальных имен актеров и клиентов в одном столбце. 
--    Укажите, что это за тип лица с помощью дополнительного столбца (например, ""Актер"" или ""Клиент"").
SELECT first_name, 'Customer' AS type FROM customers
UNION 
SELECT first_name, 'Actor' AS type FROM actors
ORDER BY type;