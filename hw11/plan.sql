SELECT DISTINCT 
    c.customer_id,
    c.first_name, 
    c.last_name, 
    c.email, 
    c.registration_date,
    COALESCE(SUM(CASE WHEN r.return_date IS NULL THEN 1 ELSE 0 END), 0) AS active_rentals,
    (SELECT COUNT(DISTINCT m1.movie_id) 
        FROM movies m1
        JOIN rentals r2 ON m1.movie_id = r2.movie_id
        WHERE r2.customer_id = c.customer_id AND m1.genre = 'Drama') AS drama_movies_rented,
    (SELECT AVG(m2.rating) 
        FROM movies m2 
        JOIN rentals r3 ON m2.movie_id = r3.movie_id
        WHERE r3.customer_id = c.customer_id) AS avg_rating,
    (SELECT COUNT(r4.rental_id) 
        FROM rentals r4 
        WHERE r4.customer_id = c.customer_id AND r4.rental_date BETWEEN '2021-01-01' AND '2022-12-31') AS rentals_last_two_years,
    MAX(r.return_date) AS last_rental_date,
    COUNT(r.rental_id) AS total_rentals,
    SUM(CASE WHEN m.genre = 'Action' THEN 1 ELSE 0 END) AS action_movies_rented
FROM 
    customers c
JOIN rentals r ON c.customer_id = r.customer_id
JOIN movies m ON r.movie_id = m.movie_id
WHERE 
    c.registration_date <= '2022-12-31'
    AND r.rental_date BETWEEN '2020-01-01' AND '2022-12-31'
GROUP BY 
    c.customer_id, c.first_name, c.last_name, c.email, c.registration_date
HAVING 
    COUNT(r.rental_id) > 10
ORDER BY
    total_rentals DESC, last_rental_date DESC
LIMIT 50;

