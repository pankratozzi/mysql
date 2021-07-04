-- stored procedures and functions

USE naive_movie_service;

-- function that counts total payments for given movie_id

DROP FUNCTION IF EXISTS get_total_pay;
DELIMITER //
CREATE FUNCTION get_total_pay (m_id BIGINT UNSIGNED)
RETURNS DECIMAL(11, 2) READS SQL DATA
BEGIN
	DECLARE total_pay DECIMAL(11, 2) DEFAULT 0;
	SET total_pay = (SELECT SUM(p.sum_payed)
						   FROM bought_media bm
						   JOIN payments p ON p.id = bm.payment_id
						   WHERE bm.media_id = m_id); 
	IF ISNULL(total_pay) THEN
		RETURN 0;
	ELSE
		RETURN total_pay;
	END IF;
END //
DELIMITER ;

SELECT get_total_pay(2);


-- function that returns average rating for input movie_id

DROP FUNCTION IF EXISTS get_avg_rate;
DELIMITER //
CREATE FUNCTION get_avg_rate (m_id BIGINT UNSIGNED)
RETURNS FLOAT READS SQL DATA
BEGIN
	DECLARE avg_rate FLOAT DEFAULT 0;
	SET avg_rate = (SELECT AVG(rating) FROM rating WHERE media_id = m_id);
	RETURN avg_rate;
END //
DELIMITER ;

SELECT get_avg_rate(350);

-- create simple movie title for input media_id
DROP PROCEDURE IF EXISTS sp_show_title;
DELIMITER //
CREATE PROCEDURE sp_show_title (IN my_title BIGINT UNSIGNED)
BEGIN
SELECT name, 
	   (SELECT name FROM jenres j WHERE id = jenre) AS jenre, 
	   description, 
	   release_year, 
	   GROUP_CONCAT(producer ORDER BY producer SEPARATOR ', ') AS producers,
	   GROUP_CONCAT(actor ORDER BY actor SEPARATOR ', ') AS actors, 
	   IFNULL(get_avg_rate(my_title), 'no votes') AS rating, 
	   GROUP_CONCAT((SELECT CONCAT(name, ' - ', country) FROM studio WHERE id = st_id)) AS studio,
	   age_lim
FROM  
	(SELECT 
		mt.id AS id, 
		m.age_limit AS age_lim,
		m.name AS name, 
		m.description AS description, 
		YEAR(m.release_date) AS release_year,
		CONCAT(SUBSTRING(p.firstname, 1, 1), '. ', p.lastname) AS producer,
		CONCAT(SUBSTRING(a.firstname, 1, 1), '. ', a.lastname) AS actor,
		m.jenre_id AS jenre,
		mt.media_id AS med_id,
		mt.studio_id AS st_id
	FROM media m 
		JOIN movie_title mt ON m.id = mt.media_id 
		JOIN producers p ON p.id = mt.producer_id 
		JOIN actors a ON a.id = mt.actor_id) AS title WHERE med_id = my_title ;
END //
DELIMITER ;

-- shows many studios (so using group_concat) because filldb generated multiple studio_id for media_id in table movie_title
CALL sp_show_title(43); 

-- outputs all help messages
DROP PROCEDURE IF EXISTS sp_help_msg;
DELIMITER //
CREATE PROCEDURE sp_help_msg (IN myuser BIGINT UNSIGNED)
BEGIN
	SELECT 
		hr.from_user_id, 
		hm.typed_at, 
		hm.message, 
		hm.direction 
	FROM help_requests hr 
	JOIN help_messages hm ON hr.id = hm.help_request_id
	WHERE hr.from_user_id = myuser AND hr.closed_at IS NOT NULL
	ORDER BY hm.typed_at;
END //
DELIMITER ;

CALL sp_help_msg(1); 

-- procedure that uses transaction to buy new movie using discounts
-- ALTER TABLE payments DROP FOREIGN KEY discount_key;
-- ALTER TABLE payments DROP INDEX discount_idx;
-- ALTER TABLE payments CHANGE discount_id discount_id BIGINT UNSIGNED;


