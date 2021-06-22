USE shop;

-- part 1 task1 
-- В базе данных shop и sample присутствуют одни и те же таблицы, учебной базы данных. 
-- Переместите запись id = 1 из таблицы shop.users в таблицу sample.users. Используйте транзакции.

SELECT * FROM shop.users LIMIT 2;
SHOW CREATE TABLE shop.users;

DROP TABLE IF EXISTS sample.users;
CREATE TABLE IF NOT EXISTS sample.users (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Имя покупателя',
  `birthday_at` date DEFAULT NULL COMMENT 'Дата рождения',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
);

SELECT * FROM sample.users;

START TRANSACTION;
SAVEPOINT initial_state;
INSERT INTO sample.users SELECT * FROM shop.users WHERE shop.users.id = 1;
COMMIT;

SELECT * FROM sample.users WHERE id = 1;

-- part 1 task2
-- Создайте представление, которое выводит название name товарной позиции из таблицы products 
-- и соответствующее название каталога name из таблицы catalogs.

CREATE OR REPLACE VIEW cat_prod AS
SELECT 
	p.name AS good_name,
	c.name AS cat_name
FROM products p 
JOIN catalogs c ON p.catalog_id = c.id;

SELECT * FROM cat_prod;

-- part 1 task 3
-- (по желанию) Пусть имеется таблица с календарным полем created_at. 
-- В ней размещены разряженые календарные записи за август 2018 года '2018-08-01', '2016-08-04', '2018-08-16' и 2018-08-17. 
-- Составьте запрос, который выводит полный список дат за август, выставляя в соседнем поле значение 1, 
-- если дата присутствует в исходном таблице и 0, если она отсутствует.

CREATE TABLE IF NOT EXISTS calendar (
created_at DATE
);

INSERT INTO calendar VALUES
	('2018-08-01'),
	('2018-08-16'),
	('2018-08-16'),
	('2018-08-17');

SELECT * FROM calendar;

SELECT 
	date_list.selected_date AS day_,
	(SELECT EXISTS (SELECT created_at FROM calendar WHERE created_at = day_)) AS exists_day
	FROM
