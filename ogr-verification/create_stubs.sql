-- $Id: create_stubs.sql,v 1.7 2003/01/08 02:20:44 joel Exp $ --

CREATE TABLE stubs (
id INT,
stub_id INTEGER,
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);

CREATE INDEX stubs_email_idx ON stubs (email);
CREATE INDEX stubs_nodecount_idx ON stubs (nodecount);
CREATE INDEX stubs_stubid_idx ON stubs (stub_id);
