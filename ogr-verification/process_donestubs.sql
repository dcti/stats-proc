-- $Id: process_donestubs.sql,v 1.1 2002/12/29 00:30:00 nerf Exp $

select A.*, D.*
from donestubs D, all_stubs A, stubs S
where D.stub_id = A.stub_id AND
	D.stub_id = S.stub_id AND
	D.nodecount = S.nodecount AND
	D.participant >= 2 AND
	S.version > 8014;

