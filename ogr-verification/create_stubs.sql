-- $Id: create_stubs.sql,v 1.5 2002/12/23 18:44:06 nerf Exp $ --

CREATE TABLE stubs (
id INT,
stub_id INTEGER,
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);

--CREATE INDEX stubs_email_idx ON stubs (email);
--CREATE INDEX stubs_nodecount_idx ON stubs (nodecount);
--CREATE INDEX stubs_stubid_idx ON stubs (stub_id);
