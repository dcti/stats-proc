-- $Id: two_pass.sql,v 1.1 2003/01/04 21:46:10 nerf Exp $

-- to be put into all_stub.pass1_id, all_stubs.nodecount
SELECT id, min(nodecount)
FROM stubs S, all_stubs A
WHERE S.version >= 8014 AND
        S.stub_id = A.stub_id;

-- to update all_stubs.pass2_id
SELECT id
FROM stubs S, all_stubs A, id_lookup I1, id_lookup I2
WHERE S.id = I1.id AND
        S.stub_id = A.stub_id AND
        S.nodecount = A.nodecount AND
        A.pass1_id = I2.id AND
        I1.stats_id != I2.stats_id;

