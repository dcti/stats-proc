-- $Id: query3.sql,v 1.9 2002/12/23 18:44:06 nerf Exp $ --

create table donestubs
(
	stub_id int,
	nodecount bigint,
	participants int
)

insert donestubs
	select stub_id, nodecount, count(distinct B.id)
	from stubs B

