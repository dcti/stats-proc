-- $Id --

INSERT INTO nodes
SELECT DISTINCT email , stub_id, stub_string_id , nodecount, os_type, cpu_type, version
FROM logdata;

CREATE INDEX nodes_email ON nodes(email);
CREATE INDEX nodes_stub_id ON nodes(stub_id);
CREATE INDEX nodes_nodecount ON nodes(nodecount);
