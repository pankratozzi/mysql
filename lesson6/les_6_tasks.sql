# task 1
# Проанализировать запросы, которые выполнялись на занятии, определить возможные корректировки 
# и/или улучшения (JOIN пока не применять).

SELECT firstname, lastname,
	(SELECT city FROM profiles WHERE user_id = users.id) AS city,
	(SELECT file_name FROM media WHERE id = (SELECT photo_id FROM profiles WHERE user_id = users.id)) AS profile_photo
FROM users WHERE id = 1;

SELECT DISTINCT IF(to_user_id = 1, from_user_id, to_user_id) AS friend
FROM friend_requests 
WHERE request_type = 1 AND (from_user_id = 1 OR to_user_id = 1);

SET @rt_id := (SELECT id FROM friend_requests_types WHERE name LIKE 'acc%');
SELECT firstname, lastname
FROM users WHERE id IN (
	SELECT to_user_id FROM friend_requests WHERE from_user_id = 1 AND
		request_type = @rt_id
		UNION
	SELECT from_user_id FROM friend_requests WHERE to_user_id = 1 AND 
		request_type = @rt_id ) AND id IN (SELECT user_id FROM communities_users) ORDER BY lastname;

SELECT name, admin_id 
FROM communities AS c WHERE c.id IN (SELECT community_id FROM communities_users cu WHERE
	cu.user_id IN (SELECT id FROM users u WHERE u.id BETWEEN 1 AND 10)) 
	AND c.admin_id IN (SELECT id FROM users u WHERE id IN (
	SELECT to_user_id FROM friend_requests WHERE from_user_id = 5 AND
		request_type = @rt_id
		UNION
	SELECT from_user_id FROM friend_requests WHERE to_user_id = 5 AND 
		request_type = @rt_id));

# просто попробовал, знаю про запрет JOIN в задании
SELECT DISTINCT GROUP_CONCAT(u.lastname), c.name AS name FROM users u JOIN communities_users cu ON u.id = cu.user_id 
	JOIN communities c ON c.id = cu.community_id GROUP BY name ORDER BY name;

SELECT c.name, c.admin_id, CONCAT(u.firstname, ' ', u.lastname) AS admin_friends_myuser
FROM communities AS c JOIN users u ON c.admin_id = u.id  WHERE c.id IN 
	(SELECT community_id FROM communities_users cu WHERE
	cu.user_id IN (SELECT id FROM users u WHERE u.id BETWEEN 1 AND 10)) 
	AND c.admin_id IN (SELECT id FROM users u WHERE id IN (
	SELECT to_user_id FROM friend_requests WHERE from_user_id = 5 AND
		request_type = @rt_id
		UNION
	SELECT from_user_id FROM friend_requests WHERE to_user_id = 5 AND 
		request_type = @rt_id));

# task 2 
# Пусть задан некоторый пользователь. 
# Из всех друзей этого пользователя найдите человека, который больше всех общался с нашим пользователем.
# пусть задан пользователь с id = 5

# есть ли у нашего пользователя друзья
SELECT COUNT(*) AS friends 
FROM friend_requests AS fr 
	WHERE ((fr.from_user_id = 5 OR fr.to_user_id = 5) AND fr.request_type = 1)
	ORDER BY friends;

SELECT DISTINCT 
IF (from_user_id = 5, to_user_id, from_user_id) AS friends
FROM friend_requests AS fr
	WHERE (fr.from_user_id = 5 OR fr.to_user_id = 5) AND fr.request_type = 1
	
# выведем список его друзей
SELECT DISTINCT CASE 
	WHEN fr.from_user_id = 5 THEN fr.to_user_id 
	WHEN fr.to_user_id = 5 THEN fr.from_user_id 
	END AS case_user
FROM friend_requests AS fr WHERE (fr.from_user_id = 5 OR fr.to_user_id = 5) 
AND fr.request_type = 1;



# выведем список пользователей, отправлявших сообщения нашему пользователю																				
SELECT
    from_user_id, COUNT(*) as send_count 
FROM messages 
WHERE to_user_id=5 AND ()
GROUP BY from_user_id
ORDER BY send_count DESC;
 
