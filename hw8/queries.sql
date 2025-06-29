-- Создайте хранимую процедуру AddNewMovie, которая добавляет новый фильм в таблицу Movie, 
-- но только если фильма с таким названием и годом выпуска еще нет в базе данных. 
-- Если фильм существует, процедура должна вывести сообщение о наличии дубля.
CREATE OR REPLACE PROCEDURE AddNewMovie(
    p_title VARCHAR(255),
    p_release_year INTEGER,
    p_genre VARCHAR(100) DEFAULT NULL,
    p_rating NUMERIC(2,1) DEFAULT NULL,
    p_duration INTEGER DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_additional_info JSONB DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM movies 
        WHERE title = p_title AND release_year = p_release_year
    ) THEN
        RAISE NOTICE 'Фильм "%" (% года) уже существует в базе данных.', p_title, p_release_year;
    ELSE
        INSERT INTO movies(title, release_year, genre, rating, duration, description, additional_info)
        VALUES (p_title, p_release_year, p_genre, p_rating, p_duration, p_description, p_additional_info);
        
        RAISE NOTICE 'Фильм "%" (% года) успешно добавлен.', p_title, p_release_year;
    END IF;
END;
$$;

-- Создайте хранимую процедуру GetCustomerRentalCount, которая принимает customer_id и возвращает количество фильмов, 
-- которые этот клиент арендовал, а также сумму всех аренд (общее количество записей).
CREATE OR REPLACE PROCEDURE GetCustomerRentalCount(
   p_customer_id INT,
   INOUT total_movies INT DEFAULT 0,
   INOUT total_rentals INT DEFAULT 0
)
LANGUAGE plpgsql
AS
$$
BEGIN
  SELECT 
    COUNT(rental_id), COUNT(DISTINCT movie_id) INTO total_rentals, total_movies
  FROM rentals
  WHERE customer_id = p_customer_id;
END;
$$

-- Создайте хранимую процедуру UpdateMovieRating, которая обновляет рейтинг фильма. 
-- Процедура должна принимать movie_id и новый рейтинг, но только если новый рейтинг находится в пределах от 0.0 до 10.0. 
-- Если рейтинг выходит за эти рамки, выведите сообщение об ошибке.
CREATE OR REPLACE PROCEDURE UpdateMovieRating(
    p_movie_id INTEGER,
    p_rating NUMERIC(2,1)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_rating < 0.0 OR p_rating > 10.0 THEN
        RAISE NOTICE 'Значение рейтинга % некорректно.', p_rating;
    ELSE
        UPDATE movies
        SET rating = p_rating
        WHERE movie_id = p_movie_id;
        
        RAISE NOTICE 'Значение рейтинга обновлено';
    END IF;
END;
$$;

-- Создайте хранимую процедуру DeleteCustomerWithLog, которая удаляет клиента из таблицы Customer, 
-- а информацию об удалении (ID клиента, email, дата удаления) записывает в лог-таблицу Customer_Deletion_Log.
CREATE TABLE customer_deletion_log (
    log_id serial NOT NULL,
    customer_id integer NOT NULL,
    email character varying(255) NOT NULL,
    deleted_at date NOT NULL,
    PRIMARY KEY (log_id)
);
CREATE TABLE rental_deletion_log (
    log_id serial NOT NULL,
    rental_id integer NOT NULL,
    customer_id integer NOT NULL,
    movie_id character varying(255) NOT NULL,
    deleted_at date NOT NULL,
    PRIMARY KEY (log_id)
);

CREATE OR REPLACE PROCEDURE DeleteCustomerWithLog(
    p_customer_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE p_email VARCHAR(255);
BEGIN
    SELECT email INTO p_email 
    FROM customers 
    WHERE customer_id = p_customer_id;

    IF EXISTS (
        SELECT 1 FROM rentals 
        WHERE customer_id = p_customer_id
    ) THEN
        INSERT INTO rental_deletion_log(rental_id, customer_id, movie_id, deleted_at)
        SELECT rental_id, customer_id, movie_id, CURRENT_DATE
        FROM rentals
        WHERE customer_id = p_customer_id;

        DELETE FROM rentals WHERE customer_id = p_customer_id;
        RAISE NOTICE 'Удалены записи клиента из таблицы аренд';
    END IF;

    IF p_email IS NOT NULL THEN
        DELETE FROM customers WHERE customer_id = p_customer_id;
        INSERT INTO customer_deletion_log(customer_id, email, deleted_at)
        VALUES (p_customer_id, p_email, CURRENT_DATE);
        RAISE NOTICE 'Клиент удален';
    ELSE
        RAISE NOTICE 'Нет такого клиента';
    END IF;
END;
$$;

-- Создайте хранимую процедуру CalculateRentalRevenue, которая рассчитывает общую выручку от аренды фильмов для указанного клиента. 
-- Процедура должна принимать customer_id в качестве параметра, 
-- подсчитывать общую сумму аренд на основе фиксированной стоимости аренды каждого фильма (например, 5 долларов за фильм) и выводить результат.
CREATE TABLE config (
    config_id serial NOT NULL,
    parameter character varying(30) NOT NULL,
    value integer NOT NULL,
    valid_from date NOT NULL,
    valid_to date,
    PRIMARY KEY (config_id)
);
INSERT INTO config(parameter, value, valid_from, valid_to) VALUES
('rental_price', 4, '2022-02-01', '2022-02-28'),
('rental_price', 5, '2022-03-01', '2022-03-31'),
('rental_price', 6, '2022-04-01', null);

CREATE OR REPLACE PROCEDURE CalculateRentalRevenue(
    p_customer_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE p_total INT;
BEGIN
    IF EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        SELECT SUM(c.value) INTO p_total
        FROM rentals r 
        LEFT JOIN config c ON c.parameter = 'rental_price' AND r.rental_date >= c.valid_from AND r.rental_date <= COALESCE(c.valid_to, '2050-01-01')
        WHERE r.customer_id = p_customer_id;

        RAISE NOTICE 'Выручка от аренды фильмов для данного клиента - %', p_total;
    ELSE
        RAISE NOTICE 'Нет такого клиента';
    END IF;
END;
$$;