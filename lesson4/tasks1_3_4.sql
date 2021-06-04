#############################################
### task 1 ### в дополнение к файлу из урока постарался 
# применить наиболее интересные (как мне показалось) варианты использования CRUD команд
USE vk_les; # это дубль учебной БД

select sql_calc_found_rows 
US.id, 
US.email, 
US.phone, 
MS.from_user_id, 
MS.to_user_id, 
MS.txt 
from users US left join messages MS on 
MS.created_at BETWEEN (CURRENT_TIMESTAMP() - interval 3 day) and CURRENT_TIMESTAMP() and
US.id = MS.from_user_id 
where 
email regexp '^([a-z0-9_\.-]+\@[\da-z\.-]+\.[a-z\.]{2,6})$'
order by US.email asc limit 0, 4;

select concat(substring(users.firstname, 1,1), '. ', users.lastname) as name, users.email, profiles.gender, 
if (profiles.gender = 'x', 'transgender', profiles.gender) as cond
from users left join profiles on users.id = profiles.user_id 
where year(users.created_at) between '2010' and '2015'
order by users.id desc limit 5, 50; 

select distinct firstname from users where phone regexp '^[0-9]{11}$';

SELECT CASE 
	WHEN name = 'image' THEN 'picture'
	WHEN name = 'audio' THEN 'song'
	WHEN name = 'video' THEN 'movie'
	WHEN name = 'document' THEN 'poem'
END AS syn
FROM media_types mt ORDER BY id;

SELECT name, CONCAT(SUBSTRING(description, 1, 15), '...') FROM communities WHERE id <= 10 AND name LIKE 'a%';

SELECT CONCAT(COUNT(is_delivered), ' delivered messages') FROM messages;

SELECT CONCAT(users.firstname, ' ', users.lastname) as name, media.file_name, media_types.name, DAYNAME(media.created_at) 
as week_day, IF(media.file_name IS NULL, 'NO DATA', media.file_name) AS cond2 FROM
	users LEFT JOIN media ON users.id = media.user_id LEFT JOIN media_types ON media.media_types_id = media_types.id
		ORDER BY users.id DESC LIMIT 15;

UPDATE profiles SET birthday = birthday + INTERVAL 1 YEAR WHERE user_id = 1;

UPDATE profiles INNER JOIN users ON users.id = profiles.user_id SET profiles.city = 'Moscow' 
	WHERE users.lastname LIKE '%in' OR users.lastname LIKE '%ov';

INSERT vk.communities SET name = 'Python Geeks', description = 'advanced python tips';
INSERT IGNORE INTO communities SELECT (vk.communities.id + 200), vk.communities.name, vk.communities.description 
	FROM vk.communities WHERE vk.communities.name LIKE '%yth%';

DELETE FROM communities WHERE id = 202;

### task 3 ###

UPDATE media_types 
SET name = ELT(FIELD(id, 1, 2, 3, 4), 'image', 'audio', 'video', 'document') 
WHERE id IN (1, 2, 3, 4);

SELECT * FROM friend_requests WHERE from_user_id = to_user_id;
DELETE FROM friend_requests WHERE from_user_id = to_user_id;

### task 4 ###

# планирую взять тему курсовой: база данных популярного стримингого сервиса (онлайн кинотеатра), например, NetFlix
# но это неточно, не слишком оригинально :)