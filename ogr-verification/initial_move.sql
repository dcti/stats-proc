-- $Id: initial_move.sql,v 1.1 2003/02/16 19:51:47 nerf Exp $

SELECT now();

create index logdata_platform on logdata (os_type,cpu_type,"version");

INSERT INTO platform (os_type,cpu_type,"version")
SELECT DISTINCT L.os_type, L.cpu_type, L.version 
FROM logdata L;
SELECT now();

create index platform_all on platform (os_type, cpu_type, "version");
SELECT now();


-- aggregate all the data
INSERT INTO OGR_results(id, stub_id, nodecount, platform_id, return_count)
SELECT I.id, A.stub_id, L.nodecount, P.platform_id, count(*)
	FROM logdata L, OGR_idlookup I, OGR_stubs A, platform P
	WHERE lower(L.email) = lower(I.email)
	AND L.stub_marks = A.stub_marks
	AND L.os_type = P.os_type
	AND L.cpu_type = P.cpu_type
	AND L.version = P.version
	GROUP BY I.id, A.stub_id, L.nodecount, P.platform_id
;
SELECT now();

vacuum analyze verbose;
SELECT now();
