-- $Id: create_platform.sql,v 1.2 2003/05/13 14:05:42 nerf Exp $
\set ON_ERROR_STOP 1

CREATE TABLE platform (
platform_id SERIAL UNIQUE PRIMARY KEY,
os_type INT NOT NULL,
cpu_type INT NOT NULL,
version INT NOT NULL
) WITHOUT OIDS;

CREATE UNIQUE INDEX platform_all on platform
	(os_type,cpu_type,version); 
