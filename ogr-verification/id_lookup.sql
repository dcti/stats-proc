-- $Id: id_lookup.sql,v 1.8 2003/09/29 01:47:41 nerf Exp $
\set ON_ERROR_STOP 1

\connect stats

CREATE TEMP TABLE id_export (
  email character varying(64) NOT NULL,
  id integer NOT NULL,
  stats_id integer NOT NULL,
  retire_date date,
  created date
) WITHOUT OIDS;

INSERT into id_export
SELECT email, id, CASE 
                    WHEN retire_to = 0 THEN id
                  ELSE retire_to
                  END AS stats_id,
       retire_date,created
FROM STATS_participant
WHERE retire_date = :RUNDATE ::DATE
  OR created = :RUNDATE ::DATE;

\copy id_export TO '/tmp/id_import.out'

\connect ogr

CREATE TEMP TABLE import_id (
email VARCHAR (64),
id INTEGER,
stats_id INTEGER,
retire_date     date,
created         date
);

\copy import_id FROM '/tmp/id_import.out'

ANALYZE import_id;

BEGIN;

INSERT INTO OGR_idlookup
	SELECT email, id, stats_id,
		retire_date,created
	FROM import_id
	WHERE created IS NOT NULL;

UPDATE OGR_idlookup
	SET stats_id = import_id.stats_id
	FROM import_id
	WHERE import_id.retire_date IS NOT NULL
	AND OGR_idlookup.id = import_id.id;

COMMIT;

ANALYZE OGR_idlookup;
