-- $Id --

DROP TABLE import_id;

CREATE TABLE import_id (
id NUMERIC (6),
email VARCHAR (64),
password CHAR (8),
listmode SMALLINT,   
nonprofit SMALLINT,   
team INT,   
retire_to INT,   
friend_a INT,   
friend_b INT,   
friend_c INT,   
friend_d INT,   
friend_e INT,   
dem_yob INT,   
dem_heard SMALLINT,   
dem_gender CHAR (1),
dem_motivation SMALLINT,   
dem_country VARCHAR (8),
contact_name VARCHAR (50),
contact_phone VARCHAR (20),
motto TEXT,
retire_date TEXT);

COPY import_id FROM '/home/nerf/stats.out';
