-- stored views and requests

USE naive_movie_service;

-- simple request: list of jenres watched by people aged 18 to 35, having high rating, using request instead of stored procedure
PREPARE request FROM 
	'SELECT DISTINCT
		j.name AS jenre,
		m.name,
		get_avg_rate(wm.media_id) AS rating
	FROM accounts a 
		JOIN watched_media wm ON a.id = wm.account_id 
		JOIN media m ON m.id = wm.media_id
		JOIN jenres j ON j.id = m.jenre_id
	WHERE (get_avg_rate(wm.media_id) > 7 OR wm.self_rating > 7) AND 
		  (TIMESTAMPDIFF(YEAR, a.birthday, CURDATE()) BETWEEN ? AND ?)
	ORDER BY jenre ASC, rating DESC LIMIT ?';
SET @fst = 18;
SET @scd = 35;
SET @lim = 10;
EXECUTE request USING @fst, @scd, @lim;

-- top-10 rating movie (video)
CREATE OR REPLACE VIEW top10 AS
SELECT 
	get_avg_rate(r.media_id) AS avg_rate, 
	med.name AS name, 
	med.watched AS watched,
	(SELECT name FROM jenres WHERE id = med.jenre_id) AS genre
FROM rating AS r 
JOIN media AS med ON r.media_id = med.id 
GROUP BY r.media_id 
ORDER BY avg_rate DESC, watched DESC LIMIT 10;

SELECT * FROM top10 ORDER BY avg_rate DESC;

-- select producers and actors for every movie 
CREATE OR REPLACE VIEW prod_actors AS
SELECT
	(SELECT name FROM media WHERE id = mt.media_id) AS movie,
	GROUP_CONCAT((SELECT CONCAT(SUBSTRING(firstname, 1, 1), '. ', lastname) 
	FROM producers WHERE id = mt.producer_id) SEPARATOR ', ') AS producer,
	GROUP_CONCAT((SELECT CONCAT(SUBSTRING(firstname, 1, 1), '. ', lastname) 
	FROM actors WHERE id = mt.actor_id) SEPARATOR ', ') AS actor
FROM movie_title AS mt 
GROUP BY mt.media_id 
ORDER BY movie;

SELECT * FROM prod_actors;

-- counting identic movie names - for develop purposes only
SELECT COUNT(*), COALESCE((SELECT name FROM media WHERE id = media_id), 'movie_id') AS movie_name 
FROM movie_title GROUP BY media_id WITH ROLLUP;

-- active accounts, who watched most videos and bought the most videos with email. Two ways.
-- first way
CREATE OR REPLACE VIEW active AS
SELECT (SELECT email FROM users WHERE users.id = a2.user_id) AS email,
	   (SELECT nickname FROM users WHERE users.id = a2.user_id) AS nickname,
	   selac.active
FROM accounts a2 JOIN  
	(SELECT idx, SUM(counter) AS active FROM
		(SELECT account_id AS idx, COUNT(*) AS counter FROM watched_media wm 
			JOIN accounts a ON wm.account_id = a.id GROUP BY wm.account_id
			UNION ALL
		 SELECT account_id AS idx, COUNT(*) AS counter FROM bought_media bm 
			JOIN accounts a ON bm.account_id = a.id GROUP BY bm.account_id) AS alias
		 GROUP BY idx ORDER BY active DESC LIMIT 10) AS selac 
	ON a2.id = selac.idx;

SELECT * FROM active;

-- second and more simple way, no need for 'distinct' here as all ids are unique
CREATE OR REPLACE VIEW active_email AS
SELECT 
	firstname, 
	lastname, 
	(SELECT email FROM users WHERE id = accounts.user_id) AS email,
	(SELECT COUNT(*) FROM bought_media WHERE bought_media.account_id = accounts.id) + -- disticnt not needed as all entries are unique
	(SELECT COUNT(*) FROM watched_media WHERE watched_media.account_id = accounts.id) AS overall
FROM accounts 
ORDER BY overall DESC LIMIT 10;

SELECT * FROM active_email;

-- list of top 15 account's subscriptions (with email) with expiery date and type of payment (free of charge - last)
CREATE OR REPLACE VIEW list_subscr AS
SELECT 
	(SELECT nickname FROM accounts WHERE id = s.account_id) AS nickname, 
	u.email, 
	st.name AS subscription, 
	s.valid_till, 
	pt.pay_type, 
	p.sum_payed 
FROM subscriptions s 
JOIN payments p ON s.payment_id = p.id 
JOIN payment_types pt ON p.pay_type_id = pt.id 
JOIN subscription_types st ON s.subscription_type_id = st.id
JOIN accounts a ON s.account_id = a.id
JOIN users u ON u.id = a.user_id 
WHERE s.is_active = 1  
	ORDER BY FIELD(pt.pay_type, 'free');

SELECT * FROM list_subscr LIMIT 15;

