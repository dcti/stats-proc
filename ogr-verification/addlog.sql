-- $Id: addlog.sql,v 1.4 2002/12/31 16:39:15 joel Exp $ --
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

CREATE INDEX log:projnum_email_id ON log:foo (email);
CREATE INDEX log:projnum_nodecount_idx ON log:foo (nodecount);
CREATE INDEX log:projnum_stubmark_idx ON log:foo (stub_marks);
