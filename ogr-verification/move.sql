-- $Id: move.sql,v 1.6 2002/12/23 02:39:51 joel Exp $ --

INSERT INTO stubs
SELECT DISTINCT id, stub_id, nodecount, os_type, cpu_type, version
FROM logdata;
