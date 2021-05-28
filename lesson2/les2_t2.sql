drop database if exists example;
create database if not exists example;

use example;

show databases;

drop table if exists users;
create table users (
id serial primary key,
name varchar(200) default 'unknown user',
descr text comment 'info about user',
unique unique_name(name(10)),
created_at datetime default current_timestamp )
comment = 'table of user\'s names';

insert ignore into users (name, descr) values ('Mike', 'story'), ('Leo', 'long story'), ('Anna', 'story'),
('Anna', 'story');
describe users;
select * from users order by name;

drop table if exists sample;
create table sample (
id serial primary key,
name varchar(200) default 'unknown user',
descr text comment 'info about user',
created_at datetime default current_timestamp );

describe sample;
update users set descr='short story' where id=1;

select * from users where name like 'Mike';

insert into sample select * from users;
alter table sample add column surname varchar(200) default 'unknown user';
create index index_of_name on sample (name);

describe sample;
select * from sample;
select * from sample where name like 'M%' or name like 'A%';

delete from users where id > 1 limit 1;
truncate sample;

show tables;
select * from users;
select * from sample;
