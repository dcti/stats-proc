-- $Id: process_donestubs.sql,v 1.4 2003/01/06 08:06:58 nerf Exp $

SELECT DISTINCT A.stub_marks
FROM donestubs D, all_stubs A, stubs S
WHERE D.stub_id = A.stub_id AND
	D.stub_id = S.stub_id AND
	D.nodecount = S.nodecount AND
	D.participants >= 2 AND
	S.version >= 8014;
