DROP DATABASE IF EXISTS vk;
CREATE DATABASE IF NOT EXISTS vk;
ALTER DATABASE `vk`
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;


-- используем БД vk
USE vk;

CREATE TABLE users(
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	first_name VARCHAR(150) NOT NULL COMMENT "Имя", 
	last_name VARCHAR(150) NOT NULL,
	email VARCHAR(150) NOT NULL UNIQUE,
	phone CHAR(11) NOT NULL,
	password_hash CHAR(80) DEFAULT NULL,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- NOW()
	INDEX users_email_idx (email),
	UNIQUE INDEX users_phone_unique_idx (phone) 
);

CREATE TABLE not_banned_users (
	id SERIAL PRIMARY KEY,
	not_banned_id BIGINT UNSIGNED NOT NULL,
	banned_id BIGINT UNSIGNED NOT NULL,
	KEY (not_banned_id),
	CONSTRAINT not_banned FOREIGN KEY (not_banned_id) REFERENCES users (id)
);

-- 1:1 связь
CREATE TABLE profiles (
	user_id SERIAL PRIMARY KEY, -- ? BIGINT UNSIGNED PRIMARY KEY
	gender ENUM('f', 'm', 'x'),
	birthday DATE NOT NULL,
	photo_id BIGINT UNSIGNED,
	city VARCHAR(130),
	country VARCHAR(130),
	FOREIGN KEY (user_id) REFERENCES users(id)	
);

-- описание таблицы
DESCRIBE users;
DESCRIBE profiles;

-- скрипт создания таблицы
SHOW CREATE TABLE users;

CREATE TABLE media (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	media_types_id BIGINT UNSIGNED NOT NULL,
	file_name VARCHAR(200),
	file_size BIGINT UNSIGNED,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	INDEX media_media_types_idx (media_types_id),
  	INDEX media_users_idx (user_id)
);

CREATE TABLE media_types (
	id SERIAL PRIMARY KEY,
	name VARCHAR(200) NOT NULL UNIQUE
);

-- добавляем
INSERT INTO media_types VALUES (DEFAULT, 'изображение');
INSERT INTO media_types VALUES (DEFAULT, 'музыка');
INSERT INTO media_types VALUES (DEFAULT, 'документ');

-- добавляем внешний ключ
ALTER TABLE media ADD FOREIGN KEY (media_types_id) REFERENCES media_types(id);

-- добавляем внешний ключ с именем ограничения
ALTER TABLE media ADD CONSTRAINT fk_media_users FOREIGN KEY (user_id) REFERENCES users(id);

CREATE TABLE messages (
	id SERIAL PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
	to_user_id BIGINT UNSIGNED NOT NULL,
	banned ENUM('0', '1'),
	txt TEXT NOT NULL,
	is_delivered BOOL DEFAULT false,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	KEY (from_user_id),
	KEY (to_user_id),
	CONSTRAINT fk_messages_users_1 FOREIGN KEY (from_user_id) REFERENCES users (id),
	CONSTRAINT fk_messages_users_2 FOREIGN KEY (to_user_id) REFERENCES users (id),
	CONSTRAINT fk_messages_users_3 FOREIGN KEY (from_user_id) REFERENCES not_banned_users (not_banned_id)
);

CREATE TABLE friend_requests (
  from_user_id BIGINT UNSIGNED NOT NULL,
  to_user_id BIGINT UNSIGNED NOT NULL,
  accepted BOOLEAN DEFAULT False,
  PRIMARY KEY (from_user_id, to_user_id),
  KEY (from_user_id),
  KEY (to_user_id),
  CONSTRAINT fk_friend_requests_users_1 FOREIGN KEY (from_user_id) REFERENCES users (id),
  CONSTRAINT fk_friend_requests_users_2 FOREIGN KEY (to_user_id) REFERENCES users (id)
);

CREATE TABLE communities (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(145) NOT NULL,
  description VARCHAR(245) DEFAULT NULL
);

-- Таблица связи пользователей и сообществ
CREATE TABLE communities_users (
	community_id BIGINT UNSIGNED NOT NULL,
	user_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (community_id, user_id),
	KEY (community_id),
  	KEY (user_id),
  	CONSTRAINT fk_communities_users_comm FOREIGN KEY (community_id) REFERENCES communities (id),
  	CONSTRAINT fk_communities_users_users FOREIGN KEY (user_id) REFERENCES users (id)
);

-- заполняем таблицы данными
-- Заполним таблицу, добавим Петю и Васю
INSERT INTO users VALUES (DEFAULT, 'Petya', 'Petukhov', 'petya@mail.com', '89212223334', DEFAULT, DEFAULT);
INSERT INTO users VALUES (DEFAULT, 'Vasya', 'Vasilkov', 'vasya@mail.com', '89212023334', DEFAULT, DEFAULT);

