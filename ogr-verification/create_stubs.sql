-- $Id: create_stubs.sql,v 1.11 2003/02/16 19:18:42 nerf Exp $ --

CREATE TABLE OGR_results (
id INT,
stub_id INTEGER,
nodecount BIGINT,
platform_id INTEGER,
return_count INTEGER
);

--CREATE INDEX stubs_email ON stubs (email);
--CREATE INDEX stubs_nodecount ON stubs (nodecount);
--CREATE INDEX stubs_stubid ON stubs (stub_id);
CREATE UNIQUE INDEX OGR_results_all on OGR_results
	(id,stub_id,nodecount,platform_id); 
