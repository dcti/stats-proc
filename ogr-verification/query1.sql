-- $Id --

select distinct stub_id, nodecount, (select count(distinct email)
from logdata B
where B.nodecount = A.nodecount) AS participants
from logdata A;
