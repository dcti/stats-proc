-- $Id: create_all_stubs.sql,v 1.12 2003/09/02 14:08:02 nerf Exp $

DROP TABLE OGR_stubs;

DROP SEQUENCE OGR_stubs_stub_id_seq;

CREATE TABLE OGR_stubs (
	stub_marks VARCHAR(22) NOT NULL,
	stub_id SERIAL, -- UNIQUE not working ?
	project_id SMALLINT NOT NULL
)WITHOUT OIDS;

\set ON_ERROR_STOP 1

CREATE TEMPORARY TABLE OGR_stubs_import(
stub_marks VARCHAR(22) not null);

COPY OGR_stubs_import FROM
'/home/nerf/dnet/stats-proc/ogr-verification/all_stubs25';

INSERT INTO OGR_stubs
        SELECT stub_marks, NEXTVAL('OGR_stubs_stub_id_seq'),'25'
FROM OGR_stubs_import ;

TRUNCATE OGR_stubs_import ;

COPY OGR_stubs_import FROM
'/home/nerf/dnet/stats-proc/ogr-verification/all_stubs24';

INSERT INTO OGR_stubs
        SELECT stub_marks, NEXTVAL('OGR_stubs_stub_id_seq'),'24'
FROM OGR_stubs_import ;

CREATE UNIQUE INDEX stubs_marks ON OGR_stubs (stub_marks);
CREATE UNIQUE INDEX stubs_projstub ON OGR_stubs (project_id,stub_id);
ALTER TABLE OGR_stubs ADD PRIMARY KEY (stub_id);
