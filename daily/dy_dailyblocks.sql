/*
# $Id: dy_dailyblocks.sql,v 1.12.2.2 2003/04/27 20:53:07 decibel Exp $
#
# Inserts the daily totals
#
# Arguments:
#       Project
*/
\set ON_ERROR_STOP 1

INSERT INTO daily_summary (date, project_id, work_units
        , participants
        , participants_new
        , teams
        , teams_new
        , top_oparticipant
        , top_opwork
        , top_yparticipant
        , top_ypwork
        , top_oteam
        , top_otwork
        , top_yteam
        , top_ytwork)
    SELECT ps.last_date, :ProjectID, ps.work_for_day
            , (SELECT count(distinct credit_id) FROM email_contrib_today WHERE project_id = :ProjectID)
            , (SELECT count(*) FROM email_rank WHERE project_id = :ProjectID AND first_date = ps.last_date)
            , (SELECT count(distinct team_id) FROM email_contrib_today WHERE project_id = :ProjectID)
            , (SELECT count(*) FROM team_rank WHERE project_id = :ProjectID AND first_date = ps.last_date)
            , (SELECT min(id) FROM email_rank WHERE project_id = :ProjectID AND overall_rank = 1)
            , (SELECT min(work_total) FROM email_rank WHERE project_id = :ProjectID AND overall_rank = 1)
            , (SELECT min(id) FROM email_rank WHERE project_id = :ProjectID AND day_rank = 1)
            , (SELECT min(work_total) FROM email_rank WHERE project_id = :ProjectID AND day_rank = 1)
            , (SELECT min(team_id) FROM team_rank WHERE project_id = :ProjectID AND overall_rank = 1)
            , (SELECT min(work_total) FROM team_rank WHERE project_id = :ProjectID AND overall_rank = 1)
            , (SELECT min(team_id )FROM team_rank WHERE project_id = :ProjectID AND day_rank = 1)
            , (SELECT min(work_total) FROM team_rank WHERE project_id = :ProjectID AND day_rank = 1)
        FROM project_statsrun ps
        WHERE ps.project_id = :ProjectID
;

