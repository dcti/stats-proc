-- $Id: addlog.sql,v 1.6 2002/12/31 18:08:45 joel Exp $ --
--set projnum '24' or '25'
--set infile '/home/joel/ogr/scripts/ogr24.filtered'

DROP TABLE logdata:projnum;

CREATE TABLE logdata:projnum (
email VARCHAR(64),
stub_marks VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);


COPY logdata:projnum FROM :infile USING DELIMITERS ',';

CREATE INDEX log_email_idx:projnum ON logdata:projnum (email);
CREATE INDEX log_nodecount_idx:projnum ON logdata:projnum (nodecount);
CREATE INDEX log_stubmark_idx:projnum ON logdata:projnum (stub_marks);
