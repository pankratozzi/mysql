USE shop;
# task 1 part 1
# Пусть в таблице users поля created_at и updated_at оказались незаполненными. 
# Заполните их текущими датой и временем.

SELECT * FROM users;
DESCRIBE users;
UPDATE users SET created_at = NOW(), updated_at = NOW() WHERE created_at IS NULL OR updated_at IS NULL;

#task 2 part 1 
# Таблица users была неудачно спроектирована. 
# Записи created_at и updated_at были заданы типом VARCHAR и в них долгое время помещались
# значения в формате 20.10.2017 8:10. Необходимо преобразовать поля к типу DATETIME, 
# сохранив введённые ранее значения.

ALTER TABLE users CHANGE COLUMN created_at created_at VARCHAR(200) NULL;
ALTER TABLE users CHANGE COLUMN updated_at updated_at VARCHAR(200) NULL;
UPDATE users SET created_at = '20.10.2017 8:10', updated_at = '20.10.2017 8:10'

UPDATE users SET created_at = str_to_date(created_at, '%d.%m.%Y %h:%i'), 
	updated_at = str_to_date(updated_at, '%d.%m.%Y %h:%i');
	
ALTER TABLE users CHANGE created_at created_at DATETIME DEFAULT CURRENT_TIMESTAMP(); 
ALTER TABLE users CHANGE updated_at updated_at DATETIME DEFAULT CURRENT_TIMESTAMP();

# task 3 part 1
# В таблице складских запасов storehouses_products в поле value 
# могут встречаться самые разные цифры: 0, если товар закончился и выше нуля, 
# если на складе имеются запасы. Необходимо отсортировать записи таким образом, 
# чтобы они выводились в порядке увеличения значения value. 
# Однако нулевые запасы должны выводиться в конце, после всех записей.

SELECT * FROM storehouses_products;
SELECT id, value FROM storehouses_products ORDER BY CASE WHEN 
	value = 0 THEN (SELECT MAX(value) + 1 FROM storehouses_products) ELSE value END;

# task 4 part 1
# (по желанию) Из таблицы users необходимо извлечь пользователей, 
# родившихся в августе и мае. Месяцы заданы в виде списка английских названий (may, august)

SELECT name, birthday_at, CASE
	WHEN MONTH(birthday_at) = 5 THEN 'may'
	WHEN MONTH(birthday_at) = 8 THEN 'august'
	END AS month_name
	FROM users WHERE MONTH(birthday_at) = 5 OR MONTH(birthday_at) = 8
	ORDER BY month_name;

SELECT GROUP_CONCAT(name ORDER BY name DESC SEPARATOR ' ') AS user_names, MONTHNAME(birthday_at) AS name_month
	FROM users WHERE MONTH(birthday_at) = 5 OR MONTH(birthday_at) = 8
		GROUP BY name_month ORDER BY name_month DESC;

# task 5 part 1
# (по желанию) Из таблицы catalogs извлекаются записи при помощи запроса. 
# SELECT * FROM catalogs WHERE id IN (5, 1, 2); Отсортируйте записи в порядке, 
# заданном в списке IN.

SELECT * FROM catalogs;
SELECT * FROM catalogs WHERE id IN (5, 1, 2) ORDER BY CASE 
	WHEN id = 5 THEN 0
	WHEN id = 1 THEN 1
	WHEN id = 2 THEN 2
	END;

SELECT * FROM catalogs WHERE id IN (5, 1, 2) ORDER BY FIELD(id, 5, 1, 2); 


# task 1 part 2
# Подсчитайте средний возраст пользователей в таблице users.

SELECT ROUND(AVG(TO_DAYS(NOW()) - TO_DAYS(birthday_at)) / 365.25, 0) AS average_age FROM users; 

SELECT FLOOR(AVG(TIMESTAMPDIFF(YEAR, birthday_at, NOW()))) AS average_age FROM users;

# task 2 part 2
# Подсчитайте количество дней рождения, которые приходятся на каждый из дней недели. Следует учесть, 
# что необходимы дни недели текущего года, а не года рождения.

SELECT COUNT(*) AS cnt, DAYNAME(CONCAT(YEAR(NOW()), '-', MONTH(birthday_at), '-', DAY(birthday_at))) AS wd, 
	GROUP_CONCAT(name ORDER BY name ASC SEPARATOR '/') AS names FROM users GROUP BY wd ORDER BY cnt, names;

SELECT DATE_FORMAT(DATE(CONCAT_WS('-', YEAR(NOW()), MONTH(birthday_at), DAY(birthday_at))), '%W') AS day_name,
	COUNT(*) AS counter FROM users GROUP BY day_name ORDER BY counter DESC;

SELECT DATE_FORMAT(DATE(CONCAT_WS('-', YEAR(NOW()), MONTH(birthday_at), DAY(birthday_at))), '%W') AS day_name,
	COUNT(*) AS counter FROM users GROUP BY day_name WITH ROLLUP;

#task 3 part 2
##task3 part2
# (по желанию) Подсчитайте произведение чисел в столбце таблицы.

SELECT FLOOR(EXP(SUM(LOG(value)))) AS product FROM storehouses_products WHERE value != 0;
SELECT FLOOR(EXP(SUM(LN(value)))) AS product FROM storehouses_products WHERE value != 0;





