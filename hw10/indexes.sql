-- использованные индексы для фильтрации
CREATE INDEX idx_movies_genre ON movies(genre);
CREATE INDEX idx_rentals_rental_date ON rentals(rental_date);

/* рассматривались и другие индексы

для JOIN
CREATE INDEX idx_rentals_customer_id ON rentals(customer_id);
CREATE INDEX idx_rentals_movie_id ON rentals(movie_id);

составные (покрывающие)
CREATE INDEX idx_movies_genre ON movies(genre, movie_id, title);
CREATE INDEX idx_rentals_rental_date ON rentals(rental_date, customer_id, rental_id);

Но либо postgres их не использует, либо использует точно так же, как два верхних (добавочного выигрыша нет)
*/