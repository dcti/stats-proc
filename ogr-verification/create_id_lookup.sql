-- $Id: create_id_lookup.sql,v 1.14 2003/04/25 21:09:20 nerf Exp $ --

CREATE TEMP TABLE import_id (
email VARCHAR (64),
id INTEGER,
retire_to INTEGER
);

CREATE TABLE OGR_idlookup (
email VARCHAR (64),
id INTEGER,
stats_id INTEGER);

TRUNCATE OGR_idlookup;
DROP INDEX idlookup_id;
DROP INDEX idlookup_email_lower;

BEGIN;

\copy import_id FROM '/tmp/id_import.out'

INSERT INTO OGR_idlookup
	SELECT email,
		id,
		(retire_to*(sign(retire_to))+id*(1-sign(retire_to)))
			AS stats_id
	FROM import_id;

COMMIT;

CREATE INDEX idlookup_id ON OGR_idlookup (id);
CREATE UNIQUE INDEX idlookup_email_lower ON OGR_idlookup (lower(email));

ANALYZE OGR_idlookup;
