-- $Id: two_pass.sql,v 1.3 2003/02/16 19:18:42 nerf Exp $

-- to be put into all_stub.pass1_id, OGR_stubs.nodecount
SELECT S.id as pass1_id, S.nodecount as nodecount
FROM OGR_results S, OGR_stubs A
WHERE S.version >= 8014 AND
        S.stub_id = A.stub_id
FOR UPDATE OF A;

-- to update OGR_stubs.pass2_id
SELECT S.id as pass2_id
FROM OGR_results S, OGR_stubs A, OGR_idlookup I1, OGR_idlookup I2
WHERE S.id = I1.id AND
        S.stub_id = A.stub_id AND
        S.nodecount = A.nodecount AND
        A.pass1_id = I2.id AND
        I1.stats_id != I2.stats_id
FOR UPDATE OF A;