INSERT INTO profiles VALUES (1, 'm', '1997-12-01', NULL, 'Moscow', 'Russia'); -- профиль Пети
INSERT INTO profiles VALUES (2, 'm', '1988-11-02', NULL, 'Moscow', 'Russia'); -- профиль Васи

INSERT INTO not_banned_users VALUES (DEFAULT, 1, 1), (DEFAULT, 2, 2);

-- вызовет ошибку
#INSERT INTO profiles VALUES (3, 'm', '1988-11-02', NULL, 'Moscow', 'Russia'); -- профиль Васи

-- Добавим два сообщения от Пети к Васе, одно сообщение от Васи к Пете
INSERT IGNORE INTO messages VALUES (DEFAULT, 1, 2, '0', 'Hi!', 1, DEFAULT, DEFAULT); -- сообщение от Пети к Васе номер 1
INSERT IGNORE INTO messages VALUES (DEFAULT, 1, 2, '0', 'Vasya!', 1, DEFAULT, DEFAULT); -- сообщение от Пети к Васе номер 2
INSERT IGNORE INTO messages VALUES (DEFAULT, 2, 1, '1', 'Hi, Petya', 1, DEFAULT, DEFAULT); -- сообщение от Пети к Васе номер 2

-- Добавим запрос на дружбу от Пети к Васе
INSERT INTO friend_requests VALUES (1, 2, 1);

-- Добавим сообщество 
INSERT INTO communities VALUES (DEFAULT, 'Number1', 'I am number one');

-- Добавим запись вида Вася участник сообщества Number 1
INSERT INTO communities_users VALUES (1, 2);

-- Добавим два изображения, которые добавил Петя
INSERT INTO media VALUES (DEFAULT, 1, 1, 'im.jpg', 100, DEFAULT);
INSERT INTO media VALUES (DEFAULT, 1, 1, 'im1.png', 78, DEFAULT);
-- Добавим документ, который добавил Вася
INSERT INTO media VALUES (DEFAULT, 2, 3, 'doc.docx', 1024, DEFAULT);

-- Добавим колонку с номером паспорта
ALTER TABLE users ADD COLUMN passport_number VARCHAR(10);

-- Изменим ее тип
ALTER TABLE users MODIFY COLUMN passport_number VARCHAR(20);

-- Переименуем ее: У МЕНЯ КОМАНДА rename не работает
ALTER TABLE users change COLUMN passport_number passport varchar(10);

-- Добавим уникальный индекс на колонку
ALTER TABLE users ADD KEY passport_idx (passport);

-- Удалим индекс
ALTER TABLE users DROP INDEX passport_idx;

-- Удалим колонку
ALTER TABLE users DROP COLUMN passport;

-- совершенствуем таблицу дружбы
-- добавляем ограничение, что отправитель запроса на дружбу 
-- не может быть одновременно и получателем
ALTER TABLE friend_requests 
ADD CONSTRAINT sender_not_reciever_check 
CHECK (from_user_id != to_user_id);

-- добавляем ограничение, что номер телефона должен состоять из 11
-- символов и только из цифр
ALTER TABLE users 
ADD CONSTRAINT phone_check
CHECK (REGEXP_LIKE(phone, '^[0-9]{11}$'));

DESCRIBE users;

/*
усовершенствовать структуру
добавить таблицу с лайками
*/
ALTER TABLE users 
ADD CONSTRAINT email_check
CHECK (REGEXP_LIKE(email, '^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$'));

-- ни валидация по регулярным выражениям, ни иные инструкции с
-- с CHECK не работают через добавление ограничения в таблицу, реализовал через триггер
-- согласно документации mysql в версиях до 8.0.16 check может быть вставлен в код но не выполняется
-- у меня установлена версия 8.0.0, так как моя ОС (MAC OS 10.11 - выше не обновляется, старый ПК), 
-- поэтому фактически проверить работу CHECK не могу

ALTER TABLE messages 
ADD CONSTRAINT some_check 
CHECK (banned like '1');

INSERT INTO messages VALUES (DEFAULT, 1, 1, '0', 'Hi, Petya', 1, DEFAULT, DEFAULT); -- сообщение от Пети к Васе номер 2

DROP TRIGGER IF EXISTS email_valid_check;

DELIMITER $$
CREATE TRIGGER email_valid_check BEFORE INSERT ON users
FOR EACH ROW 
BEGIN 
IF (NEW.email REGEXP '^([a-z0-9_\.-]+\@[\da-z\.-]+\.[a-z\.]{2,6})$') = 0 THEN 
  SIGNAL SQLSTATE '12345'
     SET MESSAGE_TEXT = 'Invalid email';
END IF;
IF (NEW.phone REGEXP '^[0-9]{11}$') = 0 THEN
	SIGNAL SQLSTATE '12345'
    	SET MESSAGE_TEXT = 'Invalid phone number';
END IF;
END$$
DELIMITER ;

