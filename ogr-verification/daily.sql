-- $Id --

--Create the logdata table and fill it with filtered(filter.pl) data. (addlog.sql)
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


--Create the id_lookup table and fill it with 1 entry(email) per participant. (id_lookup1.sql)
DROP TABLE id_lookup;
DROP SEQUENCE id_lookup_stats_id_seq;
CREATE SEQUENCE stats_id START 1;

CREATE TABLE id_lookup (
stats_id BIGSERIAL,
email VARCHAR(50),
PRIMARY KEY (stats_id));

INSERT INTO id_lookup SELECT nextval('stats_id'), email FROM nodes GROUP BY email;

CREATE INDEX id_lookup_email_idx on id_lookup (email);


--Insert only valid data into nodes. (movedata.sql)
INSERT INTO nodes
SELECT DISTINCT email , stub_id , nodecount, os_type, cpu_type, version FROM logdata;

--CREATE INDEX nodes_email ON nodes(email);
--CREATE INDEX nodes_stub_id ON nodes(stub_id);
--CREATE INDEX nodes_nodecount ON nodes(nodecount);
--CREATE INDEX nodes_os_type ON nodes(os_type);
--CREATE INDEX nodes_cpu_type ON nodes(cpu_type);
--CREATE INDEX nodes_version ON nodes(version);

--Create donenodes table. (donenodes.sql)
DROP TABLE donenodes;
CREATE TABLE donenodes (
 stub_id    TEXT,
 nodecount  BIGINT,
participants INTEGER);



--Run (query2.sql) the big query.
INSERT INTO donenodes
SELECT DISTINCT stub_id, nodecount, (select count(distinct p.stats_id)
FROM nodes B, id_lookup p
WHERE p.email = B.email AND B.nodecount = A.nodecount) AS participants
from nodes A;

