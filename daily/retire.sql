/*
# $Id: retire.sql,v 1.35 2005/05/11 18:13:27 decibel Exp $
#
# Handles all pending retire_tos and black-balls
#
# Arguments:
#       ProjectID
*/
\set ON_ERROR_STOP 1

\echo Build a list of blocked participants
BEGIN;
-- Participants who are directly blocked
SELECT id
    INTO TEMP blocked
    FROM stats_participant
    WHERE listmode >= 10
;

-- Participants retired to blocked participants
INSERT INTO blocked(id)
    SELECT sp.id
    FROM stats_participant sp, blocked b
    WHERE sp.retire_to > 0
        AND sp.retire_to = b.id
        AND sp.retire_date <= (SELECT last_date FROM Project_statsrun WHERE project_id = :ProjectID)
;

-- Participants with blacked participants retired to them
INSERT INTO blocked(id)
    SELECT sp.retire_to
    FROM stats_participant sp, blocked b
    WHERE sp.id = b.id
        AND sp.retire_to > 0
        AND sp.retire_date <= (SELECT last_date FROM Project_statsrun WHERE project_id = :ProjectID)
;

-- One final pass at participants retired to blocked participants
-- This is in case we picked up participants with blocked participants retired to them
INSERT INTO blocked(id)
    SELECT sp.id
    FROM stats_participant sp, blocked b
    WHERE sp.retire_to > 0
        AND sp.retire_to = b.id
        AND sp.retire_date <= (SELECT last_date FROM Project_statsrun WHERE project_id = :ProjectID)
;
COMMIT;

\echo Update stats_participant_blocked

INSERT INTO stats_participant_blocked(id, block_date)
    SELECT distinct id
            , (SELECT last_date FROM project_statsrun WHERE project_id = :ProjectID)
        FROM blocked b
        WHERE NOT EXISTS (SELECT *
                    FROM stats_participant_blocked spb
                    WHERE spb.id = b.id)
;
DELETE FROM stats_participant_blocked
    WHERE id NOT IN (SELECT id FROM blocked)
;


\echo Update STATS_Team_Blocked
BEGIN;
insert into STATS_Team_Blocked(TEAM_ID, block_date)
    select TEAM
            , (SELECT last_date FROM project_statsrun WHERE project_id = :ProjectID)
    from STATS_Team st
    where st.LISTMODE >= 10
        and TEAM not in (select TEAM_ID
                    from STATS_Team_Blocked stb
                    where stb.TEAM_ID = st.TEAM
                )
;
delete from STATS_Team_Blocked
    where not exists (select *
                from STATS_Team st
                where STATS_Team_Blocked.TEAM_ID = st.TEAM
                    AND LISTMODE >= 10
            )
;
COMMIT;

BEGIN;
    --SET LOCAL enable_seqscan = off;
    SELECT id, retire_to
        INTO TEMP Tnew_retires
        FROM STATS_Participant sp
        WHERE retire_to >= 1
            AND retire_date = (SELECT last_date FROM Project_statsrun WHERE project_id = :ProjectID)
    ;
COMMIT;
ANALYZE Tnew_retires;

\echo Remove retired or hidden participants from Email_Rank
SELECT RETIRE_TO, sum(WORK_TOTAL) as WORK_TOTAL, min(FIRST_DATE) as FIRST_DATE, max(LAST_DATE) as LAST_DATE
    INTO TEMP NewRetiresER
    FROM email_rank er, Tnew_retires nr
    WHERE nr.id = er.id
        AND NOT EXISTS (SELECT *
                    FROM stats_participant_blocked spb
                    WHERE spb.id = nr.id
                        AND spb.id = er.id
                        AND block_date <= (SELECT last_date FROM project_statsrun WHERE project_id = :ProjectID)
                )
        AND er.project_id = :ProjectID
    GROUP BY retire_to
