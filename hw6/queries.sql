-- 1. Напишите запрос, который выводит названия всех достопримечательностей и их координаты (широту и долготу). 
--    Используйте функцию ST_X() для извлечения долготы и ST_Y() для широты из поля location.
SELECT name, ST_X(location) AS longitude, ST_Y(location) AS latitude
FROM landmarks;

-- 2. Напишите запрос, который выводит все маршруты, начинающиеся в радиусе 5 км от точки с координатами 48.8566, 2.3522 (центр Парижа). 
--    Используйте функцию ST_DWithin() для фильтрации маршрутов по расстоянию.
SELECT id, ST_AsText(start_location) AS start_location, ST_AsText(end_location) AS end_location, ST_AsText(route) AS route
FROM routes
WHERE ST_DWithin(
    start_location::GEOGRAPHY,
    ST_GeomFromText('POINT(2.3522 48.8566)', 4326)::GEOGRAPHY,
    5000
);

-- 3. Напишите запрос, который выводит названия достопримечательностей, полностью находящихся внутри границ территории Лувра. 
--    Координаты полигона Лувра уже записаны в таблице landmarks в поле boundary.
SELECT name
FROM landmarks
WHERE ST_Contains((
	SELECT boundary FROM landmarks WHERE name = 'Лувр'
), location);

-- 4. Напишите запрос, который добавляет новую достопримечательность ""Музей Луи Виттона"" с координатами (48.864716, 2.349014) в таблицу landmarks. 
--    Укажите её местоположение как геометрию типа POINT.
INSERT INTO landmarks(name, location)
VALUES ('Музей Луи Виттона', ST_SetSRID(ST_MakePoint(2.349014, 48.864716), 4326));

-- 5. Напишите запрос, который выводит длину маршрута, соединяющего Эйфелеву башню и Лувр. 
--    Для этого используйте функцию ST_Length() для поля route в таблице routes.
SELECT ST_Length(ST_Transform(route, 3857)) AS route_length_meters
FROM routes
WHERE 
	start_location = (SELECT location FROM landmarks WHERE name = 'Эйфелева башня') 
	AND end_location = (SELECT location FROM landmarks WHERE name = 'Лувр');

-- 6. Напишите запрос, который выводит все маршруты, пересекающие радиус 2 км от точки с координатами (48.8588443, 2.2943506) (Эйфелева башня). 
--    Используйте функцию ST_Intersects() для определения пересечений.
SELECT id, ST_AsText(start_location) AS start_location, ST_AsText(end_location) AS end_location, ST_AsText(route) AS route
FROM routes
WHERE ST_Intersects(route, ST_Buffer(ST_SetSRID(ST_MakePoint(2.2943506, 48.8588443), 4326)::geography, 2000)::geometry);

-- 7. Напишите запрос, который добавляет границы для новой достопримечательности ""Парк Монсо"" 
--    (координаты по углам полигона: (48.8792, 2.3086), (48.8794, 2.3086), (48.8794, 2.3090), (48.8792, 2.3090)). 
--    Убедитесь, что границы правильно заносятся в поле boundary таблицы landmarks.
UPDATE landmarks
SET boundary = ST_SetSRID(
	ST_GeomFromText('POLYGON((2.3086 48.8792, 2.3086 48.8794, 2.3090 48.8794, 2.3090 48.8792, 2.3086 48.8792))'), 
	4326
)
WHERE name = 'Парк Монсо';

-- 8. Напишите запрос, который выводит все маршруты между достопримечательностями, находящимися в пределах города Париж 
--    (границы города заданы как полигон). Координаты полигона предоставлены.
--    ??? Не нашла, где предоставлены координаты полигона для Парижа. Взяла те, выдал ИИ
SELECT id, ST_AsText(start_location) AS start_location, ST_AsText(end_location) AS end_location, ST_AsText(route) AS route
FROM routes
WHERE ST_Contains(
    ST_SetSRID(ST_MakePolygon(ST_MakeLine(ARRAY[
        ST_MakePoint(2.2241, 48.9011),
        ST_MakePoint(2.4699, 48.9011),
        ST_MakePoint(2.4699, 48.8156),
        ST_MakePoint(2.2241, 48.8156),
        ST_MakePoint(2.2241, 48.9011)
    ])), 4326), 
    route
);

-- 9. Напишите запрос, который выводит топ-3 самых длинных маршрута между достопримечательностями. 
--    Используйте функцию ST_Length() и сортировку по убыванию длины маршрута.
SELECT 
	id, 
	ST_AsText(start_location) AS start_location, 
	ST_AsText(end_location) AS end_location, 
	ST_AsText(route) AS route,
	ST_Length(route) AS route_length
FROM routes
ORDER BY 5 DESC
LIMIT 3;

-- 10. Напишите запрос, который выводит названия всех достопримечательностей, находящихся в пределах 10 км от центра Парижа 
--     (координаты 48.8566, 2.3522). Используйте функцию ST_Distance() для измерения расстояний.
SELECT name
FROM landmarks
WHERE ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography) < 10000;