-- $Id: query3.sql,v 1.14 2003/01/14 22:11:01 nerf Exp $ --

create table donestubs
(
	stub_id int,
	nodecount bigint,
	participants int
);

insert into donestubs
	select stub_id, nodecount, count(distinct p.stats_id)
	from stubs B, id_lookup p
	where p.id = B.id
	group by stub_id, nodecount;
