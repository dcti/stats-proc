-- $Id: query3.sql,v 1.13 2003/01/08 02:28:11 joel Exp $ --

create table donestubs
(
	stub_id int,
	nodecount bigint,
	participants int
);

insert into donestubs
	select stub_id, nodecount, count(distinct p.stats_id)
	from stubsB, id_lookup p
	where p.id = B.id
	group by stub_id, nodecount;
