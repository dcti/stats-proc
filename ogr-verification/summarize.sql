-- $Id: summarize.sql,v 1.3 2003/05/03 12:25:07 nerf Exp $
create table OGR_summary
(
	stub_id int,
	nodecount bigint,
	participants int,
	max_client int
) without oids;

CREATE INDEX results_id_count ON ogr_results USING btree (stub_id, nodecount);
CREATE UNIQUE INDEX results_all
	ON ogr_results USING btree (id, stub_id, nodecount, platform_id);

DROP INDEX summ_maxpart;
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

VACUUM ANALYZE ogr_summary;
