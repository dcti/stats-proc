-- $Id: summarize.sql,v 1.2 2003/04/25 21:13:08 nerf Exp $
create table OGR_summary
(
	stub_id int,
	nodecount bigint,
	participants int,
	max_client int
) without oids;

truncate OGR_summary;

CREATE INDEX results_id_count ON ogr_results USING btree (stub_id, nodecount);
CREATE UNIQUE INDEX results_all
	ON ogr_results USING btree (id, stub_id, nodecount, platform_id);

DROP INDEX summ_maxpart;
select now();
insert into OGR_summary
	select stub_id, nodecount,
		count(distinct I.stats_id), max(P.version)
	from OGR_results R, OGR_idlookup I, platform P
	where I.id = R.id
	AND R.platform_id = P.platform_id
	group by stub_id, nodecount;
select now();
CREATE INDEX summ_maxpart on OGR_summary (max_client, participants);
analyze ogr_summary;
