-- $Id: process_donestubs.sql,v 1.5 2003/01/22 01:24:34 nerf Exp $

DROP TABLE confirmed;

CREATE TABLE confirmed AS
SELECT DISTINCT A.stub_marks
FROM donestubs D, all_stubs A, stubs S
WHERE D.stub_id = A.stub_id AND
	D.stub_id = S.stub_id AND
	D.nodecount = S.nodecount AND
	D.participants >= 2 AND
	S.version >= 8014;