# выведем частоту сообщений от пользователей к нашему пользователю и проверим друзья ли они нам
# вывод нескольких пользователей, чтобы отследить случаи, когда есть друзья с одинаковым количеством сообщений
SELECT
    msg.from_user_id, COUNT(*) as send,
    IF(msg.from_user_id IN (SELECT CASE 
		WHEN fr.from_user_id = 5 THEN fr.to_user_id 
		WHEN fr.to_user_id = 5 THEN fr.from_user_id 
	END AS case_user
	FROM friend_requests AS fr WHERE fr.request_type = 1), 'friend', 'no-one')
	AS IF_CASE
FROM messages AS msg 
WHERE msg.to_user_id = 5 AND msg.is_delivered = 1
GROUP BY msg.from_user_id
ORDER BY send DESC LIMIT 5;

# другой вариант, учитывающий сообщения от самого пользователя, поэтому вывод в виде таблицы
# забегая вперед
SET @our_user := 5;
DROP PROCEDURE IF EXISTS listfriends;
DELIMITER //
CREATE PROCEDURE listfriends (IN myuser BIGINT)
BEGIN
SELECT from_user_id AS sender, to_user_id AS reciever, COUNT(*) AS cnt 
	FROM messages 
	WHERE (from_user_id = myuser OR to_user_id = myuser) AND is_delivered = 1 # наш пользователь участник переписки и сообщение доставлено
	AND (to_user_id IN (SELECT DISTINCT 
		IF (from_user_id = myuser, to_user_id, from_user_id) AS friends
		FROM friend_requests AS fr
		WHERE (fr.from_user_id = myuser OR fr.to_user_id = myuser) AND fr.request_type = 1) 
		OR from_user_id IN (SELECT DISTINCT 
		IF (from_user_id = myuser, to_user_id, from_user_id) AS friends
		FROM friend_requests AS fr
		WHERE (fr.from_user_id = myuser OR fr.to_user_id = myuser) AND fr.request_type = 1))
	GROUP BY from_user_id, to_user_id
	ORDER BY (from_user_id = myuser), cnt DESC;
END//
DELIMITER ;

CALL listfriends(@our_user); 


# task 3
#Подсчитать общее количество лайков, которые получили 10 самых молодых пользователей.
# при запросах к profiles постоянно возникала ошибка, что не существует соответсвующей колонки в profiles
# пробовал перезаливать дамп, создавать клоны таблиц, добавлять ключи - в итоге пcиханул и добавил
# две нужные колонки в users - смысл задачи не изменился

ALTER TABLE users ADD COLUMN birthday DATE NOT NULL;
ALTER TABLE users ADD COLUMN gender ENUM('m', 'f', 'x') NOT NULL;

UPDATE users 
SET birthday = (
  SELECT birthday 
  FROM profiles 
  WHERE users.id = profiles.user_id)
WHERE users.birthday IS NULL;

UPDATE users 
SET gender = (
  SELECT gender 
  FROM profiles 
  WHERE users.id = profiles.user_id)
WHERE users.birthday IS NULL;

# вывод в виде списка друг-недруг и сколько сообщений по возрастанию
SELECT id, TIMESTAMPDIFF(YEAR, birthday, NOW()) AS age, (SELECT COUNT(*) AS total FROM posts_likes 
	WHERE like_type = 1 AND user_id = users.id GROUP BY like_type) AS COUNTED_LIKES 
	FROM users GROUP BY id ORDER BY age LIMIT 10;

# общее количество лайков в одной ячейке
SELECT COUNT(*) FROM posts_likes WHERE like_type = 1 AND user_id IN (
	SELECT * FROM (SELECT id FROM users ORDER BY birthday DESC LIMIT 10) AS alias);
# task 4 
# Определить кто больше поставил лайков (всего) - мужчины или женщины?

SELECT IF ((SELECT COUNT(*) FROM posts_likes WHERE like_type = 1 AND user_id IN
		(SELECT id FROM users WHERE gender = 'm')) >
	(SELECT COUNT(*) FROM posts_likes WHERE like_type = 1 AND user_id IN
		(SELECT id FROM users WHERE gender = 'f')), 'male', 'female'
) AS MOST_LIKELY;

