-- $Id: two_pass.sql,v 1.2 2003/01/07 00:56:49 nerf Exp $

-- to be put into all_stub.pass1_id, all_stubs.nodecount
SELECT S.id as pass1_id, S.nodecount as nodecount
FROM stubs S, all_stubs A
WHERE S.version >= 8014 AND
        S.stub_id = A.stub_id
FOR UPDATE OF A;

-- to update all_stubs.pass2_id
SELECT S.id as pass2_id
FROM stubs S, all_stubs A, id_lookup I1, id_lookup I2
WHERE S.id = I1.id AND
        S.stub_id = A.stub_id AND
        S.nodecount = A.nodecount AND
        A.pass1_id = I2.id AND
        I1.stats_id != I2.stats_id
FOR UPDATE OF A;
