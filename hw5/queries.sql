-- 1. Напишите запрос, который выводит название фильма и список языков, на которых доступен фильм. 
--    Используйте функции работы с JSON для извлечения массива языков из поля additional_info.
SELECT title, additional_info->'languages' AS languages
FROM movies;

-- 2. Напишите запрос, который выводит список фильмов, бюджет которых превышает 100 миллионов долларов. 
--    Бюджет хранится в поле additional_info внутри ключа budget.
SELECT *
FROM movies
WHERE (additional_info->>'budget')::INTEGER > 100000000;

-- 3. Напишите запрос, который для каждого клиента создаёт JSON-объект с полями full_name 
--    (содержащим полное имя клиента) и contact (содержащим email и номер телефона). 
--    Выведите customer_id и созданный JSON-объект.
SELECT customer_id, jsonb_build_object(
    'full_name', first_name||' '||last_name,
    'contact', email||', '||phone_number
) AS customer_info
FROM customers;

-- 4. Напишите запрос, который добавляет новый предпочитаемый жанр ""Drama"" в список preferred_genres для всех клиентов, 
--    которые подписаны на рассылку новостей (ключ newsletter имеет значение true).
UPDATE customers
SET preferences = JSONB_SET(preferences, '{preferred_genres}', preferences->'preferred_genres' || '["Drama"]'::JSONB)
WHERE (preferences->>'newsletter')::BOOLEAN AND NOT preferences->'preferred_genres' @> '"Drama"'::JSONB;

-- 5. Напишите запрос, который вычисляет средний бюджет фильмов по жанрам. 
--    Учтите, что жанр хранится в поле genre таблицы Movie, а бюджет — внутри JSON-поля additional_info.
SELECT genre, ROUND(AVG((additional_info->'budget')::INTEGER)) AS avg_budget
FROM movies
GROUP BY genre;

-- 6. Напишите запрос, который выводит список клиентов, у которых в preferences указан предпочитаемый актёр ""Leonardo DiCaprio"".
SELECT *
FROM customers
WHERE preferences->'preferred_actors' @> '"Leonardo DiCaprio"'::JSONB;

-- 7. Напишите запрос, который выводит список фильмов, отсортированных по значению кассовых сборов box_office из поля additional_info в порядке убывания.
SELECT *
FROM movies
ORDER BY (additional_info->'box_office')::BIGINT DESC;

-- 8. Напишите запрос, который выводит название фильма, его жанр и количество наград (awards) из additional_info.
SELECT title, genre, jsonb_array_length(additional_info->'awards') AS awards_count
FROM movies
ORDER BY awards_count DESC;

-- 9. Напишите запрос, который подсчитывает количество фильмов, имеющих более чем одну награду в поле awards внутри additional_info.
SELECT COUNT(*) AS movies_more_one_award
FROM movies
WHERE jsonb_array_length(additional_info->'awards') > 1;

-- 10. Напишите запрос, который удаляет ключ preferred_actors из поля preferences для всех клиентов.
UPDATE customers 
SET preferences = preferences - 'preferred_actors';