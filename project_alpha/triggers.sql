-- triggers for project database

USE naive_movie_service;

-- trigger for insertion email and phone
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

-- trigger that prevents byuing video second time
DROP TRIGGER IF EXISTS already_bought_check;
DELIMITER $$
CREATE TRIGGER already_bought_check BEFORE INSERT ON bought_media
FOR EACH ROW 
BEGIN 
IF ((NEW.media_id, NEW.account_id) IN (SELECT media_id, account_id FROM bought_media)) THEN 
  SIGNAL SQLSTATE '12345'
     SET MESSAGE_TEXT = 'already bought';
END IF;
END$$
DELIMITER ;

-- checks update on discounts
DROP TRIGGER IF EXISTS check_discount;
DELIMITER $$
CREATE TRIGGER check_discount BEFORE UPDATE ON discounts
FOR EACH ROW 
BEGIN 
	IF ((NEW.`size` < OLD.`size`) OR NEW.`size` > 1) THEN 
  		SET NEW.`size` = OLD.`size`;
	END IF;
END$$
DELIMITER ;

UPDATE discounts SET `size` = 2 WHERE id = 1; -- size was set to 0.5
UPDATE discounts SET `size` = 0.3 WHERE id = 1;
UPDATE discounts SET `size` = 0.8 WHERE id = 1;

-- checks if duplicate media_id in subcriptions_media
DROP TRIGGER IF EXISTS check_media;
DELIMITER $$
CREATE TRIGGER check_media BEFORE INSERT ON subscription_media
FOR EACH ROW 
BEGIN 
	IF ((NEW.subscription_id, NEW.media_id) IN (SELECT subscription_id, media_id 
		FROM subscription_media WHERE subscription_id = NEW.subscription_id)) THEN
		SIGNAL SQLSTATE '12345' SET MESSAGE_TEXT = 'media_id in that subscription already exists';
	END IF;
END $$
DELIMITER ;

-- checks if subscription already bought
DROP TRIGGER IF EXISTS already_bought_sub_check;
DELIMITER $$
CREATE TRIGGER already_bought_sub_check BEFORE INSERT ON subscriptions
FOR EACH ROW 
BEGIN 
IF ((NEW.subscription_type_id, NEW.account_id) IN (SELECT subscription_type_id, account_id FROM subscriptions
	WHERE is_active = 1 AND valid_till > NOW())) THEN 
  SIGNAL SQLSTATE '12345'
     SET MESSAGE_TEXT = 'already bought';
END IF;
END$$
DELIMITER ;

-- ? trigger on account creation, check if user_id exists IF NEW.user_id IN (SELECT id FROM users)
-- but foreign keys already solves this!

SELECT (SELECT email FROM users WHERE id = accounts.user_id), nickname 
FROM accounts;

-- here is the error from foreign key
INSERT INTO `accounts` (`id`, `user_id`, `nickname`, `firstname`, `lastname`, `gender`, `birthday`, `country`, `city`, `is_active`, `created_at`, `updated_at`, `last_login`) VALUES ('201', '250', 'Tomason', 'Domenic', 'Medhurst', 'x', '2009-10-26', 4, 'Port Jeffview', 0, '2016-08-20 18:57:50', '1974-11-12 12:36:10', '1976-08-22 23:08:19');
-- error: duplicate entries
INSERT INTO users VALUES (NULL, 'pankratozzi@gmail.com', NULL, '51235232052', DEFAULT, DEFAULT);
