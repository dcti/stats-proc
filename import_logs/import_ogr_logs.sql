-- $Id: import_ogr_logs.sql,v 1.1 2004/08/15 18:36:12 nerf Exp $

CREATE TEMP TABLE import_ogr (
	return_time	timestamp NOT NULL,
	ip_address	inet NOT NULL,
	email		charactervarying(64) NOT NULL,
	stub_marks	charactervarying(22) NOT NULL,
	nodecount	bigint NOT NULL,
	os_type		integer NOT NULL,
	cpu_type	integer NOT NULL,
	version		integer NOT NULL,
	status		smallint NOT NULL
);

COPY import_logs from :IMPORTFILE DELIMITER ',' ;

