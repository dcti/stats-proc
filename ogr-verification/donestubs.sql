-- $Id: donestubs.sql,v 1.5 2003/02/16 19:18:42 nerf Exp $ --

DROP TABLE OGR_summary;

CREATE TABLE OGR_summary (
stub_id INT,
nodecount BIGINT,
participants SMALLINT);