DROP PROCEDURE IF EXISTS sp_make_shopping_decl;
DELIMITER //
CREATE PROCEDURE sp_make_shopping_decl (IN my_account BIGINT UNSIGNED, IN med_id BIGINT UNSIGNED, IN pay_type INT UNSIGNED, 
									 OUT add_status VARCHAR(200))
BEGIN
		DECLARE disc_idx2 INT UNSIGNED;
		DECLARE summa2 DECIMAL (11, 2);
		DECLARE code, error VARCHAR(100);
		DECLARE is_rollback BOOL DEFAULT 0;
		DECLARE last_id BIGINT UNSIGNED DEFAULT 0;
		DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
		BEGIN
			SET is_rollback = 1;
			GET STACKED DIAGNOSTICS CONDITION 1
				code = RETURNED_SQLSTATE, error = MESSAGE_TEXT;
			SET add_status := concat('Aborted. Error code: ', code, '. Text: ', error);
		END; 
		SET summa2 = (SELECT 
					   IF((d.valid_till IS NOT NULL AND d.valid_till > NOW()), m.price * d.`size`, m.price) AS sum_p 
					   FROM media m 
					   LEFT JOIN discounts d ON m.id = d.media_id WHERE m.id = med_id);
		SET disc_idx2 = (SELECT d.id AS disc_idx FROM media m 
					   LEFT JOIN discounts d ON m.id = d.media_id WHERE m.id = med_id); -- test media id = 1			  
	START TRANSACTION;
		INSERT INTO payments VALUES (NULL, pay_type, summa2, disc_idx2, my_account, DEFAULT, DEFAULT); -- test pay_type = 1 account id = 5
		-- SET pay_id2 = (SELECT id FROM payments ORDER BY id DESC LIMIT 1);
		SET last_id = last_insert_id();
		INSERT INTO bought_media VALUES (NULL, my_account, med_id, last_id, DEFAULT); -- test account id = 5 media id = 1
		SELECT (SELECT nickname FROM accounts WHERE id = bm.account_id) AS nickname, 
	   		   (SELECT name FROM media WHERE id = bm.media_id) AS movie_name, 
	   		    p.sum_payed AS payed
		FROM bought_media bm 
		JOIN payments p ON bm.payment_id = p.id 
			WHERE p.id = last_id;
	IF is_rollback THEN 
		ROLLBACK;
	ELSE
		SET add_status := 'success!';
		COMMIT;
	END IF;
END//
DELIMITER ;

CALL sp_make_shopping_decl(1, 30, 2, @status);
CALL sp_make_shopping_decl(1, 31, 2, @status);
CALL sp_make_shopping_decl(3, 33, 1, @status); 
CALL sp_make_shopping_decl(3, 11, 1, @status); 


SELECT @status;

-- procedure to recomended video for given account - version 1
DROP PROCEDURE IF EXISTS sp_recomendation;
DELIMITER //
CREATE PROCEDURE sp_recomendation (IN my_account BIGINT)
BEGIN
	CREATE TABLE IF NOT EXISTS temp (id BIGINT, producer BIGINT, jenre INT);
	INSERT IGNORE INTO temp 
	SELECT DISTINCT
		mt.media_id AS movie, 
		mt.producer_id AS producer, 
		j.id AS jenre
	FROM watched_media wm 
		LEFT JOIN bought_media bm ON bm.media_id = wm.media_id  
		LEFT JOIN selected_media sm ON sm.media_id = wm.media_id 
		LEFT JOIN movie_title mt ON mt.media_id = wm.media_id 
		LEFT JOIN media m ON m.id = wm.media_id 
		LEFT JOIN jenres j ON j.id = m.jenre_id 
	WHERE wm.account_id = my_account
			AND mt.producer_id IS NOT NULL 
			AND j.id IS NOT NULL 
			AND get_avg_rate(mt.media_id) > 5; -- hardly excpects that movie have some rating
	SELECT DISTINCT
		m.name,
		ROUND(get_avg_rate(m.id), 2) AS rate
	FROM media m 
		JOIN movie_title mt ON m.id = mt.media_id 
		JOIN jenres j ON j.id = m.jenre_id 
		JOIN rating r ON r.media_id = m.id
	WHERE 
		(mt.producer_id IN (SELECT producer FROM temp) OR j.id IN (SELECT jenre FROM temp))
	 	AND m.id NOT IN (SELECT id FROM temp) AND get_avg_rate(m.id) >= 5
	 ORDER BY rate DESC LIMIT 5;
	DROP TABLE IF EXISTS temp;
