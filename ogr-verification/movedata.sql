-- $Id: movedata.sql,v 1.16 2003/01/18 00:53:50 nerf Exp $ --

CREATE TABLE TEMP normal_stubs (
	id INT,
	stub_id INTEGER,
	nodecount BIGINT,
	os_type SMALLINT,
	cpu_type SMALLINT,
	version INT);

BEGIN;
	INSERT INTO normal_stubs
	SELECT I.id, A.stub_id, L.nodecount, L.os_type,
		L.cpu_type, L.version
	FROM logdata L, id_lookup I, all_stubs A
	WHERE L.email = I.email AND
		L.stub_marks = A.stub_marks;

	UPDATE stubs s 
		SET s.return_count = s.return_count +
			( SELECT count(*)
				FROM normal_stubs n
				WHERE n.id = s.id AND
					n.stub_id = s.stub_id AND 
					n.nodecount = s.nodecount AND
					n.os_type = s.os_type AND
					n.cpu_type = s.cpu_type AND
					n.version = s.version)

	INSERT INTO stubs s
	SELECT n.*
	FROM normal_stubs n
	WHERE NOT EXISTS (SELECT 1 WHERE n.id = s.id AND
				n.stub_id = s.stub_id AND
				n.nodecount = s.nodecount AND
				n.os_type = s.os_type AND
				n.cpu_type = s.cpu_type AND
				n.version = s.version)
	GROUP BY n.id, n.stub_id, n.nodecount, n.os_type, n.cpu_type, n.version;

	DROP TABLE logdata;
COMMIT;

--CREATE INDEX stubs_id ON stubs(id);
--CREATE INDEX stubs_stub_id ON stubs(stub_id);
--CREATE INDEX stubs_nodecount ON stubs(nodecount);
