CREATE INDEX IF NOT EXISTS idx_movies_release_year ON movies(release_year);

BEGIN;

ALTER TABLE movies DISABLE TRIGGER ALL;
DROP INDEX IF EXISTS idx_movies_genre;

UPDATE movies
SET rating = LEAST(rating + 0.2, 9.9)
WHERE release_year > 2015
AND rating IS NOT NULL;

ALTER TABLE movies ENABLE TRIGGER ALL;
CREATE INDEX idx_movies_genre ON movies(genre);

COMMIT;

/*
Создан индекс для фильтрации по году выпуска

Исключены фильмы без рейтинга

Для ускорения массового обновления отключаются индексы и триггеры

Все операции выполняются в рамках одной транзакции

При условии release_year > 2015 и моих тестовых данных, postgres не использует индекс, т.к. seq scan, видимо, оказывается выгоднее.

Но если взять, например, условие release_year > 2022, то селективность запроса повышается и индекс используется

"Update on movies  (cost=4.73..59.51 rows=59 width=243) (actual time=1.786..1.787 rows=0 loops=1)"
"  ->  Bitmap Heap Scan on movies  (cost=4.73..59.51 rows=59 width=243) (actual time=0.495..0.622 rows=59 loops=1)"
"        Recheck Cond: (release_year > 2022)"
"        Filter: (rating IS NOT NULL)"
"        Heap Blocks: exact=31"
"        ->  Bitmap Index Scan on idx_movies_release_year  (cost=0.00..4.72 rows=59 width=0) (actual time=0.028..0.028 rows=114 loops=1)"
"              Index Cond: (release_year > 2022)"
"Planning Time: 0.157 ms"
"Execution Time: 1.852 ms"
*/