;
ANALYZE NewRetiresER;

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
    DELETE FROM email_rank
        WHERE project_id = :ProjectID
            AND EXISTS (SELECT 1
                            FROM Tnew_retires nr
                            WHERE nr.id = email_rank.id
                        )
    ;

    DELETE FROM email_rank
        WHERE project_id = :ProjectID
            AND EXISTS (SELECT *
                            FROM stats_participant_blocked spb
                            WHERE spb.id = email_rank.id
                                AND block_date <= (SELECT last_date
                                                            FROM project_statsrun
                                                            WHERE project_id = :ProjectID
                                                    )
                        )
    ;

    -- The following code should ensure that any "retire_to chains" eventually get eliminated
    -- It is also needed in case someone retires to an address that hasnt done any work in
    -- this contest.
    \echo Insert remaining retires
    /* I think doing the one insert is way faster, but I'm not sure
    DELETE FROM NewRetiresER
        WHERE EXISTS (SELECT 1
                                FROM Email_Rank er
                                WHERE er.PROJECT_ID = :ProjectID
                                    AND er.id = NewRetiresER.retire_to
                            )
    ;

    INSERT into Email_Rank(PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
        SELECT :ProjectID, RETIRE_TO, FIRST_DATE, LAST_DATE, WORK_TOTAL
        FROM NewRetiresER
    ;
    */
    INSERT into Email_Rank(PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
        SELECT :ProjectID, RETIRE_TO, FIRST_DATE, LAST_DATE, WORK_TOTAL
        FROM NewRetiresER
        WHERE NOT EXISTS (SELECT 1
                                FROM Email_Rank er
                                WHERE er.PROJECT_ID = :ProjectID
                                    AND er.id = NewRetiresER.retire_to
                            )
    ;
COMMIT;

\echo Remove retired participants from Team_Members

\echo Select new retires
SELECT retire_to, team_id, sum(work_total) as work_total, min(first_date) as first_date, max(last_date) as last_date
    INTO TEMP NewRetiresTM
    FROM Team_Members tm, Tnew_retires nr
    WHERE nr.id = tm.id
        AND NOT EXISTS (SELECT *
                            FROM stats_participant_blocked spb
                            WHERE spb.id = nr.id
                                AND spb.id = tm.id
                                AND block_date <= (SELECT last_date
                                                            FROM project_statsrun
                                                            WHERE project_id = :ProjectID
                                                    )
                        )
        AND tm.project_id = :ProjectID
    GROUP BY retire_to, team_id
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
    DELETE FROM team_members
        WHERE team_members.project_id = :ProjectID
            AND EXISTS (SELECT 1
                            FROM Tnew_retires nr
                            WHERE nr.id = team_members.id
                        )
    ;

    -- This code *must* stay in order to handle retiring participants old team affiliations
    \echo 
    \echo 
    \echo Insert remaining retires
    INSERT into Team_Members(PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL)
        SELECT :ProjectID, RETIRE_TO, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TOTAL
        FROM NewRetiresTM
        WHERE NOT EXISTS (SELECT 1
                            FROM team_members tm
                            WHERE tm.project_id = :ProjectID
                                AND tm.id = NewRetiresTM.retire_to
                                AND tm.team_id = NewRetiresTM.team_id
                        )
    ;
COMMIT;

\echo Remove hidden participants

\echo Select IDs to remove
-- This is all in one transaction because of the SET LOCAL
BEGIN;
    --SET LOCAL enable_seqscan = off;
    SELECT DISTINCT spb.ID
        INTO TEMP BadIDs
        FROM Team_Members tm, STATS_Participant_Blocked spb
        WHERE tm.ID = spb.ID
            and PROJECT_ID = :ProjectID
    ;
    ANALYZE BadIDs;

    \echo Summarize team work to be removed
    SELECT TEAM_ID, sum(WORK_TOTAL) as BAD_WORK_TOTAL
        INTO TEMP BadWork
        FROM Team_Members tm, BadIDs b
        WHERE tm.ID = b.ID
            and PROJECT_ID = :ProjectID
        GROUP BY TEAM_ID
    ;
    ANALYZE BadWork;

    \echo Update Team_Rank to account for removed IDs
    UPDATE Team_Rank
        SET WORK_TOTAL = WORK_TOTAL - BAD_WORK_TOTAL
        FROM BadWork bw
        WHERE project_id = :ProjectID
            AND Team_Rank.TEAM_ID = bw.TEAM_ID
    ;
    \echo Delete from Team_Members
    DELETE FROM Team_Members
        WHERE project_id = :ProjectID
            AND id IN (SELECT id FROM BadIDs)
    ;
COMMIT;

-- vi: expandtab ts=4 sw=4
