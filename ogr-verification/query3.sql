-- $Id --

select distinct stub_id, nodecount, (select count(distinct p.stats_id)
from nodes B, id_lookup p
where p.email = B.email and B.nodecount = A.nodecount) AS participants
into donenodes
from nodes A;
