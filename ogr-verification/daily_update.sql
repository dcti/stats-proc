-- $Id: daily_update.sql,v 1.19 2004/01/28 20:18:14 decibel Exp $

select now();

\set ON_ERROR_STOP 1

-- First, we connect to the stats database and export anybody that either
-- retired or was created today
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

-- export this data to a temp file
\copy id_export TO '/tmp/id_import.out'

-- Now we connect to ogr for the rest of the run
\connect ogr

CREATE TEMP TABLE import_id (
email VARCHAR (64),
id INTEGER,
stats_id INTEGER,
retire_date   date,
created     date
) WITHOUT OIDS;

\copy import_id FROM '/tmp/id_import.out'

ANALYZE import_id;

BEGIN;

-- We're being optimistic here and assuming that previously created/retired
-- people were handled in previous runs
INSERT INTO OGR_idlookup
  SELECT email, id, stats_id,
    retire_date,created
  FROM import_id
  WHERE created IS NOT NULL;

UPDATE OGR_idlookup
  SET stats_id = import_id.stats_id
  FROM import_id
  WHERE import_id.retire_date IS NOT NULL
  AND OGR_idlookup.id = import_id.id
  AND OGR_idlookup.stats_id != import_id.stats_id;
-- The last clause is not needed (we could just update everything), but it's
-- nice to know how many records have really changed.

COMMIT;

ANALYZE OGR_idlookup;

select now();
----------------

CREATE TEMP TABLE retire_today (
email VARCHAR (64) NOT NULL,
id INTEGER NOT NULL,
stats_id INTEGER NOT NULL
) WITHOUT OIDS;

-- We're again being optimistic and assuming that the data was exported
-- correctly (that we only have data for the RUNDATE)
INSERT INTO retire_today(email,id,stats_id)
  SELECT email, id, stats_id
  FROM import_id
  WHERE retire_date IS NOT NULL;

----------------

CREATE TEMP TABLE day_results (
  id INT,
  stub_id INTEGER,
  nodecount BIGINT,
  platform_id INT,
  return_count INT,
  in_results bool DEFAULT false NOT NULL,
  exclude_from_summary bool DEFAULT false NOT NULL
) WITHOUT OIDS;

analyze logdata;

INSERT INTO platform (os_type,cpu_type,"version")
SELECT DISTINCT L.os_type, L.cpu_type, L.version
FROM logdata L
WHERE NOT EXISTS (SELECT * FROM platform WHERE
            L.os_type = platform.os_type AND
            L.cpu_type = platform.cpu_type AND
            L.version = platform.version);
select now();

-- aggregate and normalize data
INSERT INTO day_results
SELECT I.id, S.stub_id, L.nodecount, P.platform_id, sum(rowcount)
  FROM (
    SELECT lower(email) AS email, stub_marks, nodecount, 
    os_type, cpu_type, version, count(*) AS rowcount
    FROM logdata
    GROUP BY 
    lower(email), stub_marks, nodecount, os_type, cpu_type, version)
    L,
  OGR_idlookup I, OGR_stubs S, platform P
  WHERE 
    L.email = lower(I.email)
    AND L.stub_marks = S.stub_marks
    AND L.os_type = P.os_type
    AND L.cpu_type = P.cpu_type
    AND L.version = P.version
  GROUP BY
    I.id, S.stub_id, L.nodecount, P.platform_id;

CREATE UNIQUE INDEX dayresults_all ON day_results
  (id,stub_id,nodecount,platform_id);

CREATE unique INDEX dayresults_all_count ON day_results
  (id,stub_id,nodecount,platform_id,return_count) ;

select now();
----------------
analyze day_results;

UPDATE day_results
SET in_results = true
WHERE exists
(SELECT * FROM OGR_results WHERE day_results.id = OGR_results.id AND
    day_results.stub_id = OGR_results.stub_id AND
    day_results.nodecount = OGR_results.nodecount AND
    day_results.platform_id = OGR_results.platform_id);
