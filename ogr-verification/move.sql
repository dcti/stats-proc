-- $Id: move.sql,v 1.3 2002/12/21 21:13:22 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT email , stub_id , nodecount, os_type, cpu_type, version
FROM logdata;