END//
DELIMITER ;

CALL sp_recomendation(5);

-- procedure that selects movie using preselected year and producer 
DROP PROCEDURE IF EXISTS sp_custom_video;
DELIMITER $$
CREATE PROCEDURE sp_custom_video (prod VARCHAR(50), start_year YEAR, end_year YEAR) -- , jenre VARCHAR(50))
BEGIN
	SELECT 
		(SELECT name FROM media WHERE id = mt.media_id) AS movie,
		(SELECT CONCAT(SUBSTRING(firstname, 1, 1), '. ', lastname) FROM producers WHERE id = mt.producer_id) AS producer,
		(SELECT price FROM media WHERE id = mt.media_id) AS price,
		j.name AS jenre
	FROM movie_title mt
	JOIN producers p ON p.id = mt.producer_id 
	JOIN media m ON m.id = mt.media_id 
	JOIN jenres j ON j.id = m.jenre_id 
	WHERE (YEAR(m.release_date) BETWEEN start_year AND end_year)
		AND p.lastname LIKE CONCAT('%', prod,'%'); 
END $$
DELIMITER ;


CALL sp_custom_video('be', '2010', '2021');

-- procedure that adds user with transaction and handler - rollback or commit finally
DROP PROCEDURE IF EXISTS sp_add_user;
DELIMITER //
CREATE PROCEDURE sp_add_user (email VARCHAR(100), password_hash VARCHAR(45), phone CHAR(11),
							OUT add_status VARCHAR(200))
BEGIN
	DECLARE is_rollback BOOL DEFAULT 0;
	DECLARE code VARCHAR(100);
	DECLARE error VARCHAR(100);
	DECLARE last_id BIGINT UNSIGNED;

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
		BEGIN
			SET is_rollback = 1;
			GET STACKED DIAGNOSTICS CONDITION 1
				code = RETURNED_SQLSTATE, error = MESSAGE_TEXT;
			SET add_status := concat('Aborted. Error code: ', code, '. Text: ', error);
		END;
	START TRANSACTION;
		SAVEPOINT before_trans;
		INSERT INTO users (email, password_hash, phone) VALUES (email, password_hash, phone);
		SET last_id = last_insert_id();
		-- SELECT * FROM (SELECT id FROM users ORDER BY id DESC LIMIT 1) AS lid INTO @last_id;
		INSERT INTO accounts VALUES (NULL, last_id, CONCAT('must_setup', last_id),
								'to_setup', 'to_setup', DEFAULT, CURDATE(), NULL, NULL, 0, DEFAULT, DEFAULT, DEFAULT);
	IF is_rollback THEN
		ROLLBACK TO before_trans;
	ELSE
		SET add_status := 'successfuly created!';
		COMMIT;
	END IF;
END //
DELIMITER ;

SELECT last_insert_id();
CALL sp_add_user('pankratozzigmailcom', NULL, '512-5232052', @add_status)  -- raises error: invalid email or phone number
CALL sp_add_user('pankratozzi2@gmail.com', NULL, '52235232052', @add_status)
-- last_insert_id() returns incorrect value (last_id + 1) if previous insertion in users finished with error
-- e.g. last_insert_id = 221 after lasd insertion, but after 3 failures of insertions the value in successful
-- insertion becomes 225 %). But the same situation appears even without this procedure
CALL sp_add_user('pankratozzi16@gmail.com', NULL, '22715132111', @add_status) 

SELECT @add_status;

