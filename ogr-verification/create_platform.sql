-- $Id: create_platform.sql,v 1.1 2003/01/22 19:33:08 nerf Exp $

CREATE TABLE platform (
platform_id SERIAL UNIQUE PRIMARY KEY,
os_type INT NOT NULL,
cpu_type INT NOT NULL,
version INT NOT NULL
) WITHOUT OIDS;

CREATE UNIQUE INDEX platform_all on platform
	(os_type,cpu_type,version); 
