-- Создайте представление CustomerMovieRentalView, которое объединяет информацию о клиентах и фильмах, которые они брали в аренду. 
CREATE VIEW CustomerMovieRentalView AS
SELECT
  r.rental_id,
  r.rental_date,
  r.return_date,
  c.first_name||' '||c.last_name AS customer_name,
  c.email AS customer_email,
  m.title AS movie_title,
  m.genre AS movie_genre
FROM rentals r
LEFT JOIN customers c ON c.customer_id = r.customer_id 
LEFT JOIN movies m ON m.movie_id = r.movie_id;

-- Напишите запрос, который покажет все фильмы, взятые в аренду клиентами в марте 2022 года, используя созданное представление.
SELECT DISTINCT movie_title
FROM CustomerMovieRentalView
WHERE rental_date BETWEEN '2022-03-01' AND '2022-04-01';

-- Создайте триггер, который автоматически обновляет поле rental_date в таблице Rental на текущую дату, если пользователь пытается вставить запись с пустым значением rental_date. 
-- Используйте BEFORE INSERT триггер.
CREATE OR REPLACE FUNCTION check_rental_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.rental_date IS NULL THEN
        NEW.rental_date = CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rental_date_trigger
BEFORE INSERT ON rentals
FOR EACH ROW
EXECUTE FUNCTION check_rental_date();

-- Создайте триггер, который предотвращает удаление записей о фильмах, если они связаны с таблицей Rental. 
-- Используйте BEFORE DELETE триггер
CREATE OR REPLACE FUNCTION check_rental_table()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT rental_id FROM rentals WHERE movie_id = OLD.movie_id) THEN
      RAISE EXCEPTION 'Deletion is not allowed. There are data in rentals table';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_movie_trigger
BEFORE DELETE ON movies
FOR EACH ROW
EXECUTE FUNCTION check_rental_table();

-- Создайте последовательность actor_sequence, которая будет генерировать уникальные значения для новых актеров. 
-- Начальное значение должно быть 1000, шаг увеличения — 1.
CREATE SEQUENCE actor_sequence START WITH 1000 INCREMENT BY 1;

-- Добавьте нового актера в таблицу Actor, используя значение из созданной последовательности для поля actor_id
INSERT INTO actors (actor_id, first_name, last_name, birth_date, nationality)
VALUES (nextval('actor_sequence'), 'John', 'Doe', '2000-01-01', 'American');

-- Обновите последовательность, чтобы начальное значение было на 10 больше последнего созданного значения. 
-- Проверьте изменение.
SELECT setval('actor_sequence', (SELECT last_value FROM actor_sequence) + 10);
SELECT nextval('actor_sequence') AS current_value;

-- Создайте триггер, который при обновлении поля return_date в таблице Rental устанавливает текущую дату, если поле NULL, 
-- и оставляет значение без изменений, если оно больше текущей даты.
CREATE OR REPLACE FUNCTION check_return_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.return_date IS NULL THEN 
      NEW.return_date = CURRENT_DATE;
    END IF;
    IF OLD.return_date > CURRENT_DATE THEN 
      NEW.return_date = OLD.return_date;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER return_date_trigger
BEFORE UPDATE ON rentals
FOR EACH ROW
EXECUTE FUNCTION check_return_date();

-- Создайте триггер, который будет записывать информацию о каждом удалении записи из таблицы Customer в отдельную таблицу Customer_Deletion_Log. 
-- Запись должна включать ID клиента, дату удаления и email клиента.
CREATE TABLE customer_deletion_log (
    log_id serial NOT NULL,
    customer_id integer NOT NULL,
    email character varying(255) NOT NULL,
    deleted_at date NOT NULL,
    PRIMARY KEY (log_id)
);

CREATE OR REPLACE FUNCTION write_delete_info()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO customer_deletion_log(customer_id, email, deleted_at)
    VALUES (OLD.customer_id, OLD.email, CURRENT_DATE);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_customer_trigger
BEFORE DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION write_delete_info();

-- Создайте триггер, который после добавления новой записи в таблицу Movie автоматически будет увеличивать 
-- количество фильмов данного жанра в таблице Genre_Statistics. 
-- Если запись о жанре уже существует, увеличьте счетчик на 1; если не существует, создайте новую запись для этого жанра.
CREATE TABLE genre_statistics (
    statistics_id serial NOT NULL,
    genre character varying(100) NOT NULL,
    count integer NOT NULL,
    PRIMARY KEY (statistics_id)
);

CREATE OR REPLACE FUNCTION update_genre_statistics()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM genre_statistics WHERE genre = NEW.genre) THEN
      UPDATE genre_statistics SET count = count + 1 WHERE genre = NEW.genre;
    ELSE
      INSERT INTO genre_statistics(genre, count) VALUES (NEW.genre, 1);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER genre_trigger
AFTER INSERT ON movies
FOR EACH ROW
EXECUTE FUNCTION update_genre_statistics();