-- $Id: fake_idlookup.sql,v 1.1 2002/12/22 22:23:20 nerf Exp $

DROP TABLE id_lookup;
DROP SEQUENCE id_lookup_stats_id_seq;
CREATE SEQUENCE id_lookup_stats_id_seq START 1;
DROP SEQUENCE id_lookup_id_seq;
CREATE SEQUENCE id_lookup_id_seq START 1;

CREATE TABLE id_lookup (
stats_id BIGSERIAL,
id BIGSERIAL,
email VARCHAR(64));

INSERT INTO id_lookup
SELECT nextval('stats_id'), DISTINCT email
FROM logdata
GROUP BY email;

CREATE INDEX id_lookup_email_idx ON id_lookup (email);
