-- $Id: movedata.sql,v 1.29 2003/07/21 00:14:12 nerf Exp $
DROP TABLE logdata_yesterday;

\set ON_ERROR_STOP 1

select now();

INSERT INTO ogr_stubs (stub_marks,project_id)
SELECT DISTINCT L.stub_marks, 0
FROM logdata L
WHERE NOT EXISTS (SELECT * FROM ogr_stubs WHERE
			L.stub_marks = ogr_stubs.stub_marks);

select now();

INSERT INTO platform (os_type,cpu_type,"version")
SELECT DISTINCT L.os_type, L.cpu_type, L.version 
FROM logdata L
WHERE NOT EXISTS (SELECT * FROM platform WHERE 
			L.os_type = platform.os_type AND
			L.cpu_type = platform.cpu_type AND
			L.version = platform.version);
select now();

CREATE TEMP TABLE day_results (
	id INT,
	stub_id INTEGER,
	nodecount BIGINT,
	platform_id INT,
	return_count INT,
	in_results bool DEFAULT false NOT NULL
) WITHOUT OIDS;
select now();

-- aggregate and normalize data
INSERT INTO day_results
SELECT I.id, S.stub_id, L.nodecount, P.platform_id, sum(rowcount)
	FROM (
		SELECT lower(email) AS email, stub_marks, nodecount, 
		os_type, cpu_type, version, count(*) AS rowcount
		FROM logdata
		GROUP BY 
		lower(email), stub_marks, nodecount, os_type, cpu_type, version) L,
	OGR_idlookup I, OGR_stubs S, platform P
	WHERE 
		L.email = lower(I.email)
		AND L.stub_marks = S.stub_marks
		AND L.os_type = P.os_type
		AND L.cpu_type = P.cpu_type
		AND L.version = P.version
	GROUP BY
		I.id, S.stub_id, L.nodecount, P.platform_id;
select now();

CREATE UNIQUE INDEX dayresults_all ON day_results
	(id,stub_id,nodecount,platform_id);
analyze day_results;

UPDATE day_results
SET in_results = true
WHERE exists
(SELECT * FROM OGR_results WHERE day_results.id = OGR_results.id AND
	day_results.stub_id = OGR_results.stub_id AND
	day_results.nodecount = OGR_results.nodecount AND
	day_results.platform_id = OGR_results.platform_id);
select now();

CREATE unique INDEX dayresults_all_count ON day_results
	(id,stub_id,nodecount,platform_id,return_count) WHERE in_results = false;
analyze day_results;

BEGIN;

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

	ALTER TABLE logdata RENAME TO logdata_yesterday;

	CREATE TABLE logdata (
	email VARCHAR(64),
	stub_marks VARCHAR(22),
	nodecount BIGINT,
	os_type INT,
	cpu_type INT,
	version INT)
	WITHOUT OIDS;

COMMIT;

ANALYZE ogr_results;

select now();
