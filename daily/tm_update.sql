/*
 $Id: tm_update.sql,v 1.32.2.4 2003/09/08 23:27:54 decibel Exp $

TM_RANK

Parameters
    Project_ID

*/
\set ON_ERROR_STOP 1
set sort_mem=128000;

\echo !! Begin team update

\echo Build summary table of team work
SELECT stats_get_max_rank_participant() AS max_rank INTO TEMP max_rank;

-- Build a table of all team contributions per member for today. Don't include anyone who's blocked.
-- WARNING! TeamMemberWork must be unique by ID and TEAM_ID. See the note below for more info
SELECT ect.credit_id, ect.team_id, sum(ect.work_units) AS work_units, 'F'::boolean AS is_new
    INTO TEMP team_member_work
    FROM email_contrib_today ect
    WHERE ect.team_id >= 1
        AND NOT EXISTS (SELECT *
                            FROM stats_participant_blocked spb
                            WHERE spb.id = ect.credit_id
                )
        AND NOT EXISTS (SELECT *
                            FROM stats_team_blocked stb
                            WHERE stb.team_id = ect.team_id
                )
        AND ect.project_id = :ProjectID
    GROUP BY credit_id, team_id
;

\echo  Flag new members
UPDATE team_member_work
    SET is_new = 'T' 
    WHERE NOT EXISTS (SELECT 1
                            FROM team_members tm
                            WHERE tm.project_id = :ProjectID
                                AND tm.team_id = team_member_work.team_id
                                AND tm.id = team_member_work.credit_id
                        )
;


-- Handle new members

-- First, build a list of just the new members, including everyone that's
-- retired to them
\echo Building list of new members and retires
SELECT sp.id, tmw.credit_id, tmw.team_id
    INTO TEMP new_members
    FROM team_member_work tmw, stats_participant sp, project_statsrun ps
    WHERE is_new = 'T'
        AND ps.project_id = :ProjectID
        AND sp.retire_to = tmw.credit_id
        AND (sp.retire_date <= last_date OR sp.retire_date IS NULL)
;
INSERT INTO new_members(id, credit_id, team_id)
    SELECT tmw.credit_id, tmw.credit_id, tmw.team_id
        FROM team_member_work tmw
        WHERE is_new = 'T'
;
CREATE UNIQUE INDEX id_project ON new_members(id)
;

-- Now, figure out the first date each one effectively joined the team by looking at email_contrib
\echo Summarizing work being contributed to team by new members
SELECT nm.credit_id, nm.team_id, min(ec.date) AS first_date, sum(ec.work_units) AS work_units
    INTO TEMP new_member_work
    FROM new_members nm, email_contrib ec
    WHERE ec.id = nm.id
        AND ec.team_id = nm.team_id
        AND ec.project_id = :ProjectID
    GROUP BY nm.credit_id, nm.team_id
;


\echo  Build temporary table of work for today, summarized by team
SELECT team_id, sum(work_units) AS work_today, 'F'::boolean AS is_new
    INTO TEMP team_work
    FROM team_member_work
    GROUP BY team_id
;
UPDATE team_work
    SET is_new = 'T'
    WHERE NOT EXISTS (SELECT 1
                            FROM team_rank tr
                            WHERE tr.project_id = :ProjectID
                                AND tr.team_id = team_work.team_id
                        )
;


