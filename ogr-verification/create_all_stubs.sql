-- $Id: create_all_stubs.sql,v 1.11 2003/05/13 14:05:42 nerf Exp $
\set ON_ERROR_STOP 1

CREATE TEMPORARY TABLE OGR_stubs_import(
stub_marks VARCHAR(22) not null);

COPY OGR_stubs_import FROM '/home/nerf/all_stubs24';

DROP SEQUENCE OGR_stubs_stub_id_seq;

CREATE TABLE OGR_stubs (
	stub_marks VARCHAR(22) NOT NULL,
	stub_id UNIQUE SERIAL,
	project_id SMALLINT NOT NULL
);

INSERT INTO OGR_stubs
        SELECT stub_marks, NEXTVAL('OGR_stubs_stub_id_seq'),'24', 0, NULL, NULL
FROM OGR_stubs_import ;

DROP TABLE OGR_stubs_import ;

CREATE TEMPORARY TABLE OGR_stubs_import(
stub_marks VARCHAR(22) not null);

COPY OGR_stubs_import FROM '/home/nerf/all_stubs25';

INSERT INTO OGR_stubs
        SELECT stub_marks, NEXTVAL('OGR_stubs_stub_id_seq'),'25', 0, NULL, NULL
FROM OGR_stubs_import ;

CREATE UNIQUE INDEX stubs_marks ON OGR_stubs (stub_marks);
CREATE UNIQUE INDEX stubs_projstub ON OGR_stubs (project_id,stub_id);
ALTER TABLE OGR_stubs ADD PRIMARY KEY (stub_id);
