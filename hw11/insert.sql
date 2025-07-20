BEGIN;

ALTER TABLE customers DISABLE TRIGGER ALL;
DROP INDEX idx_customers_email;

COPY customers (first_name, last_name, email, phone_number, address, registration_date, preferences) 
FROM 'C:\Otus\SQL\homework\hw11\customers_data.csv' 
WITH (FORMAT csv, HEADER true, DELIMITER ',');

ALTER TABLE customers ENABLE TRIGGER ALL;
CREATE INDEX idx_customers_email ON customers(email);

COMMIT;

/*
Для вставки большого количества данных можно использовать COPY из  csv-файла или многострочный INSERT. 
COPY быстрее и создает меньшую нагрузку.

Пример файла для вставки прилагается (там только 10 записей, остальные можно добавить аналогично) - customers_data.csv

Для ускорения массовой вставки отключаются индексы и триггеры

Все операции выполняются в рамках одной транзакции
*/