-- $Id: clearday.sql,v 1.5.2.1 2003/04/27 20:40:38 decibel Exp $

\echo Dropping indexes
--drop index email_contrib_today.iid
--drop index email_contrib_today.iteam_id
--;

\echo Deleting data
DELETE FROM email_contrib_today WHERE project_id=:ProjectID;
DELETE FROM platform_contrib_today WHERE project_id=:ProjectID;

\echo Updating Project_statsrun
UPDATE project_statsrun
    SET logs_for_day = 0,
        work_for_day = 0
    WHERE project_id=:ProjectID
;
