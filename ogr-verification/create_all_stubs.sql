-- $Id: create_all_stubs.sql,v 1.6 2003/01/10 17:26:34 nerf Exp $
-- set infile='/home/nerf/all_stubs'

CREATE TEMPORARY TABLE all_stubs_import(
stub_marks VARCHAR(22) not null);

COPY all_stubs_import FROM '/home/nerf/all_stubs24';

DROP SEQUENCE all_stubs_stub_id_seq;

CREATE TABLE all_stubs (
	stub_marks VARCHAR(22) not null,
	stub_id SERIAL,
	project_id SMALLINT not null,
	nodecount BIGINT,
	pass1_id INT,
	pass2_id INT
);

INSERT INTO all_stubs
        SELECT stub_marks, NEXTVAL('all_stubs_stub_id_seq'),'24', 0, NULL, NULL
FROM all_stubs_import ;

DROP TABLE all_stubs_import ;

CREATE TEMPORARY TABLE all_stubs_import(
stub_marks VARCHAR(22) not null);

COPY all_stubs_import FROM '/home/nerf/all_stubs25';

INSERT INTO all_stubs
        SELECT stub_marks, NEXTVAL('all_stubs_stub_id_seq'),'25', 0, NULL, NULL
FROM all_stubs_import ;

CREATE UNIQUE INDEX all_marks ON all_stubs (stub_marks);
CREATE UNIQUE INDEX all_stubproject_id ON all_stubs (stub_id,project_id);
ALTER TABLE all_stubs ADD PRIMARY KEY (stub_id);
