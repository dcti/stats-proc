-- $Id: donestubs.sql,v 1.4 2003/01/08 02:22:29 joel Exp $ --

DROP TABLE donestubs;

CREATE TABLE donestubs (
stub_id INT,
nodecount BIGINT,
participants SMALLINT);
