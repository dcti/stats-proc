/*
# $Id: newjoin.sql,v 1.14 2003/09/11 01:41:02 decibel Exp $
#
# Assigns old work to current team
#
# Arguments:
#       ProjectID
*/
\set ON_ERROR_STOP 1
set sort_mem=128000;

\echo :: Assigning old work to current team

-- This query will only get joins to teams (not to team 0) that have
-- taken place on the day that we're running stats for.
\echo Building temporary tables
SELECT id, team_id
    INTO TEMP newjoins
    FROM Team_Joins tj, Project_statsrun ps
    WHERE ps.project_id = :ProjectID
        AND tj.join_date = ps.last_date
        AND (tj.last_date IS NULL OR tj.last_date >= ps.last_date)
;

-- Get the retire_to info
SELECT sp.id, sp.retire_to, sp.retire_to AS effective_id, nj.team_id
    INTO TEMP nj_ids
    FROM STATS_Participant sp, newjoins nj
    WHERE sp.retire_to = nj.id
        AND sp.retire_to > 0
        AND nj.id > 0
;

-- Also insert the un-retired records
INSERT INTO nj_ids (id, retire_to, effective_id, team_id)
    SELECT sp.id, 0, sp.id, nj.team_id
    FROM stats_participant sp, newjoins nj
    WHERE sp.id = nj.id
;

-- We'll also need to know what team0 work has been done
SELECT ni.effective_id, min(ni.team_id) AS team_id, sum(work_units) AS work, min(date) AS first, max(date) AS last
    INTO TEMP nj_work
    FROM email_contrib ec, nj_ids ni
    WHERE ec.project_id = :ProjectID
        AND ec.team_id = 0
        AND ec.id = ni.id
    GROUP BY ni.effective_id
;

-- Update any team0 records
BEGIN;
-- First, update email contrib
    \echo Updating email_contrib
    UPDATE email_contrib
        SET team_id = ni.team_id
        FROM nj_ids ni
        WHERE email_contrib.project_id = :ProjectID
            AND email_contrib.team_id = 0
            AND email_contrib.id = ni.id
    ;

-- Now, update team members. There are two cases we have to handle:
-- 1) Brand new join, so the person isn't in team_members at all
-- 2) Retire or join or whatever, so we have to update work_total, first_date, and last_date
--
-- Because we decide which we're doing based on existance of a record in team_members, we have to do #2 before #1


    \echo Updating team_members
    UPDATE team_members
        SET work_total = work_total + nw.work,
            first_date = min(first_date, nw.first),
            last_date = max(last_date, nw.last)
        FROM nj_work nw
        WHERE team_members.id = nw.effective_id
            AND project_id = :ProjectID
            AND team_members.team_id = nw.team_id
    ;


    INSERT INTO team_members (project_id, id, team_id, first_date, last_date, work_total)
        SELECT :ProjectID, effective_id, team_id, first, last, work
        FROM nj_work nw
        WHERE NOT EXISTS (SELECT 1
                                FROM team_members
                                WHERE project_id = :ProjectID
                                    AND id = nw.effective_id
                                    AND team_id = nw.team_id
                            )
    ;

-- Update team_rank
-- For teams that alread have a record, we need to update first and last date, and increment the member counts

    \echo Updating team_rank
    UPDATE team_rank
        SET work_total = work_total + nw.work
            , first_date = min(first_date, nw.first)
            , last_date = max(last_date, nw.last)
            , members_overall = members_overall + members
            , members_current = members_current + members
        FROM (SELECT team_id, sum(work) AS work, min(first) AS first, max(last) AS last, count(*) AS members
                    FROM nj_work
                    GROUP BY team_id
                ) nw
        WHERE team_rank.project_id = :ProjectID
            AND team_rank.team_id = nw.team_id
    ;

-- For teams that don't already have a record, add one

    INSERT INTO team_rank (project_id, team_id, first_date, last_date, work_total
                            , members_today, members_overall, members_current
                            , day_rank
                            , day_rank_previous
                            , overall_rank
                            , overall_rank_previous)
        SELECT :ProjectID, team_id, min(first), max(last), sum(work)
                , count(*), count(*), count(*)
                , (SELECT count(*) FROM team_rank WHERE work_today > 0)
                , (SELECT count(*) FROM team_rank WHERE work_today > 0)
                , (SELECT count(*) FROM team_rank)
                , (SELECT count(*) FROM team_rank)
            FROM nj_work nw
            WHERE NOT EXISTS (SELECT 1
                                    FROM team_rank tr
                                    WHERE tr.project_id = :ProjectID
                                        AND tr.team_id = nw.team_id
                                )
            GROUP BY team_id
    ;
commit;
