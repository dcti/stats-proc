-- $Id: daily2.sql,v 1.1 2003/01/01 01:10:51 joel Exp $ --

-- (addlog.sql)
DROP TABLE logdata:projnum;

CREATE TABLE logdata:projnum (
email VARCHAR(64),
stub_marks VARCHAR(22),
nodecount BIGINT,
os_type SMALLINT,
cpu_type SMALLINT,
version INT);

COPY logdata:projnum FROM :infile USING DELIMITERS ',';

CREATE INDEX log_email_idx:projnum ON logdata:projnum (email);
CREATE INDEX log_nodecount_idx:projnum ON logdata:projnum (nodecount);
CREATE INDEX log_stubmark_idx:projnum ON logdata:projnum (stub_marks);


--(movedata.sql)
INSERT INTO stubs:projnum
SELECT DISTINCT I.id, A.stub_id, L.nodecount, L.os_type,
        L.cpu_type, L.version
FROM logdata:projnum L, id_lookup I, all_stubs:projnum A
WHERE L.email = I.email AND
        L.stub_marks = A.stub_marks;


--(create_cheaters.sql)
CREATE TABLE cheaters:projnum (
id INT NOT NULL,
returned INT,
uniq_stubs INT);

INSERT INTO cheaters:projnum
        SELECT I.id, count(A.stub_id) AS returned,
                count(DISTINCT A.stub_id) AS uniq_stubs
        FROM logdata:projnum L, id_lookup I, all_stubs:projnum A
        WHERE L.email = I.email AND
                L.stub_marks = A.stub_id
        GROUP BY id;

CREATE new_cheaters:projnum AS
        SELECT * FROM cheaters:projnum
        GROUP BY id;

DELETE * FROM cheaters:projnum ;

INSERT INTO TABLE cheaters:projnum
        SELECT * FROM new_cheaters:projnum ;

DROP TABLE new_cheaters:projnum ;

--DROP TABLE logdata:projnum ;


--(query3.sql)
CREATE TABLE donestubs:projnum
(
        stub_id INT,
        nodecount BIGINT,
        participants INT
);

INSERT INTO donestubs:projnum
        SELECT stub_id, nodecount, COUNT(DISTINCT p.stats_id)
        FROM stubs:projnum B, id_lookup p
        WHERE p.id = B.id
        GROUP BY stub_id, nodecount;

--(diff_counts.sql)
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
