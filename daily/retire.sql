/*
# $Id: retire.sql,v 1.25.2.2 2003/04/15 04:24:12 decibel Exp $
#
# Handles all pending retire_tos and black-balls
#
# Arguments:
#       ProjectID
*/

\echo Build a list of blocked participants
;
select ID into TEMP Blocked
	from STATS_Participant
	where LISTMODE >= 10
;
insert into Blocked(ID)
	select sp.ID
	from STATS_Participant sp, Blocked b
	where sp.RETIRE_TO > 0
		and sp.RETIRE_TO = b.ID
;

\echo Update STATS_Participant_Blocked

insert into STATS_Participant_Blocked(ID)
	select distinct ID
	from Blocked b
	where not exists (select *
				from STATS_Participant_Blocked spb
				where spb.ID = b.ID)
;
delete from STATS_Participant_Blocked
	where ID not in (select ID from Blocked)
;


\echo Update STATS_Team_Blocked

insert into STATS_Team_Blocked(TEAM_ID)
	select TEAM
	from STATS_Team st
	where st.LISTMODE >= 10
		and TEAM not in (select TEAM_ID
					from STATS_Team_Blocked stb
					where stb.TEAM_ID = st.TEAM
				)
;
delete from STATS_Team_Blocked
	where not exists (select *
				from STATS_Team
				where LISTMODE >= 10
			)
;

\echo Remove retired or hidden participants from Email_Rank
;
select RETIRE_TO, sum(WORK_TOTAL) as WORK_TOTAL, min(FIRST_DATE) as FIRST_DATE, max(LAST_DATE) as LAST_DATE
	into TEMP NewRetiresER
	from Email_Rank er, STATS_Participant sp
	where sp.ID = er.ID
		and sp.RETIRE_TO >= 1
		and sp.RETIRE_DATE = (SELECT last_hourly_date FROM Project_statsrun WHERE project_id = :ProjectID)
		and not exists (select *
					from STATS_Participant_Blocked spb
					where spb.ID = sp.ID
						and spb.ID = er.ID
				)
		and er.PROJECT_ID = :ProjectID
	group by RETIRE_TO
;

\echo Begin update

