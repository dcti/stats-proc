-- $Id: query3.sql,v 1.2 2002/12/20 23:55:45 nerf Exp $ --

SELECT DISTINCT stub_id, nodecount, (SELECT count(DISTINCT p.stats_id)
FROM nodes B, id_lookup p
WHERE p.email = B.email AND B.nodecount = A.nodecount) AS participants
INTO donenodes
FROM nodes A;
