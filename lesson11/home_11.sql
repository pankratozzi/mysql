USE shop;

-- part 1 task 1
/* Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users, 
catalogs и products в таблицу logs помещается время и дата создания записи, название таблицы, 
идентификатор первичного ключа и содержимое поля name.
*/

DROP TABLE IF EXISTS logs;
CREATE TABLE logs (
	created_at DATETIME NOT NULL,
	table_name VARCHAR (40) NOT NULL,
	id_prk BIGINT UNSIGNED NOT NULL,
	name_content VARCHAR(100) NOT NULL
) ENGINE = ARCHIVE;

DROP TRIGGER IF EXISTS users_add;
DELIMITER //
CREATE TRIGGER users_add AFTER INSERT ON users
FOR EACH ROW 
BEGIN 
	INSERT INTO logs (created_at, table_name, id_prk, name_content)
	VALUES (NOW(), 'users', NEW.id, NEW.name);
END //
DELIMITER ;

DROP TRIGGER IF EXISTS catalogs_add;
DELIMITER //
CREATE TRIGGER catalogs_add AFTER INSERT ON catalogs
FOR EACH ROW 
BEGIN 
	INSERT INTO logs (created_at, table_name, id_prk, name_content)
	VALUES (NOW(), 'catalogs', NEW.id, NEW.name);
END //
DELIMITER ;

DROP TRIGGER IF EXISTS products_add;
DELIMITER //
CREATE TRIGGER products_add AFTER INSERT ON products
FOR EACH ROW 
BEGIN 
	INSERT INTO logs (created_at, table_name, id_prk, name_content)
	VALUES (NOW(), 'products', NEW.id, NEW.name);
END //
DELIMITER ;

-- simple test

INSERT INTO users VALUES
	(NULL, 'ILON', '1982-08-05', DEFAULT, DEFAULT),
	(NULL, 'SHMILON', '1892-05-08', DEFAULT, DEFAULT);

SELECT * FROM logs;

INSERT INTO catalogs VALUES
	(NULL, 'notebooks'),
	(NULL, 'placeholders');

SELECT * FROM logs;

INSERT INTO products VALUES
	(NULL, 'iname', 'idescription', 123.35, 1, DEFAULT, DEFAULT),
	(NULL, 'jname', 'jdescription', 321.53, 2, DEFAULT, DEFAULT);

SELECT * FROM logs;


-- part 1 task 2
-- (по желанию) Создайте SQL-запрос, который помещает в таблицу users миллион записей.

-- use table user1, because 1000000 - is a very long time insertion, meanwhile users have some triggers on 
-- isertion (into table logs as well) -> there's another 1000000 insertions, hmm...

DROP PROCEDURE IF EXISTS crazy_insert;
DELIMITER //
CREATE PROCEDURE crazy_insert (num INT UNSIGNED)
BEGIN
	DECLARE idx INT DEFAULT 0;
	WHILE num > 0 DO
		INSERT INTO users1 (name, birthday_at) VALUES (CONCAT('user_no_', idx), CURDATE() - INTERVAL idx DAY);
		SET idx = idx + 1;
		SET num = num - 1;
	END WHILE;
END //
DELIMITER ;

CALL crazy_insert(1000000); -- insertion went until reached date 0000-00-00 :) - 737970 iterations
SELECT COUNT(*) FROM users1;
TRUNCATE users1;

-- part 2 task 1
-- have no Redis server, cannot check any results

-- В базе данных Redis подберите коллекцию для подсчета посещений с определенных IP-адресов.

SADD ip '192.168.0.22' '192.168.0.23' '192.168.0.24' '192.168.0.25'

SMEMBERS ip
SCARD ip

SET ip1 0
INCR ip1
GET ip1

-- part 2 task 2
/* При помощи базы данных Redis решите задачу поиска имени пользователя по электронному адресу и наоборот, 
поиск электронного адреса пользователя по его имени. */

-- key - email or name
SET 123@mail.ru user1
SET user1 123@mail.ru

GET 123@mail.ru
GET user1


-- part 2 task 3

-- Организуйте хранение категорий и товарных позиций учебной базы данных shop в СУБД MongoDB.

use products

db.products.insertMany([{'name': 'Intel 123', 'description': 'processor 123', 'price': '3000', 
						'catalog_id': 'Processors', 'created_at': new Date(), 'updated_at': new Date()},
						{'name': 'AMD 123', 'description': 'processor a123', 'price': '3200', 
						'catalog_id': 'Processors', 'created_at': new Date(), 'updated_at': new Date()}])

db.products.find().pretty()
db.products.find(){'name': 'Intel 123'}.pretty()

use catalogs

db.products.insert({'name': 'LCDs'})























