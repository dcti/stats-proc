-- $Id: addlog.sql,v 1.7 2003/01/10 08:58:34 nerf Exp $ --
--set projnum '24' or '25'
--set infile '/home/joel/ogr/scripts/ogr24.filtered'

DROP TABLE logdata;

CREATE TABLE logdata (
email VARCHAR(64),
stub_marks VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);


COPY logdata FROM '/home/joel/ogr/scripts/ogr24.filtered' USING DELIMITERS ',';

CREATE INDEX log_email ON logdata (email);
CREATE INDEX log_nodecount ON logdata (nodecount);
CREATE INDEX log_stubmark ON logdata (stub_marks);
