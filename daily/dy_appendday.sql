/*
# $Id: dy_appendday.sql,v 1.23.2.1 2003/04/22 21:18:03 decibel Exp $
#
# Appends the data from the daytables into the main tables
#
# Arguments:
#       PROJECT_ID
*/

\echo !! Appending day's activity to master tables

\echo ::  Assigning CREDIT_ID and TEAM in Email_Contrib_Today

/*
** CREDIT_ID holds RETIRE_TO or ID.  Not unique, but guaranteed to
** be the ID that should get credit for this work.
*/

select stats_set_last_update(:ProjectID, 'ec', NULL);

UPDATE email_contrib_today
	SET credit_id = sp.retire_to
	FROM stats_participant sp, project_statsrun ps
	WHERE sp.id = email_contrib_today.id
        AND ps.project_id = email_contrib_today.project_id
		AND sp.retire_to >= 1
		AND (sp.retire_date <= ps.last_date or sp.retire_date is null)
		AND NOT EXISTS (SELECT *
					FROM stats_participant_blocked spb
					WHERE spb.id = email_contrib_today.id
						AND spb.id = sp.id
				)
		AND email_contrib_today.project_id = :ProjectID
;

UPDATE email_contrib_today
	SET team_id = tj.team_id
	FROM team_joins tj, project_statsrun ps
	WHERE tj.id = email_contrib_today.credit_id
        AND ps.project_id = email_contrib_today.project_id
        AND ps.project_id = :ProjectID
		AND tj.join_date <= ps.last_date
		AND (tj.last_date = NULL OR tj.last_date >= ps.last_date)
		AND email_contrib_today.project_id = :ProjectID
;
--create unique clustered index iID on Email_Contrib_Today(PROJECT_ID,ID)
--create index iTEAM_ID on Email_Contrib_Today(PROJECT_ID,TEAM_ID)
--;

\echo ::  Appending into Email_Contrib

INSERT INTO email_contrib (date, project_id, id, team_id, work_units)
	SELECT ps.last_date, d.project_id, d.id, d.team_id, d.work_units
        FROM email_contrib_today d, project_statsrun ps
        WHERE d.project_id = :ProjectID
            AND d.project_id = ps.project_id
            AND ps.project_id = :ProjectID
        /* Group by is unnecessary, data is already summarized */
;

SELECT stats_set_last_update(:ProjectID, 'ec', stats_get_last_update(:ProjectID, 's'));

\echo :: Appending into Platform_Contrib

SELECT stats_set_last_update(:ProjectID, 'pc', NULL);

INSERT INTO platform_contrib (date, project_id, cpu, os, ver, work_units)
	SELECT ps.last_date, p.project_id, p.cpu, p.os, p.ver, p.work_units
        FROM platform_contrib_today p, project_statsrun ps
        WHERE p.project_id = :ProjectID
            AND p.project_id = ps.project_id
            AND ps.project_id = :ProjectID
        /* Group by is unnecessary, data is already summarized */
;

SELECT stats_set_last_update(:ProjectID, 'pc', stats_get_last_update(:ProjectID, 's'));
