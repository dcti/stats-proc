/*
# $Id: backup.sql,v 1.14.2.2 2003/04/27 20:53:07 decibel Exp $
#
# Makes backup copies of Email_Rank, Team_Rank, and Team_Members
# Arguments:
#    ProjectID
*/
\set ON_ERROR_STOP 1

SELECT last_date, last_date - interval '4 days' AS keep_date
    INTO TEMP Tdates
    FROM project_statsrun
    WHERE project_id = :ProjectID
;

\echo Deleting old data and any previous data for today.
DELETE FROM email_rank_backup
    WHERE project_id = :ProjectID
        AND (backup_date = (SELECT last_date FROM Tdates)
            OR backup_date < (SELECT keep_date FROM Tdates) )
;
DELETE FROM team_rank_backup
    WHERE project_id = :ProjectID
        AND (backup_date = (SELECT last_date FROM Tdates)
            OR backup_date < (SELECT keep_date FROM Tdates) )
;
DELETE FROM team_members_backup
    WHERE project_id = :ProjectID
        AND (backup_date = (SELECT last_date FROM Tdates)
            OR backup_date < (SELECT keep_date FROM Tdates) )
;

\echo Backing up Email_Rank
INSERT INTO email_rank_backup (backup_date, project_id, id, first_date, last_date,
        work_today, work_total, day_rank, day_rank_previous,
        overall_rank, overall_rank_previous)
    SELECT td.last_date, :ProjectID, id, first_date, er.last_date, work_today, work_total,
        day_rank, day_rank_previous, overall_rank, overall_rank_previous
        FROM email_rank er, Tdates td
        WHERE project_id = :ProjectID
;

\echo Backing up Team_Rank
INSERT INTO team_rank_backup (backup_date, project_id, team_id, first_date, last_date,
        work_today, work_total, day_rank, day_rank_previous,
        overall_rank, overall_rank_previous, members_today, members_overall, members_current)
    SELECT td.last_date, :ProjectID, team_id, first_date, tr.last_date, work_today, work_total,
        day_rank, day_rank_previous, overall_rank, overall_rank_previous,
        members_today, members_overall, members_current
    FROM team_rank tr, Tdates td
    WHERE project_id = :ProjectID
;

\echo Backing up Team_Members
INSERT INTO team_members_backup (backup_date, project_id, id, team_id,  first_date, last_date,
        work_today, work_total, day_rank, day_rank_previous,
        overall_rank, overall_rank_previous)
    SELECT td.last_date, :ProjectID, id, team_id, first_date, tm.last_date, work_today, work_total,
        day_rank, day_rank_previous, overall_rank, overall_rank_previous
    FROM team_members tm, Tdates td
    WHERE project_id = :ProjectID
;
