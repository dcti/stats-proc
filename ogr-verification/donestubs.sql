-- $Id: donestubs.sql,v 1.1 2002/12/22 21:24:19 joel Exp $ --

DROP TABLE donestubs;

CREATE TABLE donestubs (
stub_id VARCHAR(22),
nodecount  BIGINT,
participants SMALLINT);
