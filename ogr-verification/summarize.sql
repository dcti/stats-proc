-- $Id: summarize.sql,v 1.5 2003/07/21 00:19:44 nerf Exp $

create table OGR_summary
(
	stub_id int not null,
	nodecount bigint not null,
	participants int not null,
	max_client int not null
) without oids;

DROP INDEX summ_maxpart;

\set ON_ERROR_STOP 1

TRUNCATE OGR_summary;

SELECT now();
INSERT INTO OGR_summary
	SELECT stub_id, nodecount,
		count(DISTINCT I.stats_id), max(P.version)
	FROM OGR_results R, OGR_idlookup I, platform P
	WHERE I.id = R.id
	AND R.platform_id = P.platform_id
	GROUP BY stub_id, nodecount;

SELECT now();

CREATE INDEX summ_maxpart on OGR_summary (max_client, participants);

ANALYZE ogr_summary;
