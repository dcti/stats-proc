-- $Id: clearday.sql,v 1.5.2.5 2003/09/03 23:02:57 decibel Exp $
\set ON_ERROR_STOP 1
set sort_mem=128000;

\echo Dropping indexes
--drop index email_contrib_today.iid
--drop index email_contrib_today.iteam_id
--;

\echo Deleting data
DELETE FROM email_contrib_today WHERE project_id=:ProjectID;
--VACUUM email_contrib_today;
DELETE FROM platform_contrib_today WHERE project_id=:ProjectID;
--VACUUM platform_contrib_today;

\echo Updating Project_statsrun
UPDATE project_statsrun
    SET logs_for_day = 0,
        work_for_day = 0
    WHERE project_id=:ProjectID
;
