-- $Id: create_id_lookup.sql,v 1.16 2003/06/09 14:16:52 nerf Exp $ --
\set ON_ERROR_STOP 1

CREATE TEMP TABLE import_id (
    listmode smallint DEFAULT 0 NOT NULL,
    nonprofit smallint DEFAULT 0 NOT NULL,
    id integer NOT NULL,
    retire_to integer DEFAULT 0 NOT NULL,
    retire_date date,
    friend_a integer DEFAULT 0 NOT NULL,
    friend_b integer DEFAULT 0 NOT NULL,
    friend_c integer DEFAULT 0 NOT NULL,
    friend_d integer DEFAULT 0 NOT NULL,
    friend_e integer DEFAULT 0 NOT NULL,
    dem_yob integer DEFAULT 0 NOT NULL,
    dem_heard smallint DEFAULT 0 NOT NULL,
    dem_motivation smallint DEFAULT 0 NOT NULL,
    dem_gender character(1) DEFAULT '' NOT NULL,
    email character varying(64) DEFAULT '' NOT NULL,
    "password" character(8) DEFAULT '' NOT NULL,
    dem_country character varying(8) DEFAULT '' NOT NULL,
    contact_name character varying(50) DEFAULT '' NOT NULL,
    contact_phone character varying(20) DEFAULT '' NOT NULL,
    motto character varying(255) DEFAULT '' NOT NULL
) WITHOUT OIDS;

--CREATE TABLE OGR_idlookup (
--email VARCHAR (64) not null,
--id INTEGER not null,
--stats_id INTEGER not null);

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
