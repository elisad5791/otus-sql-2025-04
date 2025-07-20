CREATE TABLE movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    release_year INT,
    genre VARCHAR(100),
    rating DECIMAL(2,1),
    duration INT,
    description TEXT,
    additional_info JSONB
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone_number VARCHAR(20),
    address VARCHAR(255),
    registration_date DATE,
    preferences JSONB
);

CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    movie_id INT REFERENCES movies(movie_id),
    rental_date DATE,
    return_date DATE
);

CREATE TABLE actors (
    actor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    birth_date DATE,
    nationality VARCHAR(100)
);

CREATE TABLE movie_actors (
    movie_actor_id SERIAL PRIMARY KEY,
    movie_id INT REFERENCES movies(movie_id) NOT NULL,
    actor_id INT REFERENCES actors(actor_id) NOT NULL
);