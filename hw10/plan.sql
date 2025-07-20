SELECT 
    customers.first_name, 
    customers.last_name, 
    movies.title,
    COUNT(rentals.rental_id) AS rental_count, 
    MAX(rentals.rental_date) AS last_rental_date
FROM 
    customers
JOIN 
    rentals ON customers.customer_id = rentals.customer_id
JOIN 
    movies ON rentals.movie_id = movies.movie_id
WHERE 
    movies.genre = 'Action'
    AND rentals.rental_date BETWEEN '2021-01-01' AND '2022-12-31'
GROUP BY 
    customers.first_name,
    customers.last_name, 
    movies.title
ORDER BY 
    rental_count DESC, 
    last_rental_date DESC
LIMIT 10;

/*
СРАВНЕНИЕ ПЛАНОВ ДО И ПОСЛЕ СОЗДАНИЯ ИНДЕКСОВ

cost уменьшился 375.17..375.19 => 307.00..307.03
Execution Time уменьшилось 2.518 ms => 1.542 ms
используется Index Scan on idx_rentals_rental_date вместо Seq Scan on rentals
используется Index Scan on idx_movies_genre вместо Seq Scan on movies
выигрыш в производительности есть, но не очень большой.

ПЛАН ВЫПОНЕНИЯ ЗАПРОСА ДО СОЗДАНИЯ ИНДЕКСОВ

"Limit  (cost=375.17..375.19 rows=10 width=40) (actual time=2.419..2.421 rows=10 loops=1)"
"  ->  Sort  (cost=375.17..376.97 rows=721 width=40) (actual time=2.417..2.419 rows=10 loops=1)"
"        Sort Key: (count(rentals.rental_id)) DESC, (max(rentals.rental_date)) DESC"
"        Sort Method: top-N heapsort  Memory: 26kB"
"        ->  HashAggregate  (cost=352.38..359.59 rows=721 width=40) (actual time=2.259..2.307 rows=336 loops=1)"
"              Group Key: customers.first_name, customers.last_name, movies.title"
"              ->  Hash Join  (cost=95.25..343.37 rows=721 width=36) (actual time=0.586..2.143 rows=336 loops=1)"
"                    Hash Cond: (rentals.customer_id = customers.customer_id)"
"                    ->  Hash Join  (cost=47.75..293.96 rows=721 width=26) (actual time=0.246..1.745 rows=336 loops=1)"
"                          Hash Cond: (rentals.movie_id = movies.movie_id)"
"                          ->  Seq Scan on rentals  (cost=0.00..227.20 rows=7213 width=16) (actual time=0.018..1.310 rows=3371 loops=1)"
"                                Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                Rows Removed by Filter: 6629"
"                          ->  Hash  (cost=46.50..46.50 rows=100 width=18) (actual time=0.214..0.214 rows=100 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 14kB"
"                                ->  Seq Scan on movies  (cost=0.00..46.50 rows=100 width=18) (actual time=0.007..0.200 rows=100 loops=1)"
"                                      Filter: ((genre)::text = 'Action'::text)"
"                                      Rows Removed by Filter: 900"
"                    ->  Hash  (cost=35.00..35.00 rows=1000 width=18) (actual time=0.329..0.329 rows=1000 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 60kB"
"                          ->  Seq Scan on customers  (cost=0.00..35.00 rows=1000 width=18) (actual time=0.012..0.180 rows=1000 loops=1)"
"Planning Time: 0.973 ms"
"Execution Time: 2.518 ms"

ПЛАН ВЫПОЛНЕНИЯ ЗАПРОСА ПОСЛЕ СОЗДАНИЯ ИНДЕКСОВ

"Limit  (cost=307.00..307.03 rows=10 width=40) (actual time=1.429..1.430 rows=10 loops=1)"
"  ->  Sort  (cost=307.00..307.84 rows=337 width=40) (actual time=1.428..1.429 rows=10 loops=1)"
"        Sort Key: (count(rentals.rental_id)) DESC, (max(rentals.rental_date)) DESC"
"        Sort Method: top-N heapsort  Memory: 26kB"
"        ->  HashAggregate  (cost=296.35..299.72 rows=337 width=40) (actual time=1.278..1.323 rows=336 loops=1)"
"              Group Key: customers.first_name, customers.last_name, movies.title"
"              ->  Hash Join  (cost=167.86..292.14 rows=337 width=36) (actual time=0.484..1.165 rows=336 loops=1)"
"                    Hash Cond: (rentals.customer_id = customers.customer_id)"
"                    ->  Hash Join  (cost=120.36..243.75 rows=337 width=26) (actual time=0.209..0.835 rows=336 loops=1)"
"                          Hash Cond: (rentals.movie_id = movies.movie_id)"
"                          ->  Bitmap Heap Scan on rentals  (cost=78.81..193.33 rows=3368 width=16) (actual time=0.118..0.463 rows=3371 loops=1)"
"                                Recheck Cond: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                Heap Blocks: exact=64"
"                                ->  Bitmap Index Scan on idx_rentals_rental_date  (cost=0.00..77.97 rows=3368 width=0) (actual time=0.110..0.110 rows=3371 loops=1)"
"                                      Index Cond: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                          ->  Hash  (cost=40.30..40.30 rows=100 width=18) (actual time=0.081..0.081 rows=100 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 14kB"
"                                ->  Bitmap Heap Scan on movies  (cost=5.05..40.30 rows=100 width=18) (actual time=0.025..0.069 rows=100 loops=1)"
"                                      Recheck Cond: ((genre)::text = 'Action'::text)"
"                                      Heap Blocks: exact=34"
"                                      ->  Bitmap Index Scan on idx_movies_genre  (cost=0.00..5.03 rows=100 width=0) (actual time=0.021..0.021 rows=100 loops=1)"
"                                            Index Cond: ((genre)::text = 'Action'::text)"
"                    ->  Hash  (cost=35.00..35.00 rows=1000 width=18) (actual time=0.265..0.265 rows=1000 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 60kB"
"                          ->  Seq Scan on customers  (cost=0.00..35.00 rows=1000 width=18) (actual time=0.011..0.130 rows=1000 loops=1)"
"Planning Time: 0.678 ms"
"Execution Time: 1.542 ms"
*/