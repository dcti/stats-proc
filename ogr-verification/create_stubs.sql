-- $Id: create_stubs.sql,v 1.9 2003/01/22 01:38:37 nerf Exp $ --

CREATE TABLE stubs (
id INT,
stub_id INTEGER,
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INTEGER,
return_count INTEGER
);

--CREATE INDEX stubs_email ON stubs (email);
--CREATE INDEX stubs_nodecount ON stubs (nodecount);
--CREATE INDEX stubs_stubid ON stubs (stub_id);
CREATE UNIQUE INDEX stubs_all on stubs
	(id,stub_id,nodecount,os_type,cpu_type,version); 
