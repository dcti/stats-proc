-- $Id: create_all_stubs.sql,v 1.3 2003/01/04 21:42:37 nerf Exp $
-- set infile='/home/nerf/all_stubs'

CREATE TEMPORARY TABLE all_stubs_import:projnum (
stub_marks VARCHAR(22) not null);

COPY all_stubs_import:projnum FROM :infile;

CREATE TABLE all_stubs:projnum (
	stub_marks VARCHAR(22) not null,
	stub_id SERIAL,
	nodecount BIGINT,
	pass1_id INT,
	pass2_id INT
);

INSERT INTO all_stubs:projnum
        SELECT stub_marks, NEXTVAL('stub_id'), 0
FROM all_stubs_import:projnum ;

--DROP TABLE all_stubs_import:projnum ;

CREATE INDEX all_marks_:projnum ON all_stubs:projnum (stub_marks);
ALTER TABLE all_stubs:projnum ADD PRIMARY KEY (stub_id);
