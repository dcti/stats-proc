-- $Id: process_donestubs.sql,v 1.2 2002/12/30 06:43:38 nerf Exp $

select A.stub_marks
from donestubs D, all_stubs A, stubs S
where D.stub_id = A.stub_id AND
	D.stub_id = S.stub_id AND
	D.nodecount = S.nodecount AND
	D.participants >= 2 AND
	S.version > 8014;

