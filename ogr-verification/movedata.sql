-- $Id: movedata.sql,v 1.4 2002/12/21 23:06:54 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT email , stub_id, nodecount, os_type, cpu_type, version
FROM logdata;

CREATE INDEX stubs_email ON stubs(email);
CREATE INDEX stubs_stub_id ON stubs(stub_id);
CREATE INDEX stubs_nodecount ON stubs(nodecount);