-- procedure that predicts recommendation for given account_id, the output is the same as for sp_recommendation
DROP PROCEDURE IF EXISTS sp_recommendationV2;
DELIMITER //
CREATE PROCEDURE sp_recommendationV2 (myuser BIGINT UNSIGNED, threshold INT UNSIGNED)
BEGIN
	DROP TABLE IF EXISTS temp;
	CREATE TABLE temp (id BIGINT UNSIGNED, jid INT UNSIGNED, pid BIGINT UNSIGNED);
	INSERT INTO temp SELECT * FROM (
	SELECT DISTINCT
		wm.media_id AS id,
		m.jenre_id AS jid,
		mt.producer_id AS pid
	FROM watched_media wm 
	JOIN media m ON wm.media_id = m.id 
	JOIN movie_title mt ON wm.media_id = mt.media_id 
	WHERE get_avg_rate(wm.media_id) >= threshold AND wm.account_id = myuser
	UNION
	SELECT DISTINCT 
		sm.media_id AS id,
		m.jenre_id AS jid,
		mt.producer_id AS pid
	FROM selected_media sm 
	JOIN media m ON sm.media_id = m.id 
	JOIN movie_title mt ON sm.media_id = mt.media_id 
	WHERE get_avg_rate(sm.media_id) >= threshold AND sm.account_id = myuser
	UNION
	SELECT DISTINCT 
		bm.media_id AS id,
		m.jenre_id AS jid,
		mt.producer_id AS pid
	FROM bought_media bm 
	JOIN media m ON bm.media_id = m.id 
	JOIN movie_title mt ON bm.media_id = mt.media_id 
	WHERE get_avg_rate(bm.media_id) >= threshold AND bm.account_id = myuser ) AS alias;	
	SELECT 
		m.name,
		get_avg_rate(m.id) AS rating
	FROM media m 
	JOIN movie_title mt ON mt.media_id = m.id 
	JOIN jenres j ON j.id = m.jenre_id 
	WHERE (mt.producer_id IN (SELECT pid FROM temp) OR j.id IN (SELECT jid FROM temp))
	   	AND (m.id NOT IN (SELECT id FROM temp)) AND get_avg_rate(m.id) >= threshold;
	DROP TABLE IF EXISTS temp;
END //
DELIMITER ;

CALL sp_recommendationV2(5, 5); 
CALL sp_recomendation(5); 


-- procedure that buys the subscription, discounts like in movies are not available

DROP PROCEDURE IF EXISTS sp_buy_subscription;
DELIMITER //
CREATE PROCEDURE sp_buy_subscription (account BIGINT UNSIGNED, subscription BIGINT UNSIGNED, pay_type INT UNSIGNED,
									  OUT status VARCHAR(200))
BEGIN
	DECLARE is_rollback BOOL DEFAULT 0;
	DECLARE code VARCHAR(100);
	DECLARE error VARCHAR(100);
	DECLARE last_id BIGINT UNSIGNED;
	DECLARE summa DECIMAL (11, 2);
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
		BEGIN
			SET is_rollback = 1;
			GET STACKED DIAGNOSTICS CONDITION 1
				code = RETURNED_SQLSTATE, error = MESSAGE_TEXT;
			SET status := concat('Aborted. Error code: ', code, '. Text: ', error);
		END;
	SET summa = (SELECT price FROM subscription_types WHERE id = subscription);
	START TRANSACTION;
		SAVEPOINT before_transaction;
		INSERT INTO payments (pay_type_id, sum_payed, account_id) VALUES (pay_type, summa, account);
		SET last_id = last_insert_id();
		INSERT INTO subscriptions (account_id, payment_id, is_active, subscription_type_id, valid_till) 
								   VALUES (account, last_id, 1, subscription, (NOW() + INTERVAL 1 MONTH));
	IF is_rollback THEN
		ROLLBACK TO before_transaction;
	ELSE
		SET status := 'successfuly bought!';
		COMMIT;
	END IF;
END //
DELIMITER ;

CALL sp_buy_subscription(13, 16, 2, @status) ;
SELECT @status;
