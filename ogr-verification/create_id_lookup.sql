-- $Id: create_id_lookup.sql,v 1.12 2003/02/16 19:18:42 nerf Exp $ --

CREATE temp TABLE import_id (
email VARCHAR (64),
id INTEGER,
retire_to INTEGER
);

COPY import_id FROM '/tmp/id_import.out';

DROP TABLE OGR_idlookup;

CREATE TABLE OGR_idlookup (
email VARCHAR (64),
id INTEGER,
stats_id INTEGER);

INSERT INTO OGR_idlookup
	SELECT email,
		id,
		(retire_to*(sign(retire_to))+id*(1-sign(retire_to)))
			AS stats_id
	FROM import_id;

CREATE INDEX idlookup_id ON OGR_idlookup (id);
CREATE UNIQUE INDEX idlookup_email_lower ON OGR_idlookup (lower(email));
