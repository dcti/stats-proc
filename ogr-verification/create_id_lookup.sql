-- $Id: create_id_lookup.sql,v 1.7 2002/12/23 13:39:53 nerf Exp $ --

DROP TABLE import_id;

CREATE TABLE import_id (
email VARCHAR (64),
id INTEGER,
retire_to INTEGER
);

COPY import_id FROM '/home/nerf/id_import.out';

DROP TABLE id_lookup;

CREATE TABLE id_lookup (
email VARCHAR (64),
id INTEGER
stats_id INTEGER);

INSERT INTO id_lookup
	SELECT email,
		id,
		(retire_to*(sign(retire_to))+id*(1-sign(retire_to)))
			AS stats_id
	FROM import_id;
