-- $Id: id_lookup.sql,v 1.6 2003/09/07 05:27:37 nerf Exp $
\set ON_ERROR_STOP 1

\connect stats

CREATE TEMP TABLE id_export AS
SELECT email, id, max(id,retire_to) AS stats_id,
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

--ROLLBACK;
COMMIT;

--ANALYZE OGR_idlookup;