\echo :: Update team_members
\echo  Clear today info in team_members
BEGIN;
    SELECT stats_set_last_update(:ProjectID, 'm', NULL);
    UPDATE team_members
        SET work_today = 0,
            day_rank = 1000000,
            day_rank_previous = day_rank,
            overall_rank = 1000000,
            overall_rank_previous = overall_rank
        WHERE project_id = :ProjectID        /* all records */
    ;

    \echo  Populate today's work
    UPDATE team_members
        SET work_today = tmw.work_units,
            work_total = work_total + tmw.work_units,
            last_date = ps.last_date
        FROM team_member_work tmw, project_statsrun ps
        WHERE team_members.project_id = :ProjectID
            AND ps.project_id = :ProjectID
            AND team_members.project_id = ps.project_id
            AND tmw.credit_id = team_members.id
            AND tmw.team_id = team_members.team_id
            AND tmw.is_new = 'F'
    ;

    \echo  Insert records for members who have just joined a team
    INSERT INTO team_members (project_id, id, team_id, first_date, last_date, work_today, work_total,
                day_rank, day_rank_previous, overall_rank, overall_rank_previous)
        SELECT :ProjectID, nmw.credit_id, nmw.team_id, nmw.first_date, ps.last_date, tmw.work_units, nmw.work_units,
                1000000, 1000000, 1000000, 1000000
        FROM team_member_work tmw, new_member_work nmw, project_statsrun ps
        WHERE tmw.is_new = 'T'
            AND tmw.credit_id = nmw.credit_id
            AND tmw.team_id = nmw.team_id
            AND ps.project_id = :ProjectID
    ;

    /*
    ** TODO: Perform team member ranking within each team
    ** but only after we eliminate hidden teams
    */

    SELECT stats_set_last_update(:ProjectID, 'm', stats_get_last_update(:ProjectID, 's'));
COMMIT;


\echo :: Begin team_rank update
BEGIN;
    SELECT stats_set_last_update(:ProjectID, 't', NULL);

    \echo  Remove hidden teams from rank table
    DELETE FROM team_rank
        WHERE EXISTS (SELECT 1
                            FROM stats_team_blocked stb
                            WHERE stb.team_id = team_rank.team_id
                        )
            AND project_id = :ProjectID
    ;

    \echo  Remove or move "today"" info"
    UPDATE team_rank
        SET day_rank_previous = day_rank,
            overall_rank_previous = overall_rank,
            work_today = 0,
            members_today = 0
        WHERE project_id = :ProjectID
    ;

    \echo  Update work for existing teams
    UPDATE team_rank
        SET work_today = tw.work_today,
            work_total = work_total + tw.work_today,
            last_date = ps.last_date
        FROM team_work tw, project_statsrun ps
        WHERE team_rank.team_id = tw.team_id
            AND team_rank.project_id = :ProjectID
            AND ps.project_id = :ProjectID
            AND team_rank.project_id = ps.project_id
            AND tw.is_new = 'F'
    ;

    \echo  Insert new teams
    INSERT INTO team_rank (project_id, team_id, first_date, last_date, work_today, work_total,
            day_rank, day_rank_previous, overall_rank, overall_rank_previous,
            members_today, members_overall, members_current)
        SELECT :ProjectID, tw.team_id, ps.last_date, ps.last_date, tw.work_today, tw.work_today,
                max_rank, max_rank, max_rank, max_rank, 0, 0, 0
        FROM team_work tw, max_rank, project_statsrun ps
        WHERE tw.is_new = 'T'
            AND ps.project_id = :ProjectID
    ;
COMMIT;

/*
** Team_Members contains everyone who was or is on this team.
** Active members have WORK_TODAY > 0
** Total members = all listed in Team_Members
** Current members = people who are listed on this team today, active or not
*/
\echo ::  Setting number of Overall, Current, and Active members

CREATE TEMP TABLE current_members
(
    team_id         int,
    overall         int,
    active          int,
    curr            int
)
;

\echo Building temporary table
INSERT INTO current_members (team_id, overall, active, curr)
    SELECT tm.team_id, count(*), sum(sign(work_today)), sum(1-abs(sign(tj.team_id - tm.team_id)))
    FROM team_members tm, team_joins tj, project_statsrun ps
    WHERE tj.id = tm.id
        AND tj.join_date <= ps.last_date
        AND (tj.last_date IS NULL OR tj.last_date >= ps.last_date)
        AND tm.project_id = :ProjectID
        AND ps.project_id = :ProjectID
        AND ps.project_id = tm.project_id
    GROUP BY tm.team_id
;
CREATE UNIQUE INDEX iteam_id ON current_members(team_id)
;
\echo Updating team_rank
UPDATE team_rank
    SET members_today = active,
        members_overall = overall,
        members_current = curr
    FROM current_members cm
    WHERE team_rank.team_id = cm.team_id
        AND team_rank.project_id = :ProjectID
;
