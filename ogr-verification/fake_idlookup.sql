-- $Id: fake_idlookup.sql,v 1.3 2002/12/23 00:30:37 joel Exp $

DROP TABLE id_lookup;
DROP SEQUENCE id;
DROP SEQUENCE id_lookup_id_seq;
CREATE SEQUENCE id START 1;

CREATE TABLE id_lookup (
id BIGSERIAL,
stats_id INT,
email VARCHAR(64),
PRIMARY KEY (id));

INSERT INTO id_lookup 
SELECT nextval('id'), nextval('id'), email 
FROM logdata 
GROUP BY email;

CREATE INDEX idlookup_email_idx ON id_lookup (email);
