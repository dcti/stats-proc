-- $Id: create_stubs.sql,v 1.3 2002/12/22 21:24:19 joel Exp $ --

CREATE TABLE stubs (
stub_id VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT,
stats_id INT);


--CREATE INDEX stubs_email_idx ON stubs (email);
--CREATE INDEX stubs_nodecount_idx ON stubs (nodecount);
--CREATE INDEX stubs_stubid_idx ON stubs (stub_id);
