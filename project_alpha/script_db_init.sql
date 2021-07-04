DROP DATABASE IF EXISTS naive_movie_service;
CREATE DATABASE IF NOT EXISTS naive_movie_service;
ALTER DATABASE naive_movie_service DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;
USE naive_movie_service;

CREATE TABLE IF NOT EXISTS `users` (
  `id` SERIAL PRIMARY KEY,
  `email` VARCHAR(100) NOT NULL,
  `password_hash` VARCHAR(45) NULL DEFAULT NULL,
  `phone` CHAR(11) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE INDEX `email_UNIQUE` (`email` ASC),
  UNIQUE INDEX `phone_UNIQUE` (`phone` ASC)) COMMENT = 'base table: stores users';
 
CREATE TABLE IF NOT EXISTS `accounts` (
  `id` SERIAL PRIMARY KEY,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `nickname` VARCHAR(100) NOT NULL,
  `firstname` VARCHAR(60) NOT NULL,
  `lastname` VARCHAR(100) NOT NULL,
  `gender` ENUM('m', 'f', 'x') DEFAULT 'x',
  `birthday` DATE NOT NULL,
  `country` VARCHAR(100) DEFAULT NULL,
  `city` VARCHAR(45) DEFAULT NULL,
  `is_active` TINYINT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE INDEX `nickname_UNIQUE` (`nickname` ASC),
  INDEX `user_key_idx` (`user_id` ASC),
  CONSTRAINT `user_key` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores account for users, user may have many accounts';

CREATE TABLE IF NOT EXISTS `subscription_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  `price` DECIMAL(11, 2) UNSIGNED DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expired_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)) COMMENT = 'stores types of subscriptions';
 
 CREATE TABLE IF NOT EXISTS `payment_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `pay_type` ENUM('card', 'apple pay', 'keyword', 'free') NOT NULL,
  PRIMARY KEY (`id`)) COMMENT = 'stores available types of payments';
 
 CREATE TABLE IF NOT EXISTS `jenres` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL DEFAULT 'documental',
  PRIMARY KEY (`id`)) COMMENT = 'stores genres names';
 
 CREATE TABLE IF NOT EXISTS `studio` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `country` VARCHAR(60) NOT NULL,
  PRIMARY KEY (`id`)) COMMENT = 'stores names and country of studios that created movie';
 
 CREATE TABLE IF NOT EXISTS `media` (
  `id` SERIAL PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL DEFAULT NULL,
  `jenre_id` INT UNSIGNED NOT NULL,
  `watched` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `price` DECIMAL(11,2) UNSIGNED NOT NULL DEFAULT 0,
  `release_date` DATETIME NOT NULL,
  `studio_id` INT UNSIGNED NOT NULL,
  `fees` DECIMAL(50,2) NOT NULL DEFAULT 0,
  `photo` VARCHAR(45) NOT NULL DEFAULT 'unknown.jpeg',
  `age_limit` ENUM('0+', '6+', '12+', '16+', '18+') NOT NULL DEFAULT '18+',
  `typo` INT(10) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'used to categorize video for further suggestions',
  INDEX `jenre_idx` (`jenre_id` ASC),
  INDEX `studio_idx` (`studio_id` ASC),
  CONSTRAINT `jenre_key` FOREIGN KEY (`jenre_id`) REFERENCES `jenres` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `studio_key` FOREIGN KEY (`studio_id`) REFERENCES `studio` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores all neccesary data for movie';
   
   CREATE TABLE IF NOT EXISTS `discounts` (
  `id` SERIAL PRIMARY KEY,
  `media_id` BIGINT(19) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'discount only for media',
  `size` FLOAT(10) UNSIGNED NOT NULL DEFAULT 1 COMMENT 'value from 0 to 1',
  `type` ENUM('class1', 'class2', 'class3') NOT NULL DEFAULT 'class3',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `valid_till` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `media_idx` (`media_id` ASC),
  CONSTRAINT `media_key` FOREIGN KEY (`media_id`) REFERENCES `media` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores data about available discounts and its status';
   
  CREATE TABLE IF NOT EXISTS `payments` (
  `id` SERIAL PRIMARY KEY,
  `pay_type_id` INT(10) UNSIGNED NOT NULL,
  `sum_payed` DECIMAL(11,2) UNSIGNED DEFAULT 0,
  `discount_id` BIGINT UNSIGNED,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `pay_idx` (`pay_type_id` ASC),
  INDEX `account_idx` (`account_id` ASC),
  CONSTRAINT `pay_key` FOREIGN KEY (`pay_type_id`) REFERENCES `payment_types` (`id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `account_key` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE) COMMENT = 'stores history of payments';
   
   
  CREATE TABLE IF NOT EXISTS `subscriptions` (
  `id` SERIAL PRIMARY KEY,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `payment_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `is_active` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `subscription_type_id` INT UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `valid_till` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE INDEX `payment_id_UNIQUE` (`payment_id` ASC),
  INDEX `acc_idx` (`account_id` ASC),
  INDEX `pay_idx` (`payment_id` ASC),
  INDEX `sub_idx` (`subscription_type_id` ASC),
  CONSTRAINT `account_subscription` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `sub_type` FOREIGN KEY (`subscription_type_id`) REFERENCES `subscription_types` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `pay_key_sub` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE) COMMENT = 'stores data about accounts subscriptions';

   CREATE TABLE IF NOT EXISTS `help_requests` (
  `id` SERIAL PRIMARY KEY,
  `from_user_id` BIGINT UNSIGNED NOT NULL,
  `trouble` TEXT NULL DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `closed_at` DATETIME NULL DEFAULT NULL,
  `help_rating` TINYINT UNSIGNED NULL DEFAULT NULL,
  INDEX `user_idx` (`from_user_id` ASC),
  CONSTRAINT `user_key_help` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE) COMMENT = 'stores history of users requests for support';
    
CREATE TABLE IF NOT EXISTS `help_messages` (
  `id` SERIAL PRIMARY KEY,
  `help_request_id` BIGINT UNSIGNED NOT NULL,
  `message` VARCHAR(300) NOT NULL,
  `typed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `crew_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `direction` ENUM('in', 'out') NOT NULL COMMENT 'in - user and out - crew',
  INDEX `help_idx` (`help_request_id` ASC),
  CONSTRAINT `help_key` FOREIGN KEY (`help_request_id`) REFERENCES `help_requests` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores all messages between support and user';
   
CREATE TABLE IF NOT EXISTS `bought_media` (
  `id` SERIAL PRIMARY KEY,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `media_id` BIGINT UNSIGNED NOT NULL,
  `payment_id` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `bought_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `account_key_idx` (`account_id` ASC),
  INDEX `media_key_idx` (`media_id` ASC),
  INDEX `payment_key_idx` (`payment_id` ASC),
  CONSTRAINT `account_key_bought` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `media_key_bought` FOREIGN KEY (`media_id`) REFERENCES `media` (`id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE,
  CONSTRAINT `payment_key_bought` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE) COMMENT = 'stores list of bought movies';

CREATE TABLE IF NOT EXISTS `selected_media` (
  `id` SERIAL PRIMARY KEY,
  `media_id` BIGINT UNSIGNED NOT NULL,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `short_comment` VARCHAR(255) NULL DEFAULT 'none',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `media_key_idx` (`media_id` ASC),
  INDEX `account_key_idx` (`account_id` ASC),
  CONSTRAINT `media_key_select` FOREIGN KEY (`media_id`) REFERENCES `media` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `account_key_select` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores list of movies selected by accounts';
   
CREATE TABLE IF NOT EXISTS `producers` (
  `id` SERIAL PRIMARY KEY,
  `firstname` VARCHAR(45) NOT NULL,
  `lastname` VARCHAR(45) NOT NULL,
  `birthday` DATE NOT NULL,
  `history` TEXT NULL DEFAULT NULL,
  `rating_imdb` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `jenre_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `death_date` DATETIME NULL DEFAULT NULL,
  `photo` VARCHAR(45) NOT NULL DEFAULT 'unknown.jpeg',
  INDEX `fullname` (`firstname` ASC, `lastname` ASC),
  INDEX `jenre_idx` (`jenre_id` ASC),
  CONSTRAINT `jenre_key_prod` FOREIGN KEY (`jenre_id`) REFERENCES `jenres` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores data about movie producers';
   
CREATE TABLE IF NOT EXISTS `actors` (
  `id` SERIAL PRIMARY KEY,
  `firstname` VARCHAR(45) NOT NULL,
  `lastname` VARCHAR(45) NOT NULL,
  `jenre_id` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `birthday` DATETIME NOT NULL,
  `rating_imdb` INT(10) UNSIGNED NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `death_date` DATETIME NULL DEFAULT NULL,
  `photo` VARCHAR(100) NOT NULL DEFAULT 'unknown.jpeg',
  `history` TEXT NULL DEFAULT NULL COMMENT 'about',
  INDEX `jenre_idx` (`jenre_id` ASC),
  CONSTRAINT `jenre_key_actor` FOREIGN KEY (`jenre_id`) REFERENCES `jenres` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores data about actors';
   
CREATE TABLE IF NOT EXISTS `movie_title` (
  `id` SERIAL PRIMARY KEY,
  `media_id` BIGINT UNSIGNED NOT NULL,
  `producer_id` BIGINT UNSIGNED NOT NULL,
  `actor_id` BIGINT UNSIGNED NOT NULL,
  `studio_id` INT(10) UNSIGNED NOT NULL,
  INDEX `media_idx` (`media_id` ASC),
  INDEX `producer_idx` (`producer_id` ASC),
  INDEX `actor_idx` (`actor_id` ASC),
  INDEX `studio_idx` (`studio_id` ASC),
  CONSTRAINT `media_key_title` FOREIGN KEY (`media_id`) REFERENCES `media` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `producer_key_title` FOREIGN KEY (`producer_id`) REFERENCES `producers` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `actor_key_title` FOREIGN KEY (`actor_id`) REFERENCES `actors` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `studio_key_title` FOREIGN KEY (`studio_id`) REFERENCES `studio` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'aggregates ids that are necessary to display title, 
	prevents storing big data in actors and producers by using only integer ids';  

CREATE TABLE IF NOT EXISTS `rating` (
  `id` SERIAL PRIMARY KEY,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `rating` TINYINT UNSIGNED NOT NULL COMMENT 'value from 1 to 10',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `media_id` BIGINT UNSIGNED NOT NULL,
  INDEX `account_idx` (`account_id` ASC),
  INDEX `media_rate_idx` (`media_id` ASC),
  CONSTRAINT `account_key_rate` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `media_key_rate` FOREIGN KEY (`media_id`) REFERENCES `media` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION) COMMENT = 'stores rating values given by accounts';
   
 CREATE TABLE IF NOT EXISTS `watched_media` (
  `id` SERIAL PRIMARY KEY,
  `media_id` BIGINT UNSIGNED NOT NULL,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `self_rating` INT(10) UNSIGNED NOT NULL DEFAULT 0,
  `short_comment` VARCHAR(400) NULL DEFAULT NULL,
  `watch_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `media_key_idx` (`media_id` ASC),
  INDEX `account_key_idx` (`account_id` ASC),
  CONSTRAINT `media_key_watch` FOREIGN KEY (`media_id`) REFERENCES `media` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `account_key_watch` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE CASCADE) COMMENT = 'list of movies watched by accounts';

CREATE TABLE IF NOT EXISTS `subscription_media` (
  `id` SERIAL PRIMARY KEY,
  `subscription_id` BIGINT UNSIGNED NOT NULL,
  `media_id` BIGINT UNSIGNED NOT NULL,
  INDEX `subscription_id_idx` (`subscription_id` ASC),
  INDEX `media_sub_idx` (`media_id` ASC),
  CONSTRAINT `subscription_media_key` FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `media_sub_key` FOREIGN KEY (`media_id`) REFERENCES `media` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE) COMMENT = 'stores media_ids that are included in subscription';
   