# task 5
# Найти 10 пользователей, которые проявляют наименьшую активность в использовании социальной сети.

# список наимение активных пользователей с рабивкой по типу активности
(SELECT CONCAT('Messages sent by user №', from_user_id), 
	COUNT(*) AS counted FROM messages AS msg JOIN users AS us ON from_user_id = us.id 
	GROUP BY from_user_id ORDER BY counted LIMIT 10)
	UNION ALL
(SELECT CONCAT('Posted by user №', user_id), COUNT(*) AS counted_pst FROM posts AS pst JOIN users AS us ON user_id = us.id 
	GROUP BY user_id ORDER BY counted_pst LIMIT 10) 
	UNION ALL
(SELECT CONCAT('Media sent by user №', user_id),
	COUNT(*) AS counted_med FROM media AS med JOIN users AS us ON user_id = us.id 
	GROUP BY user_id ORDER BY counted_med LIMIT 10)
	UNION ALL
(SELECT CONCAT('Requests sent by user №', from_user_id), 
	COUNT(*) AS counted_fr FROM friend_requests AS fr JOIN users AS us ON from_user_id = us.id 
	GROUP BY from_user_id ORDER BY counted_fr LIMIT 10);


# сумма активностей наименее активных пользователей, если допустить, что вес каждой активности одинаков
SELECT id, SUM(counts) AS counts FROM
	(SELECT from_user_id AS id, COUNT(*) AS counts FROM messages GROUP BY from_user_id 
	UNION ALL
	SELECT user_id AS id, COUNT(*) FROM posts GROUP BY user_id
	UNION ALL
	SELECT user_id AS id, COUNT(*) FROM media GROUP BY user_id
	UNION ALL
	SELECT from_user_id AS id, COUNT(*) FROM friend_requests GROUP BY from_user_id ) AS conc_tab
GROUP BY id ORDER BY counts LIMIT 10;



# решение через временные таблицы (дичь)
USE vk;

CREATE TEMPORARY TABLE tbl1 (id INT, cnt INT);
CREATE TEMPORARY TABLE tbl2 (id INT, cnt INT);
CREATE TEMPORARY TABLE tbl3 (id INT, cnt INT);
CREATE TEMPORARY TABLE tbl4 (id INT, cnt INT);

INSERT INTO tbl1  
SELECT from_user_id AS user_id, COUNT(*) AS counted FROM messages AS msg GROUP BY from_user_id;

INSERT INTO tbl2
SELECT user_id, COUNT(*) FROM posts GROUP BY user_id;

INSERT INTO tbl3
SELECT user_id, COUNT(*) FROM media GROUP BY user_id;

INSERT INTO tbl4 
SELECT from_user_id, COUNT(*) FROM friend_requests GROUP BY from_user_id;


SELECT DISTINCT us.id AS not_active_user,
CASE 
	WHEN tbl1.cnt IS NULL THEN (tbl2.cnt + tbl3.cnt + tbl4.cnt)
	WHEN tbl2.cnt IS NULL THEN (tbl1.cnt + tbl3.cnt + tbl4.cnt)
	WHEN tbl3.cnt IS NULL THEN (tbl1.cnt + tbl2.cnt + tbl4.cnt)
	WHEN tbl4.cnt IS NULL THEN (tbl1.cnt + tbl2.cnt + tbl3.cnt)
	ELSE (tbl1.cnt + tbl2.cnt + tbl3.cnt + tbl4.cnt)
	END AS SUMM
FROM users AS us
	LEFT JOIN tbl1 ON us.id = tbl1.id
	LEFT JOIN tbl2 ON us.id = tbl2.id
	LEFT JOIN tbl3 ON us.id = tbl3.id
	LEFT JOIN tbl4 ON us.id = tbl4.id
		ORDER BY SUMM LIMIT 10;
	
-- DROP TABLE tbl1, tbl2, tbl3, tbl4;	
	
	
	
	
	
	
