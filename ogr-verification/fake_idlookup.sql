-- $Id: fake_idlookup.sql,v 1.5 2003/05/13 14:05:42 nerf Exp $
\set ON_ERROR_STOP 1

DROP TABLE OGR_idlookup;
DROP SEQUENCE id;
DROP SEQUENCE OGR_idlookup_id_seq;
CREATE SEQUENCE id START 1;

CREATE TABLE OGR_idlookup (
id BIGSERIAL,
stats_id INT,
email VARCHAR(64),
PRIMARY KEY (id));

INSERT INTO OGR_idlookup 
SELECT nextval('id'), nextval('id'), email 
FROM logdata 
GROUP BY email;

CREATE INDEX idlookup_email_idx ON OGR_idlookup (email);
