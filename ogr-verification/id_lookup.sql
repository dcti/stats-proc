-- $Id --

DROP TABLE id_lookup;
DROP SEQUENCE id_lookup_stats_id_seq;
CREATE SEQUENCE stats_id START 1;

CREATE TABLE id_lookup (
stats_id BIGSERIAL,
email VARCHAR(50),
PRIMARY KEY (stats_id));

INSERT INTO id_lookup SELECT nextval('stats_id'), email FROM nodes GROUP BY email;

CREATE INDEX id_lookup_email_idx on id_lookup (email);
