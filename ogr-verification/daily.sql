-- $Id: daily.sql,v 1.6 2003/02/16 19:18:42 nerf Exp $ --

--Create the logdata table and fill it with filtered(filter.pl) data. (addlog.sql)
-- This file needs to be recreated from scratch

DROP TABLE logdata;

CREATE TABLE logdata (
email TEXT,
stub_id TEXT,
nodecount BIGINT,
os_type INT,
cpu_type INT,
version BIGINT);


COPY logdata FROM '/home/postgres/ogr25.filtered' USING DELIMITERS ',';

CREATE INDEX email_idx on logdata (email);
CREATE INDEX nodecount_idx on logdata (nodecount);
CREATE INDEX stubid_idx on logdata (stub_id);


--Create the OGR_idlookup table and fill it with 1 entry(email) per participant. (id_lookup1.sql)
DROP TABLE OGR_idlookup;
DROP SEQUENCE OGR_idlookup_stats_id_seq;
CREATE SEQUENCE stats_id START 1;

CREATE TABLE OGR_idlookup (
stats_id BIGSERIAL,
email VARCHAR(50),
PRIMARY KEY (stats_id));

INSERT INTO OGR_idlookup
	SELECT nextval('stats_id'), email
	FROM OGR_results
	GROUP BY email;

CREATE INDEX OGR_idlookup_email_idx on OGR_idlookup (email);


--Insert only valid data into OGR_results. (movedata.sql)
INSERT INTO OGR_results
SELECT DISTINCT email , stub_id , nodecount, os_type, cpu_type, version
	FROM logdata;

--CREATE INDEX stubs_email ON stubs(email);
--CREATE INDEX stubs_stub_id ON stubs(stub_id);
--CREATE INDEX stubs_nodecount ON stubs(nodecount);
--CREATE INDEX stubs_os_type ON stubs(os_type);
--CREATE INDEX stubs_cpu_type ON stubs(cpu_type);
--CREATE INDEX stubs_version ON stubs(version);

--Create OGR_summary table. (donestubs.sql)
DROP TABLE OGR_summary;
CREATE TABLE OGR_summary (
 stub_id    TEXT,
 nodecount  BIGINT,
participants INTEGER);



--Run (query2.sql) the big query.
INSERT INTO OGR_summary
SELECT DISTINCT stub_id, nodecount, (select count(distinct p.stats_id)
	FROM OGR_results R, OGR_idlookup p
	WHERE p.email = R.email
	AND R.nodecount = A.nodecount
	and R.stub_id = A.stub_id) AS participants
FROM OGR_results A;
