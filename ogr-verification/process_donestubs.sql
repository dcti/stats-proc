-- $Id: process_donestubs.sql,v 1.3 2002/12/30 08:21:11 nerf Exp $

SELECT DISTINCT A.stub_marks
FROM donestubs D, all_stubs A, stubs S
WHERE D.stub_id = A.stub_id AND
	D.stub_id = S.stub_id AND
	D.nodecount = S.nodecount AND
	D.participants >= 2 AND
	S.version > 8014;

