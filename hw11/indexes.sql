CREATE INDEX idx_rentals_rental_date ON rentals(rental_date);
CREATE INDEX idx_rentals_movie_id ON rentals(movie_id);
CREATE INDEX idx_rentals_customer_id ON rentals(customer_id);
CREATE INDEX idx_customers_registration_date ON customers(registration_date);
CREATE INDEX idx_movies_genre ON movies(genre);