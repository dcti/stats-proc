-- $Id: query3.sql,v 1.16 2003/02/16 19:18:42 nerf Exp $ --

create table OGR_summary
(
	stub_id int,
	nodecount bigint,
	participants int
);

truncate table OGR_summary;

select now();
insert into OGR_summary
	select stub_id, nodecount, count(distinct p.stats_id)
	from OGR_results B, OGR_idlookup p
	where p.id = B.id
	group by stub_id, nodecount;
select now();
