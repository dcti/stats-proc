-- $Id: movedata.sql,v 1.6 2002/12/22 21:33:11 nerf Exp $ --

INSERT INTO stubs
SELECT DISTINCT L.stub_id, L.nodecount, L.os_type,
	L.cpu_type, L.version, I.id 
FROM logdata L, id_lookup I WHERE L.email = I.email;

CREATE INDEX stubs_id ON stubs(id);
CREATE INDEX stubs_stub_id ON stubs(stub_id);
CREATE INDEX stubs_nodecount ON stubs(nodecount);
