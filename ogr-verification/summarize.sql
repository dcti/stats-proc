-- $Id: summarize.sql,v 1.1 2003/02/16 19:13:20 nerf Exp $
create table OGR_summary
(
	stub_id int,
	nodecount bigint,
	participants int,
	max_client int
) without oids;

truncate OGR_summary;

select now();
insert into OGR_summary
	select stub_id, nodecount,
		count(distinct I.stats_id), max(P.version)
	from OGR_results R, OGR_idlookup I, platform P
	where I.id = R.id
	AND R.platform_id = P.platform_id
	group by stub_id, nodecount;
select now();
