-- $Id: diff_counts.sql,v 1.7 2003/05/13 14:05:42 nerf Exp $
\set ON_ERROR_STOP 1

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
