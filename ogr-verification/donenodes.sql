-- $Id: donenodes.sql,v 1.2 2002/12/20 23:55:45 nerf Exp $ --

DROP TABLE donenodes;

CREATE TABLE donenodes (
stub_id VARCHAR(22),
nodecount  BIGINT,
participants SMALLINT);
