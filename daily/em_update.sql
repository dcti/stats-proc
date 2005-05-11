/*
#
# $Id: em_update.sql,v 1.12 2005/05/11 18:13:27 decibel Exp $
#
# Updates the info in the Email_Rank table
#
# Arguments:
#       ProjectID
*/
\set ON_ERROR_STOP 1

\echo !! Begin e-mail ranking
\echo  Drop indexes on Email_Rank
--drop index Email_Rank.iDAY_RANK
--drop index Email_Rank.iOVERALL_RANK
--;

/*
** TODO: Assign earlier date if others are retired into
** Should not attempt to do it here.  It should happen one-up during a retire.
*/

\echo Build temporary tables
SELECT credit_id, sum(ect.work_units) AS work_today INTO TEMP retired_work
    FROM email_contrib_today ect
    WHERE ect.project_id = :ProjectID
        AND NOT EXISTS (SELECT *
                    FROM stats_participant_blocked spb, project_statsrun ps
                    WHERE spb.id = ect.credit_id
                        AND ps.project_id = ect.project_id
                        AND spb.block_date <= ps.last_date
                )
    GROUP by ect.CREDIT_ID
;

\echo  Insert new participants
;

BEGIN;
    --\set LOCAL enable_seqscan=off
    SELECT stats_set_last_update(:ProjectID, 'e', NULL);

explain analyze
    INSERT INTO email_rank (project_id, id, first_date, last_date)
        SELECT :ProjectID, rw.credit_id, stats_get_last_update(:ProjectID, 's'), stats_get_last_update(:ProjectID, 's')
        FROM retired_work rw
        WHERE NOT EXISTS (SELECT 1 FROM email_rank er WHERE project_id=:ProjectID AND er.id = rw.credit_id)
    ;

    \echo  Remove or move "today" info 

explain analyze
    UPDATE email_rank
        SET day_rank_previous = day_rank,
            overall_rank_previous = overall_rank,
            work_today = 0
        WHERE email_rank.project_id = :ProjectID
    ;

    \echo 
    \echo
    \echo  Update with new info
    UPDATE email_rank
        SET work_today = rw.work_today,
            work_total = work_total + rw.work_today,
            last_date = stats_get_last_update(:ProjectID, 's')
        FROM retired_work rw
        WHERE rw.credit_id = email_rank.id
            AND email_rank.project_id = :ProjectID
    ;
COMMIT;
drop table retired_work
;
