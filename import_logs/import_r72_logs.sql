-- $Id: import_r72_logs.sql,v 1.1 2004/08/15 18:36:12 nerf Exp $

CREATE TEMP TABLE import_r572 (
	return_time	timestamp NOT NULL,
	ip_address	inet NOT NULL,
	email		charactervarying(64) NOT NULL,
	key_block	charactervarying(20) NOT NULL,
	iter		integer NOT NULL,
	os_type		integer NOT NULL,
	cpu_type	integer NOT NULL,
	version		integer NOT NULL,
	core		integer NOT NULL,
	cmclast		charactervarying(20) NOT NULL,
	cmccount	integer NOT NULL,
	cmcok		smallint NOT NULL
);

COPY import_logs from :IMPORTFILE DELIMITER ',' ;

