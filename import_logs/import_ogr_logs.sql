-- $Id: import_ogr_logs.sql,v 1.2 2004/08/16 02:46:51 nerf Exp $
-- vi:expandtab sw=2 ts=2 nobackup

CREATE TEMP TABLE import_ogr (
	return_time	timestamp NOT NULL,
	ip_address	inet NOT NULL,
	email		charactervarying(64) NOT NULL,
	stub_marks	charactervarying(22) NOT NULL,
	nodecount	bigint NOT NULL,
	os_type		integer NOT NULL,
	cpu_type	integer NOT NULL,
	version		integer NOT NULL,
	status		smallint NOT NULL
);

COPY import_logs from :IMPORTFILE DELIMITER ',' ;

INSERT INTO master (return_time,ip_address,participant_id,stub_id,nodecount,platform,status,project_id)
SELECT i.return_time,i.ip_address,sp.participant_id,st.stub_id,i.nodecount,p.platform,i.status,st.project_id
FROM import_ogr i, stats_participant sp, ogr_stubs st, platform p
WHERE i.email = sp.email
  AND i.stub_marks = st.stub_marks
  AND (i.os_type = p.os_type
    AND i.cpu_type = p.pcu_type
    AND i.version = p.version)
;
