-- $Id: query3.sql,v 1.7 2002/12/23 16:54:31 bwilson Exp $ --

-- id_lookup p became irrelevant as id was already present in B
SELECT DISTINCT stub_id, nodecount, (SELECT count(DISTINCT B.id)
FROM stubs B
WHERE B.nodecount = A.nodecount AND B.stub_id = A.stub_id) AS participants
INTO donestubs
FROM stubs A;

-- Or better yet...

create table donestubs
(
	stub_id varchar(22),
	nodecount bigint,
	participants int
)

insert donestubs
	select stub_id, nodecount, count(distinct B.id)
	from stubs B

