-- $Id: move.sql,v 1.2 2002/12/20 23:55:45 nerf Exp $ --

INSERT INTO nodes
SELECT DISTINCT email , stub_id , nodecount, os_type, cpu_type, version
FROM logdata;
