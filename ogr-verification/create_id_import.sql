-- $Id: create_id_import.sql,v 1.4 2002/12/22 22:48:35 nerf Exp $ --

DROP TABLE import_id;

CREATE TABLE import_id (
email VARCHAR (64),
id INTEGER,
retire_to INTEGER
);

COPY import_id FROM '/home/nerf/id_import.out';
