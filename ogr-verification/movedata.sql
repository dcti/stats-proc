-- $Id: movedata.sql,v 1.7 2002/12/22 22:41:59 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT L.stub_id, L.nodecount, L.os_type,
	L.cpu_type, L.version, I.stats_id 
FROM logdata L, id_lookup I WHERE L.email = I.email;

CREATE INDEX stubs_id ON stubs(stats_id);
CREATE INDEX stubs_stub_id ON stubs(stub_id);
CREATE INDEX stubs_nodecount ON stubs(nodecount);
