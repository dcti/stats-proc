-- $Id: create_id_lookup.sql,v 1.4 2002/12/22 21:10:06 nerf Exp $ --

DROP TABLE id_lookup;

CREATE TABLE id_lookup (
email VARCHAR (255),
stats_id INT);

INSERT INTO id_lookup
SELECT email,
	id,
	(retire_to * (sign(retire_to)) + id * (1-sign(retire_to))) AS stats_id
FROM import_id ;
