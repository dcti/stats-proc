-- $Id: create_id_import.sql,v 1.3 2002/12/22 22:01:29 nerf Exp $ --

DROP TABLE import_id;

CREATE TABLE import_id (
id INTEGER,
email VARCHAR (64),
password CHAR (8),
listmode SMALLINT,   
nonprofit SMALLINT,   
team INTEGER,   
retire_to INTEGER,   
friend_a INTEGER,   
friend_b INTEGER,   
friend_c INTEGER,   
friend_d INTEGER,   
friend_e INTEGER,   
dem_yob INTEGER,   
dem_heard SMALLINT,   
dem_gender CHAR (1),
dem_motivation SMALLINT,   
dem_country VARCHAR (8),
contact_name VARCHAR (50),
contact_phone VARCHAR (20),
motto VARCHAR(300),
retire_date VARCHAR(20));

COPY import_id FROM '/home/nerf/stats.out';
