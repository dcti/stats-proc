-- $Id: query3.sql,v 1.5 2002/12/23 00:05:03 bwilson Exp $ --

SELECT DISTINCT stub_id, nodecount, (SELECT count(DISTINCT p.stats_id)
FROM stubs B, id_lookup p
WHERE p.id = B.id AND B.nodecount = A.nodecount AND B.stub_id = A.stub_id) AS participants
INTO donestubs
FROM stubs A;
