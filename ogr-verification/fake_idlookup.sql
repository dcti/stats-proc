-- $Id: fake_idlookup.sql,v 1.4 2003/02/16 19:18:42 nerf Exp $

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
