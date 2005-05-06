-- $Id: integrate.sql,v 1.1 2005/05/06 21:34:52 nerf Exp $

INSERT INTO email(email)
	SELECT email
	FROM (
		SELECT email FROM import_r72
		UNION
		SELECT email FROM import_ogr
	) n
	WHERE NOT EXISTS (
		SELECT 1
		FROM email e
		WHERE n.email = e.email
	);

INSERT INTO platform(os, cpu, version)
	SELECT os_type, cpu_type, version
	FROM (
		SELECT os_type, cpu_type, version FROM import_r72
		UNION
		SELECT os_type, cpu_type, version FROM import_ogr
	) n
	WHERE NOT EXISTS (
		SELECT 1
		FROM platform p
		WHERE n.os_type = p.os
			AND n.cpu_type = p.cpu
			AND n.version = p.version
	);

INSERT INTO ogr_stubs(stub_marks)
	SELECT distinct stub_marks
	FROM import_ogr n
	WHERE NOT EXISTS (
		SELECT 1
		FROM ogr_stubs s
		WHERE n.stub_marks = s.stub_marks
	);

INSERT INTO log_8 (return_time,ip_address,email_id,platform_id,iter,cmc_count,cmc_ok,core,key_block,cmc_last)
	SELECT i.return_time,i.ip_address,e.email_id,p.platform_id,i.iter,i.cmc_count,i.cmc_ok,i.core,i.key_block,i.cmc_last
	FROM import_r72 i
	, email e
	, platform p
	WHERE i.os_type = p.os
	AND i.cpu_type = p.cpu
	AND i.version = p.version
	AND i.email = e.email
;
