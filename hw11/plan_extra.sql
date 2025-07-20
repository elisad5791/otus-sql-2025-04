WITH filtered_customers AS (
    SELECT c.*
    FROM customers c
    WHERE c.registration_date <= '2022-12-31'
),
customer_rentals AS (
    SELECT 
        r.customer_id,
        COUNT(r.rental_id) AS total_rentals,
        MAX(r.return_date) AS last_rental_date,
        SUM(CASE WHEN r.return_date IS NULL THEN 1 ELSE 0 END) AS active_rentals,
        SUM(CASE WHEN m.genre = 'Action' THEN 1 ELSE 0 END) AS action_movies_rented
    FROM rentals r
    JOIN movies m ON r.movie_id = m.movie_id
    WHERE r.rental_date BETWEEN '2020-01-01' AND '2022-12-31'
    GROUP BY r.customer_id
    HAVING COUNT(r.rental_id) > 10
),
drama_counts AS (
    SELECT 
        r.customer_id,
        COUNT(DISTINCT m.movie_id) AS drama_movies_rented
    FROM rentals r
    JOIN movies m ON r.movie_id = m.movie_id AND m.genre = 'Drama'
    GROUP BY r.customer_id
),
avg_ratings AS (
    SELECT 
        r.customer_id,
        AVG(m.rating) AS avg_rating
    FROM rentals r
    JOIN movies m ON r.movie_id = m.movie_id
    GROUP BY r.customer_id
),
recent_rentals AS (
    SELECT 
        r.customer_id,
        COUNT(r.rental_id) AS rentals_last_two_years
    FROM rentals r
    WHERE r.rental_date BETWEEN '2021-01-01' AND '2022-12-31'
    GROUP BY r.customer_id
)

SELECT DISTINCT 
    c.customer_id,
    c.first_name, 
    c.last_name, 
    c.email, 
    c.registration_date,
    COALESCE(cr.active_rentals, 0) AS active_rentals,
    COALESCE(dc.drama_movies_rented, 0) AS drama_movies_rented,
    COALESCE(ar.avg_rating, 0) AS avg_rating,
    COALESCE(rr.rentals_last_two_years, 0) AS rentals_last_two_years,
    cr.last_rental_date,
    cr.total_rentals,
    COALESCE(cr.action_movies_rented, 0) AS action_movies_rented
FROM 
    filtered_customers c
JOIN customer_rentals cr ON c.customer_id = cr.customer_id
LEFT JOIN drama_counts dc ON c.customer_id = dc.customer_id
LEFT JOIN avg_ratings ar ON c.customer_id = ar.customer_id
LEFT JOIN recent_rentals rr ON c.customer_id = rr.customer_id
ORDER BY
    cr.total_rentals DESC, cr.last_rental_date DESC
LIMIT 50;

