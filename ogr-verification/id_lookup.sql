-- $Id: id_lookup.sql,v 1.4 2002/12/22 21:24:19 joel Exp $ --

DROP TABLE id_lookup;
DROP SEQUENCE id_lookup_stats_id_seq;
CREATE SEQUENCE stats_id START 1;

CREATE TABLE id_lookup (
stats_id BIGSERIAL,
email VARCHAR(64),
PRIMARY KEY (stats_id));

INSERT INTO id_lookup SELECT nextval('stats_id'), distinct email FROM logdata GROUP BY email;

CREATE INDEX id_lookup_email_idx on id_lookup (email);
