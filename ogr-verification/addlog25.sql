-- $Id: addlog25.sql,v 1.6 2002/12/24 19:06:48 nerf Exp $ --

DROP TABLE logdata;

CREATE TABLE logdata (
email VARCHAR(64),
stub_marks VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);


COPY logdata FROM '/home/postgres/ogr25.filtered' USING DELIMITERS ',';

CREATE INDEX log_email_idx ON logdata (email);
CREATE INDEX log_nodecount_idx ON logdata (nodecount);
CREATE INDEX log_stubmark_idx ON logdata (stub_marks);
