-- $Id: addlog.sql,v 1.8 2003/01/22 01:34:50 nerf Exp $ --

DROP TABLE logdata;

CREATE TABLE logdata (
email VARCHAR(64),
stub_marks VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT)
WITHOUT OIDS;


COPY logdata FROM '/home/nerf/ogr24.filtered' USING DELIMITERS ',';

--CREATE INDEX log_email ON logdata (email);
--CREATE INDEX log_nodecount ON logdata (nodecount);
--CREATE INDEX log_stubmark ON logdata (stub_marks);
