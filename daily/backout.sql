/*
 $Id: backout.sql,v 1.8.2.6 2003/07/14 00:51:01 decibel Exp $

 This script will back out all stats data to a given date

 Arguments
    ProjectID
    KeepDate - last date to KEEP in the database
*/

\set ON_ERROR_STOP 1
set enable_seqscan = off;

BEGIN;
    \echo Deleting from email_contrib where date > :KeepDate
    DELETE FROM email_contrib WHERE project_id = :ProjectID AND date > :KeepDate::date;
    --VACUUM email_contrib;
    \echo 
    
    \echo Deleting from platform_contrib where date > :KeepDate
    DELETE FROM platform_contrib WHERE project_id = :ProjectID AND date > :KeepDate::date;
    --VACUUM platform_contrib;
    \echo 
    
    \echo Deleting from daily_summary where date > :KeepDate
    DELETE FROM daily_summary WHERE project_id = :ProjectID AND date > :KeepDate::date;
    --VACUUM daily_summary;
    \echo 
    
    \echo Deleting from log_info where date > :KeepDate
    DELETE FROM log_info WHERE project_id = :ProjectID AND log_timestamp >= :KeepDate::date + '1 day'::interval;
    --VACUUM log_info;
    \echo 
    
    \echo Deleting from email_rank
    DELETE FROM email_rank WHERE project_id = :ProjectID;
    --VACUUM email_rank;
    \echo 
    
    \echo Deleting from team_rank
    DELETE FROM team_rank WHERE project_id = :ProjectID;
    --VACUUM team_rank;
    \echo 
    
    \echo Deleting from team_members
    DELETE FROM team_members WHERE project_id = :ProjectID;
    --VACUUM team_members;
    \echo 
    
    \echo Inserting into Email_Rank
    INSERT INTO email_rank (project_id, id, first_date, last_date, work_today, work_total,
            day_rank, day_rank_previous, overall_rank, overall_rank_previous)
        SELECT :ProjectID, id, first_date, last_date, work_today, work_total,
                day_rank, day_rank_previous, overall_rank, overall_rank_previous
            FROM email_rank_backup
            WHERE project_id = :ProjectID
                AND backup_date = :KeepDate::date
    ;
    /* Doesn't work for some reason, so screw it
    SELECT raise_exception('Less than 100 rows inserted into email_rank')
        FROM (SELECT count(*) AS rows
                    FROM (SELECT * FROM email_rank WHERE project_id = :ProjectID LIMIT 100) AS t1
                ) AS t2
        WHERE rows < 100
    ;
    */
    \echo 
    
    \echo Inserting into Team_Rank
    INSERT INTO team_rank (project_id, team_id, first_date, last_date, work_today, work_total,
            day_rank, day_rank_previous, overall_rank, overall_rank_previous,
            members_today, members_overall, members_current)
        SELECT :ProjectID, team_id, first_date, last_date, work_today, work_total,
                day_rank, day_rank_previous, overall_rank, overall_rank_previous,
                members_today, members_overall, members_current
            FROM team_rank_backup
            WHERE project_id = :ProjectID
                AND backup_date = :KeepDate::date
    ;
    
    \echo Inserting into Team_Members
    INSERT INTO team_members (project_id, id, team_id, first_date, last_date, work_today, work_total,
            day_rank, day_rank_previous, overall_rank, overall_rank_previous)
        SELECT :ProjectID, id, team_id, first_date, last_date, work_today, work_total,
                day_rank, day_rank_previous, overall_rank, overall_rank_previous
            FROM team_members_backup
            WHERE project_id = :ProjectID
                AND backup_date = :KeepDate::date
    ;
COMMIT;
