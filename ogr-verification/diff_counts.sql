-- $Id: diff_counts.sql,v 1.4 2003/01/01 17:01:05 joel Exp $

-- find stubs that have different nodecounts

CREATE TEMP TABLE tmp_diff_nodecounts:projnum AS
	SELECT stub_id, count(distinct nodecount) AS counts
	FROM stubs:projnum
	GROUP by stub_id
	HAVING count(distinct nodecount) >1;

CREATE table diff_counts:projnum AS
	SELECT I.email, A.stub_marks, S.nodecount, S.os_type,
		S.cpu_type, S.version
	FROM stubs:projnum S, id_lookup I, all_stubs:projnum A, tmp_diff_nodecounts:projnum C
	WHERE S.id = I.id AND
		S.stub_id = A.stub_id AND
		S.stub_id = C.stub_id
	ORDER BY A.stub_marks;
