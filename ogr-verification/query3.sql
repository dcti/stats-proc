-- $Id: query3.sql,v 1.4 2002/12/22 21:26:41 nerf Exp $ --

SELECT DISTINCT stub_id, nodecount, (SELECT count(DISTINCT p.stats_id)
FROM stubs B, id_lookup p
WHERE p.id = B.id AND B.nodecount = A.nodecount) AS participants
INTO donestubs
FROM stubs A;
