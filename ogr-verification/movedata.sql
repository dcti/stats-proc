-- $Id: movedata.sql,v 1.17 2003/01/22 01:22:21 nerf Exp $ --

CREATE TEMP TABLE normal_stubs (
	id INT,
	stub_id INTEGER,
	nodecount BIGINT,
	os_type SMALLINT,
	cpu_type SMALLINT,
	version INT) ;

BEGIN;
	INSERT INTO normal_stubs
	SELECT I.id, A.stub_id, L.nodecount, L.os_type,
		L.cpu_type, L.version
	FROM logdata L, id_lookup I, all_stubs A
	WHERE lower(L.email) = lower(I.email) AND
		L.stub_marks = A.stub_marks;

--This update isn't working for some reason
	UPDATE stubs
	SET return_count = return_count +
		( SELECT count(*)
		FROM normal_stubs n, stubs
		WHERE n.id = stubs.id AND
			n.stub_id = stubs.stub_id AND 
			n.nodecount = stubs.nodecount AND
			n.os_type = stubs.os_type AND
			n.cpu_type = stubs.cpu_type AND
			n.version = stubs.version);

	INSERT INTO stubs
	SELECT n.id, n.stub_id, n.nodecount, n.os_type, n.cpu_type,
		n.version --, count(*) as return_count
	FROM normal_stubs n 
	WHERE NOT EXISTS (SELECT 1 WHERE n.id = stubs.id AND
				n.stub_id = stubs.stub_id AND
				n.nodecount = stubs.nodecount AND
				n.os_type = stubs.os_type AND
				n.cpu_type = stubs.cpu_type AND
				n.version = stubs.version)
	GROUP BY n.id, n.stub_id, n.nodecount, n.os_type, n.cpu_type, n.version;

--	DROP TABLE logdata;
COMMIT;

--CREATE INDEX stubs_id ON stubs(id);
--CREATE INDEX stubs_stub_id ON stubs(stub_id);
--CREATE INDEX stubs_nodecount ON stubs(nodecount);