/*
СРАВНЕНИЕ ПЛАНОВ
                                стоимость               время выполнения
исходный запрос                 158538.76..158540.39    70.930 ms
исходный запрос с индексами     32947.16..32948.79      4.771 ms
запрос с СТЕ                    2328.28..2329.90        20.189 ms
запрос с СТЕ с индексами        2221.15..2222.78        17.693 ms

Как видно, изменение структуры запроса (введение CTE) существенно улучшило производительность.
Однако, использование индексов оказадось очень эффективным для исходного запроса и лишь незначительно повлияло на модифицированный запрос с CTE. 
В итоге по времени выполнения самый выгодный вариант - исходный запрос с индексами, хотя стоимость значительно ниже у запроса с CTE.


ПЛАН ВЫПОЛНЕНИЯ ЗАПРОСА ДО СОЗДАНИЯ ИНДЕКСОВ

"Limit  (cost=2328.28..2329.90 rows=50 width=114) (actual time=19.836..19.851 rows=16 loops=1)"
"  ->  Unique  (cost=2328.28..2332.11 rows=118 width=114) (actual time=19.834..19.849 rows=16 loops=1)"
"        ->  Sort  (cost=2328.28..2328.57 rows=118 width=114) (actual time=19.833..19.842 rows=16 loops=1)"
"              Sort Key: cr.total_rentals DESC, cr.last_rental_date DESC, c.customer_id, c.first_name, c.last_name, c.email, c.registration_date, (COALESCE(cr.active_rentals, '0'::bigint)), (COALESCE((count(DISTINCT m.movie_id)), '0'::bigint)), (COALESCE(ar.avg_rating, '0'::numeric)), (COALESCE(rr.rentals_last_two_years, '0'::bigint)), (COALESCE(cr.action_movies_rented, '0'::bigint))"
"              Sort Method: quicksort  Memory: 27kB"
"              ->  Hash Right Join  (cost=2284.29..2324.22 rows=118 width=114) (actual time=19.028..19.818 rows=16 loops=1)"
"                    Hash Cond: (r.customer_id = c.customer_id)"
"                    ->  GroupAggregate  (cost=538.13..563.13 rows=1000 width=12) (actual time=2.868..3.656 rows=856 loops=1)"
"                          Group Key: r.customer_id"
"                          ->  Sort  (cost=538.13..543.13 rows=2000 width=8) (actual time=2.857..2.921 rows=2027 loops=1)"
"                                Sort Key: r.customer_id"
"                                Sort Method: quicksort  Memory: 144kB"
"                                ->  Hash Join  (cost=47.75..428.47 rows=2000 width=8) (actual time=0.172..2.564 rows=2027 loops=1)"
"                                      Hash Cond: (r.movie_id = m.movie_id)"
"                                      ->  Seq Scan on rentals r  (cost=0.00..328.00 rows=20000 width=8) (actual time=0.012..0.985 rows=20000 loops=1)"
"                                      ->  Hash  (cost=46.50..46.50 rows=100 width=4) (actual time=0.152..0.153 rows=100 loops=1)"
"                                            Buckets: 1024  Batches: 1  Memory Usage: 12kB"
"                                            ->  Seq Scan on movies m  (cost=0.00..46.50 rows=100 width=4) (actual time=0.010..0.142 rows=100 loops=1)"
"                                                  Filter: ((genre)::text = 'Drama'::text)"
"                                                  Rows Removed by Filter: 900"
"                    ->  Hash  (cost=1744.68..1744.68 rows=118 width=106) (actual time=16.088..16.095 rows=16 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 10kB"
"                          ->  Hash Left Join  (cost=1705.63..1744.68 rows=118 width=106) (actual time=15.918..16.085 rows=16 loops=1)"
"                                Hash Cond: (c.customer_id = rr.customer_id)"
"                                ->  Hash Left Join  (cost=1211.63..1250.37 rows=118 width=98) (actual time=13.134..13.298 rows=16 loops=1)"
"                                      Hash Cond: (c.customer_id = ar.customer_id)"
"                                      ->  Hash Join  (cost=639.41..677.84 rows=118 width=66) (actual time=4.966..5.123 rows=16 loops=1)"
"                                            Hash Cond: (c.customer_id = cr.customer_id)"
"                                            ->  Seq Scan on customers c  (cost=0.00..37.50 rows=355 width=38) (actual time=0.018..0.158 rows=355 loops=1)"
"                                                  Filter: (registration_date <= '2022-12-31'::date)"
"                                                  Rows Removed by Filter: 645"
"                                            ->  Hash  (cost=635.25..635.25 rows=333 width=32) (actual time=4.931..4.933 rows=45 loops=1)"
"                                                  Buckets: 1024  Batches: 1  Memory Usage: 11kB"
"                                                  ->  Subquery Scan on cr  (cost=619.42..635.25 rows=333 width=32) (actual time=4.820..4.919 rows=45 loops=1)"
"                                                        ->  HashAggregate  (cost=619.42..631.92 rows=333 width=32) (actual time=4.820..4.916 rows=45 loops=1)"
"                                                              Group Key: r_1.customer_id"
"                                                              Filter: (count(r_1.rental_id) > 10)"
"                                                              Rows Removed by Filter: 955"
"                                                              ->  Hash Join  (cost=56.50..502.17 rows=6700 width=20) (actual time=0.364..3.425 rows=6698 loops=1)"
"                                                                    Hash Cond: (r_1.movie_id = m_1.movie_id)"
"                                                                    ->  Seq Scan on rentals r_1  (cost=0.00..428.00 rows=6700 width=16) (actual time=0.007..1.931 rows=6698 loops=1)"
"                                                                          Filter: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                                                          Rows Removed by Filter: 13302"
"                                                                    ->  Hash  (cost=44.00..44.00 rows=1000 width=12) (actual time=0.350..0.351 rows=1000 loops=1)"
"                                                                          Buckets: 1024  Batches: 1  Memory Usage: 53kB"
"                                                                          ->  Seq Scan on movies m_1  (cost=0.00..44.00 rows=1000 width=12) (actual time=0.021..0.224 rows=1000 loops=1)"
"                                      ->  Hash  (cost=559.72..559.72 rows=1000 width=36) (actual time=8.159..8.161 rows=1000 loops=1)"
"                                            Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                            ->  Subquery Scan on ar  (cost=537.22..559.72 rows=1000 width=36) (actual time=7.671..8.041 rows=1000 loops=1)"
"                                                  ->  HashAggregate  (cost=537.22..549.72 rows=1000 width=36) (actual time=7.670..7.988 rows=1000 loops=1)"
"                                                        Group Key: r_2.customer_id"
"                                                        ->  Hash Join  (cost=56.50..437.22 rows=20000 width=10) (actual time=0.251..4.364 rows=20000 loops=1)"
"                                                              Hash Cond: (r_2.movie_id = m_2.movie_id)"
"                                                              ->  Seq Scan on rentals r_2  (cost=0.00..328.00 rows=20000 width=8) (actual time=0.014..1.020 rows=20000 loops=1)"
"                                                              ->  Hash  (cost=44.00..44.00 rows=1000 width=10) (actual time=0.230..0.231 rows=1000 loops=1)"
"                                                                    Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                                                    ->  Seq Scan on movies m_2  (cost=0.00..44.00 rows=1000 width=10) (actual time=0.004..0.133 rows=1000 loops=1)"
"                                ->  Hash  (cost=481.50..481.50 rows=1000 width=12) (actual time=2.770..2.771 rows=1000 loops=1)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                      ->  Subquery Scan on rr  (cost=461.50..481.50 rows=1000 width=12) (actual time=2.535..2.681 rows=1000 loops=1)"
"                                            ->  HashAggregate  (cost=461.50..471.50 rows=1000 width=12) (actual time=2.535..2.628 rows=1000 loops=1)"
"                                                  Group Key: r_3.customer_id"
"                                                  ->  Seq Scan on rentals r_3  (cost=0.00..428.00 rows=6700 width=8) (actual time=0.034..1.693 rows=6698 loops=1)"
"                                                        Filter: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                                        Rows Removed by Filter: 13302"
"Planning Time: 0.892 ms"
"Execution Time: 20.189 ms"

ПЛАН ВЫПОЛНЕНИЯ ЗАПРОСА ПОСЛЕ СОЗДАНИЯ ИНДЕКСОВ

"Limit  (cost=2221.15..2222.78 rows=50 width=114) (actual time=17.371..17.385 rows=16 loops=1)"
"  ->  Unique  (cost=2221.15..2224.99 rows=118 width=114) (actual time=17.370..17.382 rows=16 loops=1)"
"        ->  Sort  (cost=2221.15..2221.45 rows=118 width=114) (actual time=17.368..17.375 rows=16 loops=1)"
"              Sort Key: cr.total_rentals DESC, cr.last_rental_date DESC, c.customer_id, c.first_name, c.last_name, c.email, c.registration_date, (COALESCE(cr.active_rentals, '0'::bigint)), (COALESCE((count(DISTINCT m.movie_id)), '0'::bigint)), (COALESCE(ar.avg_rating, '0'::numeric)), (COALESCE(rr.rentals_last_two_years, '0'::bigint)), (COALESCE(cr.action_movies_rented, '0'::bigint))"
"              Sort Method: quicksort  Memory: 27kB"
"              ->  Hash Right Join  (cost=2177.16..2217.09 rows=118 width=114) (actual time=16.545..17.357 rows=16 loops=1)"
"                    Hash Cond: (r.customer_id = c.customer_id)"
"                    ->  GroupAggregate  (cost=531.93..556.93 rows=1000 width=12) (actual time=2.607..3.416 rows=856 loops=1)"
"                          Group Key: r.customer_id"
"                          ->  Sort  (cost=531.93..536.93 rows=2000 width=8) (actual time=2.600..2.662 rows=2027 loops=1)"
"                                Sort Key: r.customer_id"
"                                Sort Method: quicksort  Memory: 144kB"
"                                ->  Hash Join  (cost=41.55..422.27 rows=2000 width=8) (actual time=0.098..2.327 rows=2027 loops=1)"
"                                      Hash Cond: (r.movie_id = m.movie_id)"
"                                      ->  Seq Scan on rentals r  (cost=0.00..328.00 rows=20000 width=8) (actual time=0.020..0.821 rows=20000 loops=1)"
"                                      ->  Hash  (cost=40.30..40.30 rows=100 width=4) (actual time=0.072..0.073 rows=100 loops=1)"
"                                            Buckets: 1024  Batches: 1  Memory Usage: 12kB"
"                                            ->  Bitmap Heap Scan on movies m  (cost=5.05..40.30 rows=100 width=4) (actual time=0.032..0.062 rows=100 loops=1)"
"                                                  Recheck Cond: ((genre)::text = 'Drama'::text)"
"                                                  Heap Blocks: exact=34"
"                                                  ->  Bitmap Index Scan on idx_movies_genre  (cost=0.00..5.03 rows=100 width=0) (actual time=0.028..0.029 rows=100 loops=1)"
"                                                        Index Cond: ((genre)::text = 'Drama'::text)"
"                    ->  Hash  (cost=1643.76..1643.76 rows=118 width=106) (actual time=13.871..13.876 rows=16 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 10kB"
"                          ->  Hash Left Join  (cost=1604.71..1643.76 rows=118 width=106) (actual time=13.711..13.869 rows=16 loops=1)"
"                                Hash Cond: (c.customer_id = rr.customer_id)"
"                                ->  Hash Left Join  (cost=1161.18..1199.93 rows=118 width=98) (actual time=11.786..11.941 rows=16 loops=1)"
"                                      Hash Cond: (c.customer_id = ar.customer_id)"
"                                      ->  Hash Join  (cost=588.96..627.39 rows=118 width=66) (actual time=3.706..3.855 rows=16 loops=1)"
"                                            Hash Cond: (c.customer_id = cr.customer_id)"
"                                            ->  Seq Scan on customers c  (cost=0.00..37.50 rows=355 width=38) (actual time=0.007..0.141 rows=355 loops=1)"
"                                                  Filter: (registration_date <= '2022-12-31'::date)"
"                                                  Rows Removed by Filter: 645"
"                                            ->  Hash  (cost=584.80..584.80 rows=333 width=32) (actual time=3.683..3.685 rows=45 loops=1)"
"                                                  Buckets: 1024  Batches: 1  Memory Usage: 11kB"
"                                                  ->  Subquery Scan on cr  (cost=568.97..584.80 rows=333 width=32) (actual time=3.573..3.677 rows=45 loops=1)"
"                                                        ->  HashAggregate  (cost=568.97..581.47 rows=333 width=32) (actual time=3.573..3.673 rows=45 loops=1)"
"                                                              Group Key: r_1.customer_id"
"                                                              Filter: (count(r_1.rental_id) > 10)"
"                                                              Rows Removed by Filter: 955"
"                                                              ->  Hash Join  (cost=205.48..451.68 rows=6702 width=20) (actual time=0.534..2.282 rows=6698 loops=1)"
"                                                                    Hash Cond: (r_1.movie_id = m_1.movie_id)"
"                                                                    ->  Bitmap Heap Scan on rentals r_1  (cost=148.98..377.51 rows=6702 width=16) (actual time=0.281..0.841 rows=6698 loops=1)"
"                                                                          Recheck Cond: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                                                          Heap Blocks: exact=128"
"                                                                          ->  Bitmap Index Scan on idx_rentals_rental_date  (cost=0.00..147.31 rows=6702 width=0) (actual time=0.268..0.268 rows=6698 loops=1)"
"                                                                                Index Cond: ((rental_date >= '2020-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                                                    ->  Hash  (cost=44.00..44.00 rows=1000 width=12) (actual time=0.250..0.251 rows=1000 loops=1)"
"                                                                          Buckets: 1024  Batches: 1  Memory Usage: 53kB"
"                                                                          ->  Seq Scan on movies m_1  (cost=0.00..44.00 rows=1000 width=12) (actual time=0.004..0.151 rows=1000 loops=1)"
"                                      ->  Hash  (cost=559.72..559.72 rows=1000 width=36) (actual time=8.076..8.078 rows=1000 loops=1)"
"                                            Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                            ->  Subquery Scan on ar  (cost=537.22..559.72 rows=1000 width=36) (actual time=7.556..7.950 rows=1000 loops=1)"
"                                                  ->  HashAggregate  (cost=537.22..549.72 rows=1000 width=36) (actual time=7.555..7.895 rows=1000 loops=1)"
"                                                        Group Key: r_2.customer_id"
"                                                        ->  Hash Join  (cost=56.50..437.22 rows=20000 width=10) (actual time=0.207..4.227 rows=20000 loops=1)"
"                                                              Hash Cond: (r_2.movie_id = m_2.movie_id)"
"                                                              ->  Seq Scan on rentals r_2  (cost=0.00..328.00 rows=20000 width=8) (actual time=0.007..0.823 rows=20000 loops=1)"
"                                                              ->  Hash  (cost=44.00..44.00 rows=1000 width=10) (actual time=0.197..0.197 rows=1000 loops=1)"
"                                                                    Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                                                    ->  Seq Scan on movies m_2  (cost=0.00..44.00 rows=1000 width=10) (actual time=0.004..0.107 rows=1000 loops=1)"
"                                ->  Hash  (cost=431.02..431.02 rows=1000 width=12) (actual time=1.916..1.917 rows=1000 loops=1)"
"                                      Buckets: 1024  Batches: 1  Memory Usage: 51kB"
"                                      ->  Subquery Scan on rr  (cost=411.02..431.02 rows=1000 width=12) (actual time=1.682..1.828 rows=1000 loops=1)"
"                                            ->  HashAggregate  (cost=411.02..421.02 rows=1000 width=12) (actual time=1.681..1.772 rows=1000 loops=1)"
"                                                  Group Key: r_3.customer_id"
"                                                  ->  Bitmap Heap Scan on rentals r_3  (cost=148.98..377.51 rows=6702 width=8) (actual time=0.251..0.795 rows=6698 loops=1)"
"                                                        Recheck Cond: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"                                                        Heap Blocks: exact=128"
"                                                        ->  Bitmap Index Scan on idx_rentals_rental_date  (cost=0.00..147.31 rows=6702 width=0) (actual time=0.238..0.238 rows=6698 loops=1)"
"                                                              Index Cond: ((rental_date >= '2021-01-01'::date) AND (rental_date <= '2022-12-31'::date))"
"Planning Time: 1.691 ms"
"Execution Time: 17.693 ms"
*/