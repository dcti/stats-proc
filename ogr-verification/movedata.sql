-- $Id: movedata.sql,v 1.13 2003/01/08 02:27:19 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT I.id, A.stub_id, L.nodecount, L.os_type,
	L.cpu_type, L.version
FROM logdataL, id_lookup I, all_stubsA
WHERE L.email = I.email AND
	L.stub_marks = A.stub_marks;

--CREATE INDEX stubs_id ON stubs(id);
--CREATE INDEX stubs_stub_id ON stubs(stub_id);
--CREATE INDEX stubs_nodecount ON stubs(nodecount);
