-- $Id: donestubs.sql,v 1.3 2003/01/01 17:01:05 joel Exp $ --

DROP TABLE donestubs:projnum ;

CREATE TABLE donestubs:projnum (
stub_id INT,
nodecount BIGINT,
participants SMALLINT);
