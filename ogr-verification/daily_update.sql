-- $Id: daily_update.sql,v 1.4 2003/09/10 19:11:21 nerf Exp $

select now();

\set ON_ERROR_STOP 1

-- First, we connect to the stats database and export anybody that either
-- retired or was created today
\connect stats

CREATE TEMP TABLE id_export (
 email        character varying(64) NOT NULL,
 id           integer NOT NULL,
 stats_id     integer NOT NULL,
 retire_date  date,
 created      date
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
retire_date     date,
created         date
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
	in_results bool DEFAULT false NOT NULL
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

CREATE TEMP TABLE retired_stub_id (
stub_id integer NOT NULL,
nodecount bigint NOT NULL,
id integer NOT NULL
) WITHOUT OIDS;

ANALYZE retire_today;

SET enable_seqscan = false;
explain analyze
INSERT INTO retired_stub_id
    SELECT DISTINCT stub_id, nodecount, id
        -- Get list of all work done by everyone who's retiring, along with their stats_id
        -- Doing this as a subquery is faster because it limits the amount of processing the main query
        -- has to do.
        FROM (SELECT DISTINCT stub_id, nodecount, rslt.id, rt.stats_id
                    FROM OGR_results rslt, retire_today rt
                    WHERE rslt.id = rt.id
                ) AS w
        -- In the final list we only want work that would duplicate other work by this participant
        -- This means we just have to see if there's any results for each stub/nodecount that were done
        -- by anyone in the retire-chain *except for the id that's newly retired*
        WHERE EXISTS (SELECT 1
                                FROM ogr_results r, ogr_idlookup l
                                WHERE r.id = l.id
                                    AND r.stub_id = w.stub_id
                                    AND r.nodecount = w.nodecount
                                    AND l.stats_id = w.stats_id
                                    AND l.id != w.id
                            )
;
SET enable_seqscan = true;

select now();
select * from retired_stub_id;

analyze retired_stub_id;

select now();

BEGIN;

-- reduce the number of participants for a given stub, but only if what
-- we previous thought was two different people are now (because of retires)
-- seen as a single person
explain analyze UPDATE ogr_summary
SET participants = participants - duplicated_ids
FROM (SELECT stub_id, nodecount, count(*) AS duplicated_ids
	FROM retired_stub_id GROUP BY stub_id, nodecount) dw
WHERE ogr_summary.stub_id = dw.stub_id
AND ogr_summary.nodecount = dw.nodecount;

-- Create a summary, like OGR_summary, but just with today's data
CREATE TEMP TABLE day_summary (
 stub_id       integer  NOT NULL,
 nodecount     bigint   NOT NULL,
 ids  integer  NOT NULL,
 max_version    integer  NOT NULL,
 in_ogr_summary boolean NOT NULL DEFAULT FALSE
) WITHOUT OIDS;

explain analyze INSERT INTO day_summary (stub_id,nodecount,ids,max_version)
SELECT stub_id, nodecount, count(DISTINCT l.stats_id) AS ids,
	max(p.version) AS max_version
    FROM day_results dr, OGR_idlookup l, platform p
    WHERE l.id = dr.id
        AND p.platform_id = dr.platform_id
AND NOT EXISTS (
	SELECT * FROM ogr_results r
		WHERE r.stub_id = dr.stub_id
		AND r.nodecount = dr.nodecount
		AND r.id = dr.id)
    GROUP BY stub_id, nodecount
;
CREATE INDEX day_stubnode ON day_summary (stub_id,nodecount)
    WHERE in_ogr_summary;

analyze day_summary;

-- Mark all the records that are currently in ogr_summary
-- Since we're going to update the ones that are there, then insert the
-- ones that are not, this saves us having to do the same EXISTS
-- statement twice
explain analyze UPDATE day_summary
SET in_ogr_summary = true
WHERE exists
(SELECT * FROM OGR_summary WHERE OGR_summary.stub_id = day_summary.stub_id
        AND OGR_summary.nodecount = day_summary.nodecount
        );

-- If it's threre already, update it
explain analyze UPDATE OGR_summary
    SET participants = participants + ids
        , max_client = max(max_client, max_version)
    FROM day_summary ds
    WHERE ds.in_ogr_summary 
    AND ds.stub_id = OGR_summary.stub_id
    AND ds.nodecount = OGR_summary.nodecount
;

-- If it's not there, add it
-- Note that most of the stubs will fall under this category
explain analyze INSERT INTO OGR_summary(stub_id, nodecount, participants, max_client)
    SELECT stub_id, nodecount, ids, max_version
    FROM day_summary ds
    WHERE NOT ds.in_ogr_summary
;

COMMIT;

CREATE TEMP TABLE ogr_stats (
  table_name varchar(22), 
  function varchar(22), 
  result int8, 
  project_id int2
) WITHOUT OIDS;


BEGIN;

insert into ogr_stats (table_name,function,result,project_id)
select 'ogr_stubs','count',count(*),project_id
from ogr_stubs
group by project_id;

insert into ogr_stats (function,result,project_id)
select 'pass1',count(distinct su.stub_id),project_id
from ogr_stubs s, ogr_summary su
where s.stub_id = su.stub_id
group by project_id;

insert into ogr_stats (function,result,project_id)
select 'pass2',count(distinct su.stub_id),project_id
from ogr_stubs s, ogr_summary su
where s.stub_id = su.stub_id
	and su.max_client >= 8014
	and su.participants >=2
group by project_id;

insert into ogr_stats (function,result,project_id)
select 'stubs_returned',count(*),project_id
from logdata ld, ogr_stubs s
where ld.stub_marks = s.stub_marks
group by project_id;

analyze ogr_stats;

select * from ogr_stats;

INSERT INTO ogr_complete
SELECT :RUNDATE as rundate,Cnt.project_id, Cnt.result as count, 
        P1.result as Pass1, P2.result as Pass2, P3.result as Stubs_Returned
FROM ogr_stats as Cnt, ogr_stats as P1, ogr_stats as P2, ogr_stats as P3
WHERE Cnt.function = 'count'
AND P1.function = 'pass1'
AND P2.function = 'pass2'
AND P3.function = 'stubs_returned'
AND Cnt.project_id = P1.project_id 
AND P1.project_id = P2.project_id
AND P2.project_id = P3.project_id;

COMMIT;

truncate logdata;

select now();
