-- $Id: diff_counts.sql,v 1.6 2003/02/16 19:18:42 nerf Exp $

-- find stubs that have different nodecounts

CREATE TEMP TABLE tmp_diff_nodecounts AS
	SELECT stub_id, count(distinct nodecount) AS counts
	FROM OGR_results
	GROUP by stub_id
	HAVING count(distinct nodecount) >1;

CREATE table diff_counts AS
	SELECT I.email, A.stub_marks, S.nodecount, S.os_type,
		S.cpu_type, S.version
	FROM OGR_results S, OGR_idlookup I, OGR_stubs A, tmp_diff_nodecounts C
	WHERE S.id = I.id AND
		S.stub_id = A.stub_id AND
		S.stub_id = C.stub_id
	ORDER BY A.stub_marks;
