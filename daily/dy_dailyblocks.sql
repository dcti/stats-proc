/*
# $Id: dy_dailyblocks.sql,v 1.12.2.3 2003/04/29 20:36:14 decibel Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project
*/
\set ON_ERROR_STOP 1

SELECT *
    INTO TEMP Tsummary
    FROM daily_summary
    WHERE 1=0
;

\echo project_statsrun, _new
UPDATE Tsummary
    SET date = last_date
            , project_id = :ProjectID
            , work_units = work_for_day
            , participants_new = (SELECT count(*) FROM email_rank WHERE project_id = :ProjectID
                                            AND first_date = ps.last_date)
            , teams_new = (SELECT count(*) FROM team_rank WHERE project_id = :ProjectID
                                            AND first_date = ps.last_date)
    FROM project_statsrun ps
    WHERE ps.project_id = :ProjectID
;

\echo email_contrib_today
UPDATE Tsummary
    SET participants = count(distinct credit_id)
            , teams = count(distinct team_id)
    FROM email_contrib_today
    WHERE project_id = :ProjectID
;

\echo email_rank, overall_rank = 1
UPDATE Tsummary
    SET top_oparticipant = min(id)
        , top_opwork = min(work_total)
    FROM email_rank
    WHERE project_id = :ProjectID
        AND overall_rank = 1
;

\echo email_rank, day_rank = 1
UPDATE Tsummary
    SET top_yparticipant = min(id)
        , top_ypwork = min(work_total)
    FROM email_rank
    WHERE project_id = :ProjectID
        AND day_rank = 1
;

\echo team_rank, overall_rank = 1
UPDATE Tsummary
    SET top_oteam = min(team_id)
        , top_otwork = min(work_total)
    FROM team_rank
    WHERE project_id = :ProjectID
        AND overall_rank = 1
;

\echo team_rank, overall_rank = 1
UPDATE Tsummary
    SET top_yteam = min(team_id)
        , top_ytwork) = min(work_total)
    FROM team_rank
    WHERE project_id = :ProjectID
        AND day_rank = 1
;

INSERT INTO daily_summary
    SELECT *
        FROM Tsummary
;
