-- все актеры
SELECT * FROM actors ;

-- все фильмы жанра ""Драма"", выпущенные после 2010 года
SELECT f.*
FROM films f
JOIN genres g ON g.genre_id = f.genre_id
WHERE g.genre_name = 'Драма' AND f.release_year > 2010;

-- список актеров, отсортированных по фамилии в алфавитном порядке
SELECT * FROM actors ORDER BY last_name;

-- топ 5 фильмов с самым высоким рейтингом
SELECT * FROM films ORDER BY rating DESC LIMIT 5;

-- фильмы с 6 по 10 из отсортированного по рейтингу списка фильмов
SELECT * FROM films ORDER BY rating DESC LIMIT 5 OFFSET 5;