-- $Id: create_id_lookup.sql,v 1.17 2003/07/20 23:19:58 nerf Exp $ --

CREATE TABLE OGR_idlookup (
email VARCHAR (64) not null,
id INTEGER not null,
stats_id INTEGER not null,
retire_date     date null,
created         date null);

DROP INDEX idlookup_id;
DROP INDEX idlookup_email_lower;

\set ON_ERROR_STOP 1

TRUNCATE OGR_idlookup;

CREATE TEMP TABLE import_id (
email VARCHAR (64),
id INTEGER,
retire_to INTEGER,
retire_date     date,
created         date
);


BEGIN;

\copy import_id FROM '/tmp/id_import.out' WITH NULL AS ''

INSERT INTO OGR_idlookup
	SELECT email,
		id,
		(retire_to*(sign(retire_to))+id*(1-sign(retire_to)))
			AS stats_id,
retire_date,created
	FROM import_id;

COMMIT;

\set ON_ERROR_STOP 0

CREATE INDEX idlookup_id ON OGR_idlookup (id);
CREATE UNIQUE INDEX idlookup_email_lower ON OGR_idlookup (lower(email));

ANALYZE OGR_idlookup;
