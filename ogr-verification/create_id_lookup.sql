-- $Id: create_id_lookup.sql,v 1.6 2002/12/22 22:39:29 joel Exp $ --

DROP TABLE id_lookup;

CREATE TABLE id_lookup (
email VARCHAR (64),
id INTEGER
stats_id INTEGER);

INSERT INTO id_lookup
SELECT email,
	id,
	(retire_to * (sign(retire_to)) + id * (1-sign(retire_to))) AS stats_id
FROM import_id ;
