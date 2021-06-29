# task 1 
# Составьте список пользователей users, которые осуществили хотя бы один заказ orders в интернет магазине.
ALTER TABLE orders CHANGE user_id user_id BIGINT UNSIGNED NOT NULL;
ALTER TABLE orders ADD CONSTRAINT user_order FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE;
INSERT INTO orders VALUES (NULL, 2, DEFAULT, DEFAULT), 
						  (NULL, 2, DEFAULT, DEFAULT), 
						  (NULL, 3, DEFAULT, DEFAULT), 
						  (NULL, 6, DEFAULT, DEFAULT);
INSERT INTO orders_products VALUES (NULL, 1, 1, 1, DEFAULT, DEFAULT),
								   (NULL, 2, 5, 1, DEFAULT, DEFAULT),
								   (NULL, 3, 5, 2, DEFAULT, DEFAULT),
								   (NULL, 4, 7, 1, DEFAULT, DEFAULT);
ALTER TABLE orders_products CHANGE product_id product_id BIGINT UNSIGNED NOT NULL;

SELECT name 
FROM users WHERE id IN (SELECT user_id FROM orders WHERE orders.user_id = users.id) ORDER BY name;

SELECT u.name, op.order_id, (SELECT CONCAT(SUBSTRING(name, 1, 5), ' ... ', price, ' $') 
	   FROM products WHERE id = op.product_id) AS name_price, 
	   op.total 
	   FROM users u JOIN orders o ON u.id = o.user_id
				JOIN orders_products op ON o.id = op.order_id ORDER BY u.name;


# task 2
# Выведите список товаров products и разделов catalogs, который соответствует товару.

SELECT p.name AS good, p.price AS price, c.name AS cat_name FROM products p JOIN catalogs c ON p.catalog_id = c.id 
	ORDER BY price DESC;


# task 3
# (по желанию) Пусть имеется таблица рейсов flights (id, from, to) и таблица городов cities (label, name). 
# Поля from, to и label содержат английские названия городов, поле name — русское. 
# Выведите список рейсов flights с русскими названиями городов.

CREATE TABLE IF NOT EXISTS cities (
	label VARCHAR(100),
	name VARCHAR(100),
	INDEX name_idx (label)
);

CREATE TABLE IF NOT EXISTS flights (
	id SERIAL PRIMARY KEY,
	`from` VARCHAR(100),
	`to` VARCHAR(100),
	CONSTRAINT label_from_city FOREIGN KEY (`from`) REFERENCES cities(label) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT label_to_city FOREIGN KEY (`to`) REFERENCES cities(label) ON DELETE SET NULL ON UPDATE CASCADE
);

INSERT INTO cities VALUES ('Moscow', 'Москва'),
						  ('Paris', 'Париж'),
						  ('London', 'Лондон'),
						  ('Berlin', 'Берлин');

INSERT INTO flights VALUES (NULL, 'Moscow', 'Paris'),
						   (NULL, 'Paris', 'London'),
						   (NULL, 'London', 'Berlin'),
						   (NULL, 'Berlin', 'Moscow'),
						   (NULL, 'Moscow', 'Paris');
# вариант 1					   
SELECT id, 
	(SELECT name FROM cities WHERE cities.label = `from`) AS departure,
	(SELECT name FROM cities WHERE cities.label = `to`) AS arrival
FROM flights ORDER BY id;

# вариант 2
SELECT f.id AS flight_no, c.name AS departure, c2.name AS arrival FROM flights AS f JOIN cities AS c ON f.`from` = c.label 
	JOIN cities AS c2 ON f.`to` = c2.label ORDER BY flight_no;

