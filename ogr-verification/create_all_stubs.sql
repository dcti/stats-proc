-- $Id: create_all_stubs.sql,v 1.2 2003/01/01 17:01:05 joel Exp $
-- set infile='/home/nerf/all_stubs'

--DROP SEQUENCE stub_id;
CREATE SEQUENCE stub_id START 1;

CREATE TEMPORARY TABLE all_stubs_import:projnum (
stub_marks VARCHAR(22) not null);

COPY all_stubs_import:projnum FROM :infile;

CREATE TABLE all_stubs:projnum (
stub_marks VARCHAR(22) not null,
stub_id INT DEFAULT NEXTVAL('stub_id') not null,
completed INT DEFAULT 0);

INSERT INTO all_stubs:projnum
        SELECT stub_marks, NEXTVAL('stub_id'), 0
FROM all_stubs_import:projnum ;

--DROP TABLE all_stubs_import:projnum ;

CREATE INDEX all_marks_:projnum ON all_stubs:projnum (stub_marks);
ALTER TABLE all_stubs:projnum ADD PRIMARY KEY (stub_id);