(SELECT * FROM 
(SELECT adddate('1970-01-01',t4*10000 + t3*1000 + t2*100 + t1*10 + t0) selected_date FROM
 (SELECT 0 t0 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t0,
 (SELECT 0 t1 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t1,
 (SELECT 0 t2 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t2,
 (SELECT 0 t3 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t3,
 (SELECT 0 t4 UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t4) v
WHERE selected_date BETWEEN '2018-08-01' AND '2018-08-31') AS date_list;


-- part 1 task 4
-- (по желанию) Пусть имеется любая таблица с календарным полем created_at. 
-- Создайте запрос, который удаляет устаревшие записи из таблицы, оставляя только 5 самых свежих записей.

CREATE TABLE IF NOT EXISTS calendar2 (
created_at DATETIME
);
INSERT INTO calendar2 VALUES 
	(NOW()),
	(NOW() - INTERVAL 1 DAY ),
	(NOW() - INTERVAL 2 DAY ),
	(NOW() - INTERVAL 3 DAY ),
	(NOW() - INTERVAL 4 DAY ),
	(NOW() - INTERVAL 5 DAY ),
	(NOW() - INTERVAL 6 DAY ),
	(NOW() - INTERVAL 7 DAY ),
	(NOW() - INTERVAL 8 DAY ),
	(NOW() - INTERVAL 9 DAY ),
	(NOW() - INTERVAL 10 DAY );

-- 5 самых свежих
SELECT * FROM calendar2 ORDER BY created_at DESC LIMIT 5;
-- выбрать все кроме 5 самых свежих
SELECT created_at FROM calendar2 
	WHERE created_at NOT IN (SELECT * FROM
		(SELECT * FROM calendar2 ORDER BY created_at DESC LIMIT 5) AS limitation);
-- а теперь удалить
DELETE FROM calendar2 WHERE 
created_at NOT IN (SELECT * FROM
		(SELECT * FROM calendar2 ORDER BY created_at DESC LIMIT 5) AS limitation);

SELECT * FROM calendar2 ORDER BY created_at DESC;


-- part 2 task 1 
-- Создайте двух пользователей которые имеют доступ к базе данных shop. 
-- Первому пользователю shop_read должны быть доступны только запросы на чтение данных, 
-- второму пользователю shop — любые операции в пределах базы данных shop.

-- право доступа к shop с localhost для чтения
GRANT SELECT ON shop.* TO 'shop_read'@'localhost' IDENTIFIED WITH sha256_password BY 'pass';
-- право доступа к shop с localhost для любых действий
GRANT ALL ON shop.* TO 'shop'@'localhost' IDENTIFIED WITH sha256_password BY 'pass';


-- part 3 task 1
-- Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. 
-- С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать 
-- фразу "Добрый день", с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".
SELECT CURTIME();

DROP PROCEDURE IF EXISTS hello;
DELIMITER &&
CREATE PROCEDURE hello()
BEGIN
	IF (CURTIME() BETWEEN '06:00:00' AND '12:00:00') THEN SELECT 'Доброе утро';
	ELSEIF (CURTIME() BETWEEN '12:00:01' AND '18:00:00') THEN SELECT 'Добрый день';
	ELSE SELECT 'Добрый вечер';
	END IF;
END &&
DELIMITER ;

CALL hello(); 

# part 3 task 2
-- В таблице products есть два текстовых поля: name с названием товара и description с его описанием. 
-- Допустимо присутствие обоих полей или одно из них. Ситуация, когда оба поля принимают неопределенное 
-- значение NULL неприемлема. Используя триггеры, добейтесь того, чтобы одно из этих полей 
-- или оба поля были заполнены. При попытке присвоить полям NULL-значение необходимо отменить операцию.

SELECT * FROM products;

DROP TRIGGER IF EXISTS check_null;
DELIMITER $$
CREATE TRIGGER check_null BEFORE INSERT ON products
FOR EACH ROW 
BEGIN 
	IF (ISNULL(NEW.name) AND ISNULL(NEW.desription)) THEN
  		SIGNAL SQLSTATE '12345'
    	SET MESSAGE_TEXT = 'NULL for name or description is unacceptably';
	END IF;
END$$
DELIMITER ;

INSERT INTO products VALUES (NULL, NULL, NULL, 7000, 1, DEFAULT, DEFAULT); -- ERROR
INSERT INTO products VALUES (NULL, 'text', NULL, 7000, 1, DEFAULT, DEFAULT);
INSERT INTO products VALUES (NULL, NULL, 'text', 7000, 1, DEFAULT, DEFAULT);
INSERT INTO products VALUES (NULL, 'text', 'text', 7000, 1, DEFAULT, DEFAULT);

DROP TRIGGER IF EXISTS check_null_upt;
DELIMITER $$
CREATE TRIGGER check_null_upt BEFORE UPDATE ON products
FOR EACH ROW 
BEGIN 
	IF ((ISNULL(NEW.name) AND ISNULL(OLD.desription)) OR (ISNULL(NEW.desription) AND ISNULL(OLD.name))
		OR (ISNULL(NEW.name) AND ISNULL(NEW.desription))) THEN
  		SIGNAL SQLSTATE '12345'
    	SET MESSAGE_TEXT = 'NULL for both name or description is unacceptably';
	END IF;
END$$
DELIMITER ;

UPDATE products SET name = NULL WHERE id = 8;
UPDATE products SET desription = NULL WHERE id = 9;
UPDATE products SET name = NULL, desription = NULL WHERE id = 10;
UPDATE products SET name = 'google' WHERE id = 8;


# part 3 task 3
-- (по желанию) Напишите хранимую функцию для вычисления произвольного числа Фибоначчи. 
-- Числами Фибоначчи называется последовательность в которой число равно сумме двух предыдущих чисел. 
-- Вызов функции FIBONACCI(10) должен возвращать число 55.

DROP FUNCTION IF EXISTS fibo;

/* as occures: recursive functions are not allowed in MySQL
DELIMITER //
CREATE FUNCTION fibo (n INT)
RETURNS INT DETERMINISTIC
BEGIN
	IF ((n = 1) OR (n = 2)) THEN
		RETURN 1;
	ELSE
		RETURN fibo(n - 1) + fibo(n - 2);
	END IF;
END //
DELIMITER ; */

DELIMITER //
CREATE FUNCTION fibo (n INT)
	RETURNS INT DETERMINISTIC
BEGIN
	DECLARE a BIGINT UNSIGNED DEFAULT 0;
	DECLARE b BIGINT UNSIGNED DEFAULT 1;
	DECLARE i INT DEFAULT 0;
	DECLARE tmp BIGINT UNSIGNED DEFAULT 0;
	IF ((n = 1) OR (n = 2)) THEN
		RETURN 1;
	ELSE
		WHILE i < n DO
			SET tmp = a;
			SET a = b;
			SET b = tmp + b;
			SET i = i + 1;
		END WHILE;
		RETURN a; -- работает для небольших значений n, так как BIGINT ограничен
	END IF;
END //
DELIMITER ;

SELECT fibo(10) AS FIBO;





