-- $Id: diff_counts.sql,v 1.2 2002/12/27 04:54:58 nerf Exp $

-- find stubs that have different nodecounts

create temp diff_counts as
select stub_id, count(distinct nodecount) as counts
from stubs
group by stub_id
having count(distinct nodecount) >1;

SELECT I.email, A.stub_marks, S.nodecount, S.os_type,
	S.cpu_type, S.version
FROM stubs S, id_lookup I, all_stubs A, diff_counts C
WHERE S.email = I.email AND
	S.stub_marks = A.stub_marks AND
	S.stub_id = C.stub_id
ORDER BY A.stub_marks;
