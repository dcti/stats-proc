-- $Id: movedata.sql,v 1.20 2003/01/22 18:36:15 nerf Exp $ --

CREATE TEMP TABLE day_results (
	id INT,
	stub_id INTEGER,
	nodecount BIGINT,
	os_type SMALLINT,
	cpu_type SMALLINT,
	version INT) ;

BEGIN;
	INSERT INTO day_results
	SELECT I.id, A.stub_id, L.nodecount, L.os_type,
		L.cpu_type, L.version
	FROM logdata L, id_lookup I, all_stubs A
	WHERE lower(L.email) = lower(I.email) AND
		L.stub_marks = A.stub_marks;

	CREATE INDEX dayresults_all ON day_results
		(id,stub_id,nodecount,os_type,cpu_type,version); 

	UPDATE stubs
	SET return_count = COALESCE(return_count,0) +
		( SELECT count(*)
		FROM day_results dr
		WHERE dr.id = stubs.id AND
			dr.stub_id = stubs.stub_id AND
			dr.nodecount = stubs.nodecount AND
			dr.os_type = stubs.os_type AND
			dr.cpu_type = stubs.cpu_type AND
			dr.version = stubs.version)
	WHERE exists
	(SELECT * from day_results dr WHERE dr.id = stubs.id AND
		dr.stub_id = stubs.stub_id AND
		dr.nodecount = stubs.nodecount AND
		dr.os_type = stubs.os_type AND
		dr.cpu_type = stubs.cpu_type AND
		dr.version = stubs.version);

	INSERT INTO stubs
	SELECT dr.id, dr.stub_id, dr.nodecount, dr.os_type, dr.cpu_type,
		dr.version 
	FROM day_results dr 
	WHERE NOT EXISTS (SELECT 1 WHERE dr.id = stubs.id AND
				dr.stub_id = stubs.stub_id AND
				dr.nodecount = stubs.nodecount AND
				dr.os_type = stubs.os_type AND
				dr.cpu_type = stubs.cpu_type AND
				dr.version = stubs.version)
	GROUP BY dr.id, dr.stub_id, dr.nodecount, dr.os_type, dr.cpu_type, dr.version;

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
