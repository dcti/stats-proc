-- $Id: movedata.sql,v 1.5 2002/12/22 21:24:19 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT logdata.stub_id, logdata.nodecount, logdata.os_type,
logdata.cpu_type, logdata.version, id_lookup.id 
FROM logdata, id_lookup WHERE logdata.email = id_lookup.email;

CREATE INDEX stubs_email ON stubs(email);
CREATE INDEX stubs_stub_id ON stubs(stub_id);
CREATE INDEX stubs_nodecount ON stubs(nodecount);
