-- $Id: addlog24.sql,v 1.3 2002/12/23 18:44:06 nerf Exp $ --

DROP TABLE logdata;

CREATE TABLE logdata (
email VARCHAR(64),
stub_marks VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);


COPY logdata FROM '/home/joel/ogr/scripts/ogr24.filtered' USING DELIMITERS ',';

CREATE INDEX log_id_idx ON logdata (id);
CREATE INDEX log_nodecount_idx ON logdata (nodecount);
CREATE INDEX log_stubmark_idx ON logdata (stub_marks);