/*
СРАВНЕНИЕ ПЛАНОВ ДО И ПОСЛЕ СОЗДАНИЯ ИНДЕКСОВ

1. уменьшилась стоимость 158538.76..158540.39 -> 32947.16..32948.79
2. уменьшилось время выполнения 70.930 ms -> 4.771 ms
3. postgres использовал только три из созданных индексов - 
    Index Scan on idx_rentals_rental_date
    Index Scan on idx_rentals_customer_id
    Index Scan on idx_movies_genre


ПЛАН ВЫПОЛНЕНИЯ ЗАПРОСА ДО ОПТИМИЗАЦИИ

"Limit  (cost=158538.76..158540.39 rows=50 width=114) (actual time=70.621..70.650 rows=16 loops=1)"
"  ->  Unique  (cost=158538.76..158542.60 rows=118 width=114) (actual time=70.620..70.647 rows=16 loops=1)"
"        ->  Sort  (cost=158538.76..158539.06 rows=118 width=114) (actual time=70.617..70.633 rows=16 loops=1)"
"              Sort Key: (count(r.rental_id)) DESC, (max(r.return_date)) DESC, c.customer_id, c.first_name, c.last_name, c.email, c.registration_date, (COALESCE(sum(CASE WHEN (r.return_date IS NULL) THEN 1 ELSE 0 END), '0'::bigint)), ((SubPlan 1)), ((SubPlan 2)), ((SubPlan 3)), (sum(CASE WHEN ((m.genre)::text = 'Action'::text) THEN 1 ELSE 0 END))"
"              Sort Method: quicksort  Memory: 27kB"
"              ->  HashAggregate  (cost=591.98..158534.70 rows=118 width=114) (actual time=8.473..70.578 rows=16 loops=1)"
"                    Group Key: c.customer_id"
"                    Filter: (count(r.rental_id) > 10)"
"                    Rows Removed by Filter: 339"
"                    ->  Hash Join  (cost=98.44..550.37 rows=2378 width=54) (actual time=0.656..3.488 rows=2409 loops=1)"
"                          Hash Cond: (r.movie_id = m.movie_id)"
"                          ->  Hash Join  (cost=41.94..487.60 rows=2378 width=50) (actual time=0.372..2.827 rows=2409 loops=1)"
"                                Hash Cond: (r.customer_id = c.customer_id)"
"                                ->  Seq Scan on rentals r  (cost=0.00..428.00 rows=6700 width=16) (actual time=0.025..1.784 rows=6698 loops=1)"
"                                      Filter: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                      Rows Removed by Filter: 13302"
"                                ->  Hash  (cost=37.50..37.50 rows=355 width=38) (actual time=0.332..0.333 rows=355 loops=1)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 34kB"
"                                      ->  Seq Scan on customers c  (cost=0.00..37.50 rows=355 width=38) (actual time=0.010..0.236 rows=355 loops=1)"
"                                            Filter: (registration_date <= '2022-12-31'::date)"
"                                            Rows Removed by Filter: 645"
"                          ->  Hash  (cost=44.00..44.00 rows=1000 width=12) (actual time=0.278..0.278 rows=1000 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 53kB"
"                                ->  Seq Scan on movies m  (cost=0.00..44.00 rows=1000 width=12) (actual time=0.007..0.160 rows=1000 loops=1)"
"                    SubPlan 1"
"                      ->  Aggregate  (cost=425.81..425.82 rows=1 width=8) (actual time=1.271..1.271 rows=1 loops=16)"
"                            ->  Hash Join  (cost=47.75..425.80 rows=2 width=4) (actual time=0.420..1.262 rows=2 loops=16)"
"                                  Hash Cond: (r2.movie_id = m1.movie_id)"
"                                  ->  Seq Scan on rentals r2  (cost=0.00..378.00 rows=20 width=4) (actual time=0.029..1.243 rows=20 loops=16)"
"                                        Filter: (customer_id = c.customer_id)"
"                                        Rows Removed by Filter: 19980"
"                                  ->  Hash  (cost=46.50..46.50 rows=100 width=4) (actual time=0.120..0.121 rows=100 loops=1)"
"                                        Buckets: 1024  Batches: 1  Memory Usage: 12kB"
"                                        ->  Seq Scan on movies m1  (cost=0.00..46.50 rows=100 width=4) (actual time=0.004..0.110 rows=100 loops=1)"
"                                              Filter: ((genre)::text = 'Drama'::text)"
"                                              Rows Removed by Filter: 900"
"                    SubPlan 2"
"                      ->  Aggregate  (cost=434.61..434.62 rows=1 width=32) (actual time=1.286..1.286 rows=1 loops=16)"
"                            ->  Hash Join  (cost=56.50..434.55 rows=20 width=6) (actual time=0.048..1.279 rows=20 loops=16)"
"                                  Hash Cond: (r3.movie_id = m2.movie_id)"
"                                  ->  Seq Scan on rentals r3  (cost=0.00..378.00 rows=20 width=4) (actual time=0.029..1.252 rows=20 loops=16)"
"                                        Filter: (customer_id = c.customer_id)"
"                                        Rows Removed by Filter: 19980"
"                                  ->  Hash  (cost=44.00..44.00 rows=1000 width=10) (actual time=0.189..0.191 rows=1000 loops=1)"
"                                        Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                        ->  Seq Scan on movies m2  (cost=0.00..44.00 rows=1000 width=10) (actual time=0.003..0.097 rows=1000 loops=1)"
"                    SubPlan 3"
"                      ->  Aggregate  (cost=478.02..478.03 rows=1 width=8) (actual time=1.588..1.588 rows=1 loops=16)"
"                            ->  Seq Scan on rentals r4  (cost=0.00..478.00 rows=7 width=4) (actual time=0.122..1.576 rows=11 loops=16)"
"                                  Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date) AND (customer_id = c.customer_id))"
"                                  Rows Removed by Filter: 19989"
"Planning Time: 1.107 ms"
"Execution Time: 70.930 ms"


ПЛАН ВЫПОЛНЕНИЯ ЗАПРОСА ПОСЛЕ ДОБАВЛЕНИЯ ИНДЕКСОВ

"Limit  (cost=32947.16..32948.79 rows=50 width=114) (actual time=4.550..4.559 rows=16 loops=1)"
"  ->  Unique  (cost=32947.16..32951.00 rows=118 width=114) (actual time=4.549..4.558 rows=16 loops=1)"
"        ->  Sort  (cost=32947.16..32947.46 rows=118 width=114) (actual time=4.548..4.551 rows=16 loops=1)"
"              Sort Key: (count(r.rental_id)) DESC, (max(r.return_date)) DESC, c.customer_id, c.first_name, c.last_name, c.email, c.registration_date, (COALESCE(sum(CASE WHEN (r.return_date IS NULL) THEN 1 ELSE 0 END), '0'::bigint)), ((SubPlan 1)), ((SubPlan 2)), ((SubPlan 3)), (sum(CASE WHEN ((m.genre)::text = 'Action'::text) THEN 1 ELSE 0 END))"
"              Sort Method: quicksort  Memory: 27kB"
"              ->  HashAggregate  (cost=541.52..32943.10 rows=118 width=114) (actual time=3.749..4.529 rows=16 loops=1)"
"                    Group Key: c.customer_id"
"                    Filter: (count(r.rental_id) > 10)"
"                    Rows Removed by Filter: 339"
"                    ->  Hash Join  (cost=247.42..499.89 rows=2379 width=54) (actual time=0.958..2.750 rows=2409 loops=1)"
"                          Hash Cond: (r.movie_id = m.movie_id)"
"                          ->  Hash Join  (cost=190.92..437.12 rows=2379 width=50) (actual time=0.656..2.072 rows=2409 loops=1)"
"                                Hash Cond: (r.customer_id = c.customer_id)"
"                                ->  Bitmap Heap Scan on rentals r  (cost=148.98..377.51 rows=6702 width=16) (actual time=0.410..1.004 rows=6698 loops=1)"
"                                      Recheck Cond: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                      Heap Blocks: exact=128"
"                                      ->  Bitmap Index Scan on idx_rentals_rental_date  (cost=0.00..147.31 rows=6702 width=0) (actual time=0.394..0.395 rows=6698 loops=1)"
"                                            Index Cond: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                ->  Hash  (cost=37.50..37.50 rows=355 width=38) (actual time=0.229..0.229 rows=355 loops=1)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 34kB"
"                                      ->  Seq Scan on customers c  (cost=0.00..37.50 rows=355 width=38) (actual time=0.004..0.166 rows=355 loops=1)"
"                                            Filter: (registration_date <= '2022-12-31'::date)"
"                                            Rows Removed by Filter: 645"
"                          ->  Hash  (cost=44.00..44.00 rows=1000 width=12) (actual time=0.294..0.294 rows=1000 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 53kB"
"                                ->  Seq Scan on movies m  (cost=0.00..44.00 rows=1000 width=12) (actual time=0.006..0.168 rows=1000 loops=1)"
"                    SubPlan 1"
"                      ->  Aggregate  (cost=100.34..100.35 rows=1 width=8) (actual time=0.025..0.025 rows=1 loops=16)"
"                            ->  Hash Join  (cost=45.99..100.33 rows=2 width=4) (actual time=0.018..0.023 rows=2 loops=16)"
"                                  Hash Cond: (r2.movie_id = m1.movie_id)"
"                                  ->  Bitmap Heap Scan on rentals r2  (cost=4.44..58.73 rows=20 width=4) (actual time=0.008..0.014 rows=20 loops=16)"
"                                        Recheck Cond: (customer_id = c.customer_id)"
"                                        Heap Blocks: exact=320"
"                                        ->  Bitmap Index Scan on idx_rentals_customer_id  (cost=0.00..4.44 rows=20 width=0) (actual time=0.007..0.007 rows=20 loops=16)"
"                                              Index Cond: (customer_id = c.customer_id)"
"                                  ->  Hash  (cost=40.30..40.30 rows=100 width=4) (actual time=0.064..0.064 rows=100 loops=1)"
"                                        Buckets: 1024  Batches: 1  Memory Usage: 12kB"
"                                        ->  Bitmap Heap Scan on movies m1  (cost=5.05..40.30 rows=100 width=4) (actual time=0.029..0.054 rows=100 loops=1)"
"                                              Recheck Cond: ((genre)::text = 'Drama'::text)"
"                                              Heap Blocks: exact=34"
"                                              ->  Bitmap Index Scan on idx_movies_genre  (cost=0.00..5.03 rows=100 width=0) (actual time=0.025..0.025 rows=100 loops=1)"
"                                                    Index Cond: ((genre)::text = 'Drama'::text)"
"                    SubPlan 2"
"                      ->  Aggregate  (cost=115.34..115.35 rows=1 width=32) (actual time=0.031..0.031 rows=1 loops=16)"
"                            ->  Hash Join  (cost=60.94..115.28 rows=20 width=6) (actual time=0.020..0.028 rows=20 loops=16)"
"                                  Hash Cond: (r3.movie_id = m2.movie_id)"
"                                  ->  Bitmap Heap Scan on rentals r3  (cost=4.44..58.73 rows=20 width=4) (actual time=0.003..0.009 rows=20 loops=16)"
"                                        Recheck Cond: (customer_id = c.customer_id)"
"                                        Heap Blocks: exact=320"
"                                        ->  Bitmap Index Scan on idx_rentals_customer_id  (cost=0.00..4.44 rows=20 width=0) (actual time=0.002..0.002 rows=20 loops=16)"
"                                              Index Cond: (customer_id = c.customer_id)"
"                                  ->  Hash  (cost=44.00..44.00 rows=1000 width=10) (actual time=0.216..0.217 rows=1000 loops=1)"
"                                        Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                        ->  Seq Scan on movies m2  (cost=0.00..44.00 rows=1000 width=10) (actual time=0.004..0.119 rows=1000 loops=1)"
"                    SubPlan 3"
"                      ->  Aggregate  (cost=58.85..58.86 rows=1 width=8) (actual time=0.012..0.012 rows=1 loops=16)"
"                            ->  Bitmap Heap Scan on rentals r4  (cost=4.44..58.83 rows=7 width=4) (actual time=0.004..0.010 rows=11 loops=16)"
"                                  Recheck Cond: (customer_id = c.customer_id)"
"                                  Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                  Rows Removed by Filter: 9"
"                                  Heap Blocks: exact=320"
"                                  ->  Bitmap Index Scan on idx_rentals_customer_id  (cost=0.00..4.44 rows=20 width=0) (actual time=0.002..0.002 rows=20 loops=16)"
"                                        Index Cond: (customer_id = c.customer_id)"
"Planning Time: 2.318 ms"
"Execution Time: 4.771 ms"
*/