-- дает ошибку invalid email / invalid phone number
#INSERT INTO users VALUES (DEFAULT, 'Vasya', 'Vasilkov', 'va&s%ya@mail.com', '89212553334', DEFAULT, DEFAULT);
#INSERT INTO users VALUES (DEFAULT, 'Vasya', 'Vasilkov', 'va1sya@mail.com', '89212f53334', DEFAULT, DEFAULT);

DROP TABLE IF EXISTS tags;
CREATE TABLE tags (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL COMMENT 'user who created tag',
	tag_id BIGINT UNSIGNED NOT NULL,
	tag_content CHAR(45) NOT NULL,
	KEY (user_id),
	UNIQUE INDEX (tag_id),
	CONSTRAINT user_id_tag FOREIGN KEY (user_id) REFERENCES users (id),
	CONSTRAINT not_banned_tagger FOREIGN KEY (user_id) REFERENCES not_banned_users (not_banned_id)
);

INSERT INTO tags VALUES (0, 1, 1, '#mysql_basics'), (DEFAULT, 2, 2, '#MachineDeepLearning');

DROP TABLE IF EXISTS comments;
CREATE TABLE comments (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	comment_id BIGINT UNSIGNED NOT NULL,
	comment_content TEXT,
	KEY (user_id),
	UNIQUE KEY (comment_id),
	CONSTRAINT user_id_comment FOREIGN KEY (user_id) REFERENCES users (id),
	CONSTRAINT not_banned_commentator FOREIGN KEY (user_id) REFERENCES not_banned_users (not_banned_id)
);

INSERT INTO comments VALUES (0, 1, 1, 'Usefull dataset :)'), (DEFAULT, 2, 2, 'You are a cheater!');

DROP TABLE IF EXISTS posts;
CREATE  TABLE IF NOT EXISTS posts (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL,
	post_id BIGINT UNSIGNED NOT NULL,
	post_content TEXT,
	UNIQUE KEY (post_id),
	CONSTRAINT user_id_post FOREIGN KEY (user_id) REFERENCES users (id)
);

INSERT INTO posts VALUES (0, 1, 1, 'Complete Guide to CycleGAN with tensorflow'), (DEFAULT, 2, 2, 'Using Dropout layer with Deep CNN in Pytorch');


ALTER TABLE profiles ADD COLUMN rating BIGINT DEFAULT 0 COMMENT 'number of likes for user';

-- можно добавить счетчик лайков непосредственно в таблицу tag, но нужно смотреть кто поставил лайк
DROP TABLE IF EXISTS tag_like;
CREATE TABLE tag_like (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'user who set like',
	tag_id BIGINT UNSIGNED NOT NULL COMMENT 'link',
	tag_like_count BIGINT UNSIGNED DEFAULT 0 COMMENT 'to be updated after next like',
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY (tag_id),
	CONSTRAINT user_id_action_1 FOREIGN KEY (user_id) REFERENCES users (id),
	CONSTRAINT user_id_action_2 FOREIGN KEY (tag_id) REFERENCES tags (tag_id)
);

INSERT INTO tag_like VALUES (DEFAULT, 1, 1, 1, DEFAULT, DEFAULT);
UPDATE  tag_like SET tag_like_count = tag_like_count  + 1 WHERE tag_id = 1;
SELECT * FROM tag_like;

DROP TABLE IF EXISTS media_like;
CREATE TABLE media_like (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'user who set like',
	media_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'link',
	media_like_count BIGINT UNSIGNED DEFAULT 0,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY (media_id),
	CONSTRAINT user_id_action_3 FOREIGN KEY (user_id) REFERENCES users (id),
	CONSTRAINT user_id_action_4 FOREIGN KEY (media_id) REFERENCES media (media_types_id)
);

INSERT INTO media_like VALUES (DEFAULT, 2, 1, 1, DEFAULT, DEFAULT);


DROP TABLE IF EXISTS comment_like;
CREATE TABLE comment_like (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'user who set like',
	comment_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'link',
	comment_like_count BIGINT UNSIGNED DEFAULT 0,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY (comment_id),
	CONSTRAINT user_id_action_5 FOREIGN KEY (user_id) REFERENCES users (id),
	CONSTRAINT user_id_action_6 FOREIGN KEY (comment_id) REFERENCES comments (comment_id)
);

INSERT INTO comment_like VALUES (DEFAULT, 1, 1, 1, DEFAULT, DEFAULT);


DROP TABLE IF EXISTS post_like;
CREATE TABLE post_like (
	id SERIAL PRIMARY KEY,
	user_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'user who set like',
	post_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'link',
	post_like_count BIGINT UNSIGNED DEFAULT 0,
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	UNIQUE KEY (post_id),
	CONSTRAINT user_id_action_7 FOREIGN KEY (user_id) REFERENCES users (id),
	CONSTRAINT user_id_action_8 FOREIGN KEY (post_id) REFERENCES posts (post_id)
);

INSERT INTO post_like VALUES (DEFAULT, 2, 2, 1, DEFAULT, DEFAULT);





