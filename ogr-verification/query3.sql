-- $Id: query3.sql,v 1.8 2002/12/23 16:57:28 bwilson Exp $ --

create table donestubs
(
	stub_id varchar(22),
	nodecount bigint,
	participants int
)

insert donestubs
	select stub_id, nodecount, count(distinct B.id)
	from stubs B

