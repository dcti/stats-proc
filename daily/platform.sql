-- $Id: platform.sql,v 1.2.2.4 2003/07/14 00:51:01 decibel Exp $
\set ON_ERROR_STOP 1

BEGIN;
    DELETE FROM platform_summary WHERE project_id = :ProjectID ;

    INSERT INTO platform_summary (project_id, cpu, os, ver, first_date, last_date, work_today, work_total)
        SELECT project_id, cpu, os, ver, min(date), max(date), 0, sum(work_units)
        FROM platform_contrib
        WHERE project_id = :ProjectID
        GROUP BY project_id, cpu, os, ver
    ;

    UPDATE platform_summary
        SET work_today = work_units
        FROM platform_contrib pc
        WHERE platform_summary.project_id = pc.project_id
            AND platform_summary.cpu = pc.cpu
            AND platform_summary.os = pc.os
            AND platform_summary.ver = pc.ver
            AND platform_summary.project_id = :ProjectID
            AND pc.project_id = :ProjectID
            AND pc.date = (SELECT max(date) FROM platform_contrib WHERE project_id = :ProjectID)
    ;
COMMIT;
--VACUUM platform_summary;
