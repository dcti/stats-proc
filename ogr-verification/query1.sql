-- $Id: query1.sql,v 1.2 2002/12/20 23:55:45 nerf Exp $ --

select distinct stub_id, nodecount, (select count(distinct email)
from logdata B
where B.nodecount = A.nodecount) AS participants
from logdata A;
