-- $Id: integrate.sql,v 1.2 2007/06/17 04:54:05 decibel Exp $

CREATE OR REPLACE FUNCTION intergrate(
        p_log_type log_type.log_type%TYPE
        , p_log_day log_history.log_day%TYPE
        , p_log_hour log_history.log_hour%TYPE
        , p_import_start timestamp
        , OUT new_emails int
        , OUT new_platforms int
        , OUT inserted_rows int
        , OUT deleted_rows int
    ) RETURNS record LANGUAGE plpgsql VOLATILE AS $integrate$
DECLARE
    v_log_type_id log_type.log_type_id%TYPE;
BEGIN
    -- Find out what the log_type_id is for log_type
    SELECT INTO v_log_type_id
            log_type_id
        FROM log_type
        WHERE log_type = p_log_type
    ;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid log_type %', p_log_type;
    END IF;

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
    GET DIAGNOSTICS new_emails = ROW_COUNT;

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
    GET DIAGNOSTICS new_platforms = ROW_COUNT;

    INSERT INTO log (
            project_id, return_time, ip_address, email_id, platform_id, workunit_tid
                , core, rc5_cmc_count, rc5_cmc_ok, rc5_iter, rc5_cmc_last
                , ogr_status, ogr_nodecount, log_type_id, bad_ip_address
        )
        SELECT i.project_id, i.return_time, i.ip_address, e.email_id, p.platform_id, i.workunit_tid
                , i.core, i.rc5_cmc_count, i.rc5_cmc_ok, i.rc5_iter, i.rc5_cmc_last
                , i.ogr_status, i.ogr_nodecount, i.log_type_id, i.bad_ip_address
        FROM import i
            JOIN platform p ON ( i.os_type = p.os AND i.cpu_type = p.cpu AND i.version = p.version )
            JOIN email e ON ( i.email = e.email )
    ;
    GET DIAGNOSTICS inserted_rows = ROW_COUNT;

    -- We should really replace this with a temporary table
    DELETE FROM import;
    GET DIAGNOSTICS deleted_rows = ROW_COUNT;

    INSERT INTO log_history( logday, loghour, log_type_id, lines, start_time, end_time )
        VALUES( log_day, log_hour, v_log_type_id, inserted_rows, import_start, timeofday()::timestamptz AT TIME ZONE 'UTC' )
    ;
END;
$integrate$;
