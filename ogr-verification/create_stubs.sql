-- $Id: create_stubs.sql,v 1.6 2003/01/01 17:01:05 joel Exp $ --

CREATE TABLE stubs:projnum (
id INT,
stub_id INTEGER,
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);

CREATE INDEX stubs_email_idx:projnum ON stubs:projnum (email);
CREATE INDEX stubs_nodecount_idx:projnum ON stubs:projnum (nodecount);
CREATE INDEX stubs_stubid_idx:projnum ON stubs:projnum (stub_id);