select now();

analyze day_results;

BEGIN;

-- Now we have some updates to exclude_from_summary.  Setting this flag to true
-- now means that those records will not make it into ogr_summary.  Use
-- this for cases where we want separate results in ogr_results, but
-- they aren't different enough to warrant two entries (or a participant
-- count of 2 in ogr_summary

-- update day_results.exclude_from_summary for stubs that were done by someone
-- under a different id, but that we now know is the same person (due
-- to retires)

UPDATE day_results
SET exclude_from_summary = true
WHERE exists
(SELECT * FROM OGR_results, ogr_idlookup i1, ogr_idlookup i2
    WHERE i1.stats_id = i2.stats_id AND
    i1.id = day_results.id AND i2.id = ogr_results.id AND
    day_results.id != ogr_results.id AND
    day_results.stub_id = OGR_results.stub_id AND
    day_results.nodecount = OGR_results.nodecount AND
    day_results.platform_id = OGR_results.platform_id);

-- update where stub_id, nodecount, id are equal but platform is different
-- We have decided that this should not count as having been done twice.
UPDATE day_results
SET exclude_from_summary = true
WHERE day_results.id = ogr_results.id
    AND day_results.stub_id = ogr_results.stub_id
    AND day_results.nodecount = ogr_results.nodecount
    AND day_results.platform_id != ogr_results.platform_id
;

    UPDATE OGR_results
    SET return_count = COALESCE(OGR_results.return_count,0) + dr.return_count
    FROM day_results dr
    WHERE dr.id = OGR_results.id AND
        dr.stub_id = OGR_results.stub_id AND
        dr.nodecount = OGR_results.nodecount AND
        dr.platform_id = OGR_results.platform_id AND
        dr.in_results = true;
select now();

    INSERT INTO OGR_results
    SELECT dr.id, dr.stub_id, dr.nodecount, dr.platform_id, dr.return_count
    FROM day_results dr
    WHERE dr.in_results = false;
select now();

analyze OGR_results;

CREATE TEMP TABLE retired_stub_id (
stub_id integer NOT NULL,
nodecount bigint NOT NULL,
id integer NOT NULL
) WITHOUT OIDS;

ANALYZE retire_today;

-- We need to build a list of work that has been done by newly retired participants that can no longer
-- be considered valid because a stub has been done multiple times by the same persone
--
-- Here are the scenarios:
-- Assume id 2 and 3 both retired into id 1
-- a) The same stub has been done by 1 and 2 or 1 and 3; reduce count be one
-- b) Same stub done by 1, 2, and 3; reduce count by 2
-- c) Same stub done by 2 and 3; reduce by 1

-- Grab all data involved:
/*
SELECT stub_id, nodecount, rslt.id, rt.stats_id
    INTO retired_data
    FROM OGR_results rslt, retire_today rt
    WHERE rslt.id = rt.id OR rslt.id = rt.stats_id
;
For case a:
stub 1, nodecount 1, 1, 1
stub 1, nodecount 1, 1, 2 (or stub 1, nodecount 1, 1, 3)

b:
stub 1, nodecount 1, 1, 1
stub 1, nodecount 1, 1, 2
stub 1, nodecount 1, 1, 3

c:
stub 1, nodecount 1, 1, 2
stub 1, nodecount 1, 1, 3

Given that set, the delta we need to apply to each stub_id/nodecount combo is
-(count(*) - count(DISTINCT stats_id)) but of course count(DISTINCT stats_id) will always be 1 so what we
want is:

SELECT stub_id, nodecount, count(*)-1 as correction
    FROM retired_data
    GROUP BY stub_id, nodecount
;

*/

