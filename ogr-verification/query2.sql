-- $Id: query2.sql,v 1.2 2002/12/20 23:55:45 nerf Exp $ --

insert into donenodes
select distinct stub_id, nodecount, (select count(distinct p.stats_id)
from nodes B, id_lookup p
where p.email = B.email and B.nodecount = A.nodecount) AS participants
from nodes A;
