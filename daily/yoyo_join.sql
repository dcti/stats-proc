/*
# $Id: yoyo_join.sql,v 1.1 2008/04/29 08:46:47 thejet Exp $
#
# Accomodate yoyo@home wrapper client.  Auto-join participants
# who have no team affiliation and whose email address is
# *@yoyo.rechenkraft.net to the Yoyo@Home team.
#
# Yoyo@home Team ID = 31743
#
# Arguments:
#       ProjectID
*/
\set ON_ERROR_STOP 1

\echo :: Gathering list of yoyo participant ids who are not on a team

-- This query will only get yoyo participants who have never joined
-- a team.
\echo Building temporary tables
SELECT par.id, ps.last_date AS join_date 
    INTO TEMP new_yoyo
    FROM stats_participant par, Project_statsrun ps
    WHERE ps.project_id = :ProjectID
        AND par.email LIKE '%@yoyo.rechenkraft.net'
        AND NOT EXISTS(SELECT * FROM team_joins WHERE id = par.id)
;

\echo Inserting new team_join records
INSERT INTO team_joins
 (id, team_id, join_date)
 SELECT id, 31743, join_date
   FROM new_yoyo
;

//commit;
rollback;
