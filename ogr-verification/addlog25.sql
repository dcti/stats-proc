-- $Id: addlog25.sql,v 1.2 2002/12/22 21:24:19 joel Exp $ --

DROP TABLE logdata;

CREATE TABLE logdata (
stub_id VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT
id INT);


COPY logdata FROM '/home/postgres/ogr25.filtered' USING DELIMITERS ',';

CREATE INDEX email_idx ON logdata (email);
CREATE INDEX nodecount_idx ON logdata (nodecount);
CREATE INDEX stubid_idx ON logdata (stub_id);
