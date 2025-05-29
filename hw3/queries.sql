-- 1. Напишите запрос, который выводит список фильмов, где рейтинг является NULL, и заменяет NULL на значение 0.
SELECT movie_id, title, COALESCE(rating, 0.0) AS normalized_rating
FROM movies
WHERE rating IS NULL;

-- 2. Напишите запрос, который выводит название фильма и округленное вверх значение рейтинга до ближайшего целого числа.
SELECT title, CEIL(rating) AS normalized_rating
FROM movies;

-- 3. Выведите список клиентов, которые зарегистрировались в последний месяц.
SELECT *
FROM customers
WHERE 
	DATE_PART('year', registration_date) = DATE_PART('year', now()) AND 
	DATE_PART('month', registration_date) = DATE_PART('month', now());

-- 4. Выведите количество дней, в течение которых каждый клиент держал у себя фильм.
SELECT 
	r.rental_id, 
	c.first_name||' '||c.last_name AS customer_name, 
	m.title AS movie_title, 
	return_date - rental_date as rental_period
FROM rentals r
LEFT JOIN customers c ON c.customer_id=r.customer_id
LEFT JOIN movies m ON m.movie_id=r.movie_id
ORDER BY r.rental_id;

-- 5. Напишите запрос, который выводит название фильма в верхнем регистре.
SELECT movie_id, UPPER(title) AS title_upper
FROM movies
ORDER BY movie_id;

-- 6. Выведите первые 50 символов описания фильма.
SELECT movie_id, title, LEFT(description, 50) AS short_description
FROM movies
ORDER BY movie_id;

-- 7. Напишите запрос, который выводит жанр и общее количество фильмов в каждом жанре.
SELECT genre, COUNT(*) AS quantity
FROM movies
GROUP BY genre;

-- 8. Напишите запрос, который выводит название фильма, его рейтинг и место в рейтинге по убыванию рейтинга.
SELECT title, rating, ROW_NUMBER() OVER (ORDER BY rating DESC) AS rating_number
FROM movies;

-- 9. Напишите запрос, который выводит название фильма, его рейтинг и рейтинг предыдущего фильма в списке по убыванию рейтинга.
SELECT title, rating, LAG(rating) OVER (ORDER BY rating DESC) as previous_rating
FROM movies;

-- 10. Напишите запрос, который для каждого жанра выводит средний рейтинг фильмов в этом жанре, округленный до двух знаков после запятой.
SELECT genre, round(AVG(rating), 2) AS genre_average_rating
FROM movies
GROUP BY genre
ORDER BY 2 DESC;