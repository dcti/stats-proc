-- $Id: addlog25.sql,v 1.3 2002/12/23 01:35:30 joel Exp $ --

DROP TABLE logdata;

CREATE TABLE logdata (
email varchar(64),
stub_id VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT,
id INT);


COPY logdata FROM '/home/postgres/ogr25.filtered' USING DELIMITERS ',';

CREATE INDEX id_idx ON logdata (email);
CREATE INDEX nodecount_idx ON logdata (nodecount);
CREATE INDEX stubid_idx ON logdata (stub_id);
