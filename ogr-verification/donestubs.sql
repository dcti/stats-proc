-- $Id: donestubs.sql,v 1.6 2003/05/13 14:05:42 nerf Exp $ --
\set ON_ERROR_STOP 1

DROP TABLE OGR_summary;

CREATE TABLE OGR_summary (
stub_id INT,
nodecount BIGINT,
participants SMALLINT);
