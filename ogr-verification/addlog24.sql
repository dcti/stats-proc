-- $Id: addlog24.sql,v 1.1 2002/12/21 21:13:22 joel Exp $ --

DROP TABLE logdata;

CREATE TABLE logdata (
email VARCHAR(64),
stub_id VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);


COPY logdata FROM '/home/joel/ogr/scripts/ogr24.filtered' USING DELIMITERS ',';

CREATE INDEX email_idx ON logdata (email);
CREATE INDEX nodecount_idx ON logdata (nodecount);
CREATE INDEX stubid_idx ON logdata (stub_id);
