-- Создайте функцию GetMovieDurationInHours, которая принимает movie_id в качестве параметра 
-- и возвращает продолжительность фильма в часах (округленную до двух знаков после запятой).
CREATE OR REPLACE FUNCTION GetMovieDurationInHours(f_movie_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE 
    duration_minutes NUMERIC;
    duration_hours NUMERIC;
BEGIN
    SELECT duration INTO duration_minutes FROM movies WHERE movie_id = f_movie_id;
    duration_hours := ROUND(duration_minutes / 60, 2);
    RETURN duration_hours;
END;
$$;

-- Создайте функцию GetMoviesByDirector, которая принимает имя режиссера в качестве параметра и возвращает таблицу с названием фильма, 
-- годом выпуска и жанром для всех фильмов этого режиссера.
CREATE OR REPLACE FUNCTION GetMoviesByDirector(f_director_name VARCHAR)
RETURNS TABLE(movie_title VARCHAR, movie_release_year INT, movie_genre VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY 
    SELECT title AS movie_title, release_year AS movie_release_year, genre AS movie_genre
    FROM movies
    WHERE additional_info->>'director' = f_director_name;
END;
$$;

-- Создайте функцию CalculateCustomerRentalCost, которая принимает customer_id и возвращает общую стоимость всех аренд этого клиента, 
-- основываясь на фиксированной цене аренды одного фильма (например, 5 долларов).
CREATE OR REPLACE FUNCTION CalculateCustomerRentalCost(f_customer_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE 
    rental_count INT;
    rental_cost INT;
BEGIN
    SELECT COUNT(rental_id) INTO rental_count FROM rentals WHERE customer_id = f_customer_id;
    rental_cost := 5 * rental_count;
    RETURN rental_cost;
END;
$$;

-- Создайте функцию GetCustomerStatus, которая принимает customer_id и возвращает статус клиента в зависимости от количества аренд.
-- Если клиент арендовал более 10 фильмов, вернуть статус 'VIP'.
-- Если клиент арендовал от 5 до 10 фильмов, вернуть статус 'Regular'.
-- Если клиент арендовал менее 5 фильмов, вернуть статус 'Newbie'.
CREATE OR REPLACE FUNCTION GetCustomerStatus(f_customer_id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE 
    rental_count INT;
BEGIN
    SELECT COUNT(rental_id) INTO rental_count FROM rentals WHERE customer_id = f_customer_id;
    IF rental_count < 5 THEN
        RETURN 'Newbie';
    ELSIF rental_count <= 10 THEN
        RETURN 'Regular';
    ELSE 
        RETURN 'VIP';
	END IF;
END;
$$;

-- Создайте функцию GetMostPopularGenre, которая возвращает жанр, по которому арендовали больше всего фильмов.
-- Функция не принимает параметров и возвращает строку с названием самого популярного жанра.
CREATE OR REPLACE FUNCTION GetMostPopularGenre()
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE 
    genre_name VARCHAR;
BEGIN
    SELECT m.genre INTO genre_name
    FROM movies m
    LEFT JOIN rentals r on r.movie_id = m.movie_id
    GROUP BY m.genre
    ORDER BY COUNT(r.rental_id) DESC
    LIMIT 1;

    RETURN genre_name;
END;
$$;