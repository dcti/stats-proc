-- $Id: process_donestubs.sql,v 1.6 2003/02/03 05:48:56 nerf Exp $

DROP TABLE confirmed;

CREATE TABLE confirmed AS
SELECT DISTINCT A.stub_marks
FROM donestubs D, all_stubs A, stubs S, platform P
WHERE D.stub_id = A.stub_id AND
	D.stub_id = S.stub_id AND
	D.nodecount = S.nodecount AND
	S.platform_id = P.platform_id AND
	D.participants >= 2 AND
	P.version >= 8014;