BEGIN;
    \echo Update Email_Rank with new information
    UPDATE Email_Rank
        SET WORK_TOTAL = Email_Rank.WORK_TOTAL + nr.WORK_TOTAL
        FROM NewRetiresER nr
        WHERE Email_Rank.ID = nr.RETIRE_TO
            and Email_Rank.PROJECT_ID = :ProjectID
    ;
    UPDATE Email_Rank
        SET FIRST_DATE = nr.FIRST_DATE
        FROM NewRetiresER nr
        WHERE Email_Rank.ID = nr.RETIRE_TO
            and Email_Rank.FIRST_DATE > nr.FIRST_DATE
            and Email_Rank.PROJECT_ID = :ProjectID
    ;
    UPDATE Email_Rank
        SET LAST_DATE = nr.LAST_DATE
        FROM NewRetiresER nr
        WHERE Email_Rank.ID = nr.RETIRE_TO
            and Email_Rank.LAST_DATE < nr.LAST_DATE
            and Email_Rank.PROJECT_ID = :ProjectID
    ;

    \echo 
    \echo 
    \echo Delete retires and blocked participants from Email_Rank
    DELETE FROM Email_Rank
        where project_id = :ProjectID
            and id IN  (SELECT id
                            FROM STATS_Participant sp
                            WHERE retire_to >= 1
                                and retire_date = (SELECT last_hourly_date FROM Project_statsrun WHERE project_id = :ProjectID)
                        )
    ;

    DELETE FROM Email_Rank
        WHERE project_id = :ProjectID
            and id IN (SELECT id FROM STATS_Participant_Blocked)
    ;

    -- The following code should ensure that any "retire_to chains" eventually get eliminated
    -- It is also needed in case someone retires to an address that hasnt done any work in
    -- this contest.
    \echo Insert remaining retires
    DELETE FROM NewRetiresER
        WHERE retire_to IN (SELECT id
                                FROM Email_Rank er
                                WHERE er.PROJECT_ID = :ProjectID
                            )
    ;

    INSERT into Email_Rank(PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
        SELECT :ProjectID, RETIRE_TO, FIRST_DATE, LAST_DATE, WORK_TOTAL
        FROM NewRetiresER
    ;
COMMIT;

\echo Remove retired participants from Team_Members

\echo Select new retires
SELECT retire_to, team_id, sum(work_total) as work_total, min(first_date) as first_date, max(last_date) as last_date
	INTO TEMP NewRetiresTM
	FROM Team_Members tm, STATS_Participant sp
	WHERE sp.ID = tm.ID
		and sp.RETIRE_TO >= 1
		and sp.RETIRE_DATE = (SELECT last_hourly_date FROM Project_statsrun WHERE project_id = :ProjectID)
		and not exists (select *
					from STATS_Participant_Blocked spb
					where spb.ID = sp.ID
						and spb.ID = tm.ID
				)
		and tm.PROJECT_ID = :ProjectID
	group by RETIRE_TO, TEAM_ID
;

\echo Begin update

BEGIN;
    \echo Update Team_Members with new information for retires
    UPDATE Team_Members
        SET WORK_TOTAL = Team_Members.WORK_TOTAL + nr.WORK_TOTAL
        FROM NewRetiresTM nr
        WHERE Team_Members.ID = nr.RETIRE_TO
            and Team_Members.TEAM_ID = nr.TEAM_ID
            and Team_Members.PROJECT_ID = :ProjectID
    ;
    UPDATE Team_Members
        SET FIRST_DATE = nr.FIRST_DATE
        FROM NewRetiresTM nr
        WHERE Team_Members.ID = nr.RETIRE_TO
            and Team_Members.TEAM_ID = nr.TEAM_ID
            and Team_Members.PROJECT_ID = :ProjectID
            and Team_Members.FIRST_DATE > nr.FIRST_DATE
    ;
    UPDATE Team_Members
        SET LAST_DATE = nr.LAST_DATE
        FROM NewRetiresTM nr
        WHERE Team_Members.ID = nr.RETIRE_TO
            and Team_Members.TEAM_ID = nr.TEAM_ID
            and Team_Members.PROJECT_ID = :ProjectID
            and Team_Members.LAST_DATE < nr.LAST_DATE
    ;

    \echo Delete retires from Team_Members
    DELETE FROM Team_Members
        WHERE Team_Members.PROJECT_ID = :ProjectID
            and id IN (SELECT id
                            FROM STATS_Participant sp, Project_statsrun ps
                            WHERE sp.RETIRE_TO >= 1
                                and sp.RETIRE_DATE = ps.last_hourly_date
                                and ps.project_id = :ProjectID
                        )
    ;

    -- This code *must* stay in order to handle retiring participants old team affiliations
    \echo 
    \echo 
    \echo Insert remaining retires
    DELETE FROM NewRetiresTM
        WHERE (retire_to, team_id) IN (SELECT id, team_id
                                            FROM Team_Members tm
                                            WHERE tm.PROJECT_ID = :ProjectID
                                        )
    ;
    INSERT into Team_Members(PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
        SELECT :ProjectID, RETIRE_TO, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL
        FROM NewRetiresTM
    ;
COMMIT;

\echo Remove hidden participants

\echo Select IDs to remove
SELECT DISTINCT spb.ID
	INTO BadIDs
	FROM Team_Members tm, STATS_Participant_Blocked spb
	WHERE tm.ID = spb.ID
		and PROJECT_ID = :ProjectID
;

\echo Summarize team work to be removed
SELECT TEAM_ID, sum(WORK_TOTAL) as BAD_WORK_TOTAL
	INTO BadWork
	FROM Team_Members tm, BadIDs b
	WHERE tm.ID = b.ID
		and PROJECT_ID = :ProjectID
	GROUP BY TEAM_ID
;

BEGIN;
    \echo Update Team_Rank to account for removed IDs
    UPDATE Team_Rank
        SET WORK_TOTAL = WORK_TOTAL - BAD_WORK_TOTAL
        FROM BadWork bw
        WHERE Team_Rank.TEAM_ID = bw.TEAM_ID
    ;
    \echo Delete from Team_Members
    DELETE FROM Team_Members
        WHERE project_id = :ProjectID
            and id IN (SELECT id FROM BadIDs)
    ;
COMMIT;
