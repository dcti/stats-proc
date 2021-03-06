/*
#
# $Id: em_rank.sql,v 1.26 2005/05/11 18:13:27 decibel Exp $
#
# Does the participant ranking
#
# Arguments:
#       Project_id
*/
\set ON_ERROR_STOP 1

\echo !! Begin e-mail ranking
--\echo  Drop indexes on email_rank
--drop index email_rank.iDAY_RANK
--drop index email_rank.iOVERALL_RANK
--;

\echo  Create rank table for overall
CREATE TEMP SEQUENCE rnk_assign_overall CACHE 2000;
CREATE TEMP TABLE Trank_work_overall AS
    SELECT nextval('rnk_assign_overall') AS raw_rank, work_units
                FROM (SELECT work_total AS work_units
                            FROM email_rank
                            WHERE project_id = :ProjectID
                            ORDER BY work_total DESC
                        ) AS raw_work
;
ANALYZE Trank_work_overall;
SELECT work_units, min(raw_rank) AS rank INTO TEMP rank_tie_overall
    FROM Trank_work_overall
    GROUP BY work_units
;
DROP TABLE Trank_work_overall;

\echo    Index on work_units
CREATE UNIQUE INDEX work_units_overall ON rank_tie_overall(work_units)
;

\echo  Create rank table for today
CREATE TEMP SEQUENCE rnk_assign_today CACHE 2000;
CREATE TEMP TABLE Trank_work_today AS
    SELECT nextval('rnk_assign_today') AS raw_rank, work_units
                FROM (SELECT work_today AS work_units
                            FROM email_rank
                            WHERE project_id = :ProjectID
                            ORDER BY work_today DESC
                        ) AS raw_work
;
ANALYZE Trank_work_today;
SELECT work_units, min(raw_rank) AS rank INTO TEMP rank_tie_today
    FROM Trank_work_today
    GROUP BY work_units
;
DROP TABLE Trank_work_today;

\echo    Index on work_units
CREATE UNIQUE INDEX work_units_today ON rank_tie_today(work_units)
;
ANALYZE rank_tie_today;

\echo  Update email_rank with new rankings
BEGIN;
    UPDATE email_rank
        SET overall_rank = o.rank, day_rank = d.rank
        FROM rank_tie_overall o, rank_tie_today d
        WHERE email_rank.work_today = d.work_units
            AND email_rank.work_total = o.work_units
            AND email_rank.project_id = :ProjectID
    ;

    \echo  set previous rank = current rank for new participants
    
    UPDATE email_rank
        SET day_rank_previous = day_rank,
            overall_rank_previous = overall_rank
        FROM project_statsrun ps
        WHERE email_rank.project_id = :ProjectID
            AND email_rank.project_id = ps.project_id
            AND ps.project_id = :ProjectID
            AND first_date = ps.last_date
    ;

    SELECT stats_set_last_update(:ProjectID, 'e', stats_get_last_update(:ProjectID, 's'));
COMMIT;

--\echo  update statistics
--;
--update statistics email_rank
--;
--\echo  Rebuild indexes on email_rank
--create index iDAY_RANK on email_rank(PROJECT_ID, DAY_RANK)
--create index iOVERALL_RANK on email_rank(PROJECT_ID, OVERALL_RANK)
--;
