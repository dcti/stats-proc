-- $Id: movedata.sql,v 1.22 2003/02/03 05:47:39 nerf Exp $

INSERT INTO platform (os_type,cpu_type,"version")
SELECT DISTINCT L.os_type, L.cpu_type, L.version 
FROM logdata L
WHERE NOT EXISTS (SELECT * from platform WHERE 
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
	in_stubs bool DEFAULT false NOT NULL
) WITHOUT OIDS;
select now();

-- aggregate all the data
INSERT INTO day_results(id, stub_id, nodecount, platform_id, return_count)
SELECT I.id, A.stub_id, L.nodecount, P.platform_id, count(*)
	FROM logdata L, id_lookup I, all_stubs A, platform P
	WHERE lower(L.email) = lower(I.email)
	AND L.stub_marks = A.stub_marks
	AND L.os_type = P.os_type
	AND L.cpu_type = P.cpu_type
	AND L.version = P.version
	GROUP BY I.id, A.stub_id, L.nodecount, P.platform_id
;
select now();

CREATE unique INDEX dayresults_all ON day_results
	(id,stub_id,nodecount,platform_id);

UPDATE day_results
SET in_stubs = true
WHERE exists
(SELECT * from stubs WHERE day_results.id = stubs.id AND
	day_results.stub_id = stubs.stub_id AND
	day_results.nodecount = stubs.nodecount AND
	day_results.platform_id = stubs.platform_id);
select now();

CREATE unique INDEX dayresults_all_count ON day_results
	(id,stub_id,nodecount,platform_id,return_count) WHERE in_stubs = false;

BEGIN;

	UPDATE stubs
	SET return_count = COALESCE(stubs.return_count,0) + dr.return_count
	FROM day_results dr
	WHERE dr.id = stubs.id AND
		dr.stub_id = stubs.stub_id AND
		dr.nodecount = stubs.nodecount AND
		dr.platform_id = stubs.platform_id AND
		dr.in_stubs = true;
select now();

	INSERT INTO stubs
	SELECT dr.id, dr.stub_id, dr.nodecount, dr.platform_id, dr.return_count
	FROM day_results dr 
	WHERE dr.in_stubs = false;
select now();

	DROP TABLE logdata;

	CREATE TABLE logdata (
	email VARCHAR(64),
	stub_marks VARCHAR(22),
	nodecount BIGINT,
	os_type INT,
	cpu_type INT,
	version INT)
	WITHOUT OIDS;

COMMIT;
select now();
