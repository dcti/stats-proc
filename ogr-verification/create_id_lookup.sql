-- $Id: create_id_lookup.sql,v 1.3 2002/12/21 21:13:22 joel Exp $ --

DROP TABLE id_lookup;

CREATE TABLE id_lookup (
email VARCHAR (255),
stats_id INT);

INSERT INTO id_lookup
SELECT email,
	(retire_to * (sign(retire_to)) + id * (1-sign(retire_to))) AS stats_id
FROM import_id ;
