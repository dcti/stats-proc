-- $Id: donestubs.sql,v 1.2 2002/12/23 18:44:06 nerf Exp $ --

DROP TABLE donestubs;

CREATE TABLE donestubs (
stub_id INT,
nodecount BIGINT,
participants SMALLINT);
