-- $Id: movedata.sql,v 1.21 2003/01/22 19:31:23 nerf Exp $

CREATE TEMP TABLE day_results (
	id INT,
	stub_id INTEGER,
	nodecount BIGINT,
	platform_id INT
) ;

INSERT INTO platform (os_type,cpu_type,"version")
SELECT DISTINCT ld.os_type, ld.cpu_type, ld.version 
FROM logdata ld
WHERE NOT EXISTS (SELECT 1 WHERE 
			ld.os_type = platform.os_type AND
			ld.cpu_type = platform.cpu_type AND
			ld.version = platform.version);

INSERT INTO day_results
SELECT I.id, A.stub_id, L.nodecount, P.platform_id
FROM logdata L, id_lookup I, all_stubs A, platform P
WHERE lower(L.email) = lower(I.email) AND
	L.stub_marks = A.stub_marks;

CREATE INDEX dayresults_all ON day_results
	(id,stub_id,nodecount,platform_id); 


BEGIN;
	UPDATE stubs
	SET return_count = COALESCE(return_count,0) +
		( SELECT count(*)
		FROM day_results dr
		WHERE dr.id = stubs.id AND
			dr.stub_id = stubs.stub_id AND
			dr.nodecount = stubs.nodecount AND
			dr.platform_id = stubs.platform_id)
	WHERE exists
	(SELECT * from day_results dr WHERE dr.id = stubs.id AND
		dr.stub_id = stubs.stub_id AND
		dr.nodecount = stubs.nodecount AND
		dr.platform_id = stubs.platform_id);

	INSERT INTO stubs
	SELECT dr.id, dr.stub_id, dr.nodecount, dr.platform_id
	FROM day_results dr 
	WHERE NOT EXISTS (SELECT 1 WHERE dr.id = stubs.id AND
				dr.stub_id = stubs.stub_id AND
				dr.nodecount = stubs.nodecount AND
				dr.platform_id = stubs.platform_id)
	GROUP BY dr.id, dr.stub_id, dr.nodecount, dr.platform_id;

	DROP TABLE logdata;

	CREATE TABLE logdata (
	email VARCHAR(64),
	stub_marks VARCHAR(22),
	nodecount BIGINT,
	os_type SMALLINT,
	cpu_type SMALLINT,
	version INT)
	WITHOUT OIDS;

COMMIT;
