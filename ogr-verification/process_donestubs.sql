-- $Id: process_donestubs.sql,v 1.7 2003/02/16 19:18:42 nerf Exp $

DROP TABLE confirmed;

select now();
CREATE TABLE confirmed AS
SELECT DISTINCT S.stub_marks
FROM OGR_summary D, OGR_stubs S, OGR_results R, platform P
WHERE D.stub_id = S.stub_id AND
	D.stub_id = R.stub_id AND
	D.nodecount = R.nodecount AND
	R.platform_id = P.platform_id AND
	D.participants >= 2 AND
	P.version >= 8014;
select now();
