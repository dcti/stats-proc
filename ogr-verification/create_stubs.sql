-- $Id: create_stubs.sql,v 1.1 2002/12/21 22:57:30 joel Exp $ --

CREATE TABLE stubs (
email VARCHAR(64),
stub_id VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);


CREATE INDEX stubs_email_idx ON stubs (email);
CREATE INDEX stubs_nodecount_idx ON stubs (nodecount);
CREATE INDEX stubs_stubid_idx ON stubs (stub_id);
