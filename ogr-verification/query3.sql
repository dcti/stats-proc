-- $Id: query3.sql,v 1.3 2002/12/21 21:13:22 joel Exp $ --

SELECT DISTINCT stub_id, nodecount, (SELECT count(DISTINCT p.stats_id)
FROM stubs B, id_lookup p
WHERE p.email = B.email AND B.nodecount = A.nodecount) AS participants
INTO donestubs
FROM stubs A;
