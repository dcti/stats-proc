-- $Id: movedata.sql,v 1.3 2002/12/21 21:13:22 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT email , stub_id, stub_string_id , nodecount, os_type, cpu_type, version
FROM logdata;

CREATE INDEX stubs_email ON stubs(email);
CREATE INDEX stubs_stub_id ON stubs(stub_id);
CREATE INDEX stubs_nodecount ON stubs(nodecount);
