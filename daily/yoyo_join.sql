/*
# $Id: yoyo_join.sql,v 1.2 2008/05/01 03:50:09 thejet Exp $
#
# Accomodate yoyo@home wrapper client.  Auto-join participants
# who have no team affiliation and whose email address is
# *@yoyo.rechenkraft.net to the Yoyo@Home team.
#
# Yoyo@home Team ID = 31743
#
# Arguments:
#      StatsDate 
*/
\set ON_ERROR_STOP 1

\echo :: Gathering list of yoyo participant ids who are not on a team

-- This query will only get yoyo participants who have never joined
-- a team.
\echo Building temporary tables
SELECT par.id, :StatsDate::date AS join_date
    INTO TEMP new_yoyo
    FROM stats_participant par
    WHERE 
        par.email LIKE '%@yoyo.rechenkraft.net'
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
