-- $Id: import_ogr_logs.sql,v 1.3 2005/02/16 21:03:22 decibel Exp $

TRUNCATE TABLE import;

COPY import_logs(return_time, ip_address, email, stub_marks, nodecount, os_type, cpu_type, version, status)
    FROM :IMPORTFILE DELIMITER ','
;

/*
INSERT INTO master (return_time,ip_address,participant_id,ogr_stub_id,nodecount,platform,status,project_id)
SELECT i.return_time,i.ip_address,sp.participant_id,st.ogr_stub_id,i.nodecount,p.platform,i.status,st.project_id
FROM import_ogr i, stats_participant sp, ogr_stubs st, platform p
WHERE i.email = sp.email
  AND i.stub_marks = st.stub_marks
  AND (i.os_type = p.os_type
    AND i.cpu_type = p.pcu_type
    AND i.version = p.version)
;
*/
-- vi:expandtab sw=4 ts=4 nobackup
