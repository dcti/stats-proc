-- $Id: create_all_stubs.sql,v 1.8 2003/01/22 01:35:39 nerf Exp $

CREATE TEMPORARY TABLE all_stubs_import(
stub_marks VARCHAR(22) not null);

COPY all_stubs_import FROM '/home/nerf/all_stubs24';

DROP SEQUENCE all_stubs_stub_id_seq;

CREATE TABLE all_stubs (
	stub_marks VARCHAR(22) NOT NULL,
	stub_id UNIQUE SERIAL,
	project_id SMALLINT NOT NULL
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
