-- $Id: create_id_lookup.sql,v 1.10 2003/01/18 23:42:13 nerf Exp $ --

CREATE temp TABLE import_id (
email VARCHAR (64),
id INTEGER,
retire_to INTEGER
);

COPY import_id FROM '/home/nerf/id_import.out';

DROP TABLE id_lookup;

CREATE TABLE id_lookup (
email VARCHAR (64),
id INTEGER,
stats_id INTEGER);

INSERT INTO id_lookup
	SELECT email,
		id,
		(retire_to*(sign(retire_to))+id*(1-sign(retire_to)))
			AS stats_id
	FROM import_id;

CREATE INDEX idlookup_id ON id_lookup (id);
CREATE INDEX idlookup_email_idx ON id_lookup (email);
