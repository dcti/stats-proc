-- $Id: query3.sql,v 1.6 2002/12/23 01:35:30 joel Exp $ --

SELECT DISTINCT stub_id, nodecount, (SELECT count(DISTINCT p.id)
FROM stubs B, id_lookup p
WHERE p.id = B.id AND B.nodecount = A.nodecount AND B.stub_id = A.stub_id) AS participants
INTO donestubs
FROM stubs A;