SET enable_seqscan = false;
--explain analyze
INSERT INTO retired_stub_id
    -- Get the list of all work done by the IDs involved in retires
    SELECT stub_id, nodecount, id
        FROM
            -- Build a list of all the IDs we might need. This removes the need for an OR so it should be faster
            (
                SELECT stats_id, id FROM retire_today
                    UNION
                SELECT stats_id, stats_id FROM retire_today
            ) AS ids
            , OGR_results r
        WHERE r.id = ids.id
            -- But we only need work if it has been done by someone else in our retire chain
            AND EXISTS (SELECT *
                        FROM OGR_results r2, ids
                        WHERE r2.id = ids.id
                            AND r2.stub_id = r.stub_id
                            AND r2.nodecount = r.nodecount
                            AND r2.id != r.id
                      )
;
SET enable_seqscan = true;

select now();
select * from retired_stub_id;

analyze retired_stub_id;

select now();

-- reduce the number of participants for a given stub, but only if what
-- we previous thought was two different people are now (because of retires)
-- seen as a single person
--explain analyze
UPDATE OGR_summary
SET participants = participants - duplicated_ids
FROM (
  SELECT stub_id, nodecount, count(*) AS duplicated_ids
    FROM retired_stub_id GROUP BY stub_id, nodecount
  ) dw
WHERE OGR_summary.stub_id = dw.stub_id
  AND OGR_summary.nodecount = dw.nodecount;


-- Create a summary, like OGR_summary, but just with today's data
CREATE TEMP TABLE day_summary (
  stub_id     integer  NOT NULL,
  nodecount   bigint   NOT NULL,
  ids  integer  NOT NULL,
  max_version  integer  NOT NULL,
  in_OGR_summary boolean NOT NULL DEFAULT FALSE
) WITHOUT OIDS;

--explain analyze
INSERT INTO day_summary (stub_id,nodecount,ids,max_version)
SELECT stub_id, nodecount, count(DISTINCT l.stats_id) AS ids,
  max(p.version) AS max_version
  FROM day_results dr, OGR_idlookup l, platform p
  WHERE l.id = dr.id
    AND p.platform_id = dr.platform_id
    AND NOT (dr.exclude_from_summary
      OR dr.in_results)
  GROUP BY stub_id, nodecount
;


analyze day_summary;
analyze OGR_summary;

-- Mark all the records that are currently in OGR_summary
-- Since we're going to update the ones that are there, then insert the
-- ones that are not, this saves us having to do the same EXISTS
-- statement twice
--explain analyze
UPDATE day_summary
SET in_OGR_summary = true
WHERE exists
    (SELECT * FROM OGR_summary WHERE OGR_summary.stub_id = day_summary.stub_id
        AND OGR_summary.nodecount = day_summary.nodecount
    )
;

CREATE INDEX day_stubnode ON day_summary (stub_id,nodecount)
  WHERE in_OGR_summary;

-- If it's there already, update it
--explain analyze
UPDATE OGR_summary
    SET participants = participants + ids,
      max_client = max(max_client, max_version)
    FROM day_summary ds
    WHERE ds.in_OGR_summary 
    AND ds.stub_id = OGR_summary.stub_id
    AND ds.nodecount = OGR_summary.nodecount
;

-- If it's not there, add it
-- Note that most of the stubs will fall under this category
--explain analyze
INSERT INTO OGR_summary(stub_id, nodecount, participants, max_client)
    SELECT stub_id, nodecount, ids, max_version
    FROM day_summary ds
    WHERE NOT ds.in_OGR_summary
;

UPDATE ogr_summary
SET max_client = p.version
  FROM platform p, day_results dr
  WHERE p.platform_id = dr.platform_id
    AND dr.exclude_from_summary
    AND max_client < p.version
    AND dr.stub_id = OGR_summary.stub_id
    AND dr.nodecount = OGR_summary.nodecount
;

COMMIT;
select now();

BEGIN;
  select doOGRstatsrun( :RUNDATE ::DATE);
COMMIT;

TRUNCATE logdata;

select now();
select 'daily_update complete for ',:RUNDATE as rundate ,now() as current_time ;
