/*
#
# $Id: em_rank.sql,v 1.22.2.1 2003/04/23 02:45:22 decibel Exp $
#
# Does the participant ranking
#
# Arguments:
#       Project_id
*/

\echo !! Begin e-mail ranking
--\echo  Drop indexes on Email_Rank
--drop index Email_Rank.iDAY_RANK
--drop index Email_Rank.iOVERALL_RANK
--;

\echo  Create rank table for overall
CREATE TEMP SEQUENCE rnk_assign_overall CACHE 2000;
SELECT work_units, min(raw_rank) AS rank INTO TEMP rank_tie_overall
    FROM (SELECT nextval('rnk_assign_overall') AS raw_rank, work_total AS work_units
            FROM email_rank
            WHERE project_id = :ProjectID
            ORDER BY work_total DESC, id DESC) AS raw_rank
    GROUP BY work_units
;

\echo    Index on work_units
CREATE UNIQUE INDEX work_units_overall ON rank_tie_overall(work_units)
;

\echo  Create rank table for today
CREATE TEMP SEQUENCE rnk_assign_today CACHE 2000;
SELECT work_units, min(raw_rank) AS rank INTO TEMP rank_tie_today
    FROM (SELECT nextval('rnk_assign_today') AS raw_rank, work_today AS work_units
            FROM email_rank
            WHERE project_id = :ProjectID
            ORDER BY work_today DESC, id DESC) AS raw_rank
    GROUP BY work_units
;

\echo    Index on work_units
CREATE UNIQUE INDEX work_units_today ON rank_tie_today(work_units)
;

\echo  Update Email_Rank with new rankings
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
--update statistics Email_Rank
--;
--\echo  Rebuild indexes on Email_Rank
--create index iDAY_RANK on Email_Rank(PROJECT_ID, DAY_RANK)
--create index iOVERALL_RANK on Email_Rank(PROJECT_ID, OVERALL_RANK)
--;
