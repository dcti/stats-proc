-- $Id: addlog24.sql,v 1.2 2002/12/23 01:53:12 joel Exp $ --

DROP TABLE logdata;

CREATE TABLE logdata (
email VARCHAR(64),
stub_id VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT,
id INT);


COPY logdata FROM '/home/joel/ogr/scripts/ogr24.filtered' USING DELIMITERS ',';

CREATE INDEX id_idx ON logdata (id);
CREATE INDEX nodecount_idx ON logdata (nodecount);
CREATE INDEX stubid_idx ON logdata (stub_id);
