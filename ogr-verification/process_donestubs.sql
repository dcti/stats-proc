-- $Id: process_donestubs.sql,v 1.8 2003/05/13 14:05:42 nerf Exp $
\set ON_ERROR_STOP 1

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
