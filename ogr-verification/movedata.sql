-- $Id: movedata.sql,v 1.12 2003/01/01 17:01:05 joel Exp $ --

INSERT INTO stubs:projnum
SELECT DISTINCT I.id, A.stub_id, L.nodecount, L.os_type,
	L.cpu_type, L.version
FROM logdata:projnum L, id_lookup I, all_stubs:projnum A
WHERE L.email = I.email AND
	L.stub_marks = A.stub_marks;

--CREATE INDEX stubs_id_:projnum ON stubs:projnum (id);
--CREATE INDEX stubs_stub_id_:projnum ON stubs:projnum (stub_id);
--CREATE INDEX stubs_nodecount_:projnum ON stubs:projnum (nodecount);
