-- $Id: query3.sql,v 1.12 2003/01/01 17:01:05 joel Exp $ --

create table donestubs:projnum
(
	stub_id int,
	nodecount bigint,
	participants int
);

insert into donestubs:projnum
	select stub_id, nodecount, count(distinct p.stats_id)
	from stubs:projnum B, id_lookup p
	where p.id = B.id
	group by stub_id, nodecount;
