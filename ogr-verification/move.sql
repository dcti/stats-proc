-- $Id: move.sql,v 1.4 2002/12/22 22:14:51 nerf Exp $ --

INSERT INTO stubs
SELECT DISTINCT id, stub_id, nodecount, os_type, cpu_type, version
FROM logdata;
