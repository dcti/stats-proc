-- $Id: move.sql,v 1.5 2002/12/22 22:41:05 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT stats_id, stub_id, nodecount, os_type, cpu_type, version
FROM logdata;
