-- $Id: query3.sql,v 1.10 2002/12/24 00:05:32 bwilson Exp $ --

create table donestubs
(
	stub_id int,
	nodecount bigint,
	participants int
)

insert donestubs
	select stub_id, nodecount, count(distinct p.stats_id)
	from nodes B, id_lookup p
	where p.email = B.email
	group by stub_id, nodecount
