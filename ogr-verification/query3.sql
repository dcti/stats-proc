-- $Id: query3.sql,v 1.15 2003/02/03 05:49:28 nerf Exp $ --

create table donestubs
(
	stub_id int,
	nodecount bigint,
	participants int
);

truncate table donestubs;

select now();
insert into donestubs
	select stub_id, nodecount, count(distinct p.stats_id)
	from stubs B, id_lookup p
	where p.id = B.id
	group by stub_id, nodecount;
select now();