-- total sum payed for movies using discounts with emails of payers for the last 5 years
-- uses tables media and discounts without bought_media 
CREATE OR REPLACE VIEW total_payments AS
SELECT 
	GROUP_CONCAT(DISTINCT (SELECT email FROM users WHERE id IN (SELECT user_id FROM accounts WHERE id = p.account_id))
		SEPARATOR ', ') AS email,
	CONCAT(m.name, '_', m.id) AS movies,
	GROUP_CONCAT(DISTINCT p.account_id) AS account,
	SUM(ROUND((d.`size` * m.price), 2)) AS total_payed -- or just sum of p.sum_payed, that is not the same because of filldb randoms the sum_payed
FROM payments p 
	JOIN discounts d ON p.discount_id = d.id
	JOIN media m ON m.id = d.media_id 
WHERE p.created_at BETWEEN (CURDATE() - INTERVAL 5 YEAR) AND CURDATE() 
GROUP BY movies WITH ROLLUP;

SELECT * FROM total_payments;

-- counts genders, counts ages and displays genres watched by them with rating > 2
CREATE OR REPLACE VIEW auditory AS
SELECT 
	COUNT(*) AS counter,
	CASE a.gender
		WHEN 'm' THEN 'male'
		WHEN 'f' THEN 'female'
		ELSE 'undefined'
	END AS gender,
	CASE
		WHEN TIMESTAMPDIFF(YEAR, a.birthday, NOW()) < 18 THEN 'under 18'
		WHEN TIMESTAMPDIFF(YEAR, a.birthday, NOW()) > 18 AND TIMESTAMPDIFF(YEAR, a.birthday, NOW()) < 45 THEN 'adults 18-45'
		ELSE 'older 45'
	END AS case_y,
	(SELECT name FROM jenres WHERE id = m.jenre_id) AS genre
FROM accounts a
JOIN watched_media wm ON a.id = wm.account_id
JOIN media m ON wm.media_id = m.id
WHERE get_avg_rate(wm.media_id) >= 2
GROUP BY case_y, a.gender, genre
ORDER BY gender ASC, counter DESC, genre ASC;

-- who is our auditory
CREATE OR REPLACE VIEW auditory_v2 AS
SELECT 
	COUNT(*) AS counter,
	CASE a.gender
		WHEN 'm' THEN 'male'
		WHEN 'f' THEN 'female'
		ELSE 'undefined'
	END AS gender,
	CASE
		WHEN TIMESTAMPDIFF(YEAR, a.birthday, NOW()) < 18 THEN 'under 18'
		WHEN TIMESTAMPDIFF(YEAR, a.birthday, NOW()) > 18 AND TIMESTAMPDIFF(YEAR, a.birthday, NOW()) < 45 THEN 'adults 18-45'
		ELSE 'older 45'
	END AS case_y
FROM accounts a
GROUP BY case_y, a.gender
ORDER BY gender ASC, counter DESC;

SELECT * FROM auditory;
SELECT * FROM auditory_v2;

-- simple view of top10 accounts (users), who bought most movies
CREATE OR REPLACE VIEW top10buyers AS
	SELECT 
		(SELECT nickname FROM accounts WHERE id = bought_media.account_id) AS nickname, 
		COUNT(*) AS sum_movie 
	FROM bought_media 
	GROUP BY account_id 
	ORDER BY sum_movie DESC LIMIT 10;

SELECT * FROM top10buyers;

-- top10 movies suitable for kids
CREATE OR REPLACE VIEW top10kids AS
SELECT DISTINCT 
	m.name AS movie, 
	m.age_limit, 
	ROUND(get_avg_rate(m.id), 2) AS rating,
	j.name AS jenre
FROM media m
JOIN jenres j ON j.id = m.jenre_id 
WHERE m.age_limit IN ('0+', '6+', '12+')
ORDER BY rating DESC LIMIT 10;

SELECT * FROM top10kids;

-- top5 troubles that are still in work
CREATE OR REPLACE VIEW top5trouble AS
SELECT COUNt(*) AS request, (SELECT nickname FROM accounts WHERE id = help_requests.from_user_id) AS nickname
FROM help_requests 
WHERE closed_at IS NULL
GROUP BY from_user_id ORDER BY request DESC;

SELECT * FROM top5trouble LIMIT 5;

-- most watched list of videos with highest rating
CREATE OR REPLACE VIEW top10watched AS
SELECT 
	(SELECT name FROM media WHERE id = wm.media_id) AS movie, 
	COUNT(*) AS total_watched,
	get_avg_rate(wm.media_id) AS rating
	-- ROUND((SELECT AVG(rating) FROM rating r WHERE r.media_id = wm.media_id GROUP BY r.media_id), 2) AS rating
FROM watched_media wm 
JOIN rating r ON wm.media_id = r.media_id 
WHERE get_avg_rate(wm.media_id) BETWEEN 6 AND 10
GROUP BY wm.media_id
ORDER BY total_watched
DESC LIMIT 10;

SELECT * FROM top10watched;



