-- $Id: audit.sql,v 1.42 2005/04/29 21:14:30 decibel Exp $
\set ON_ERROR_STOP 1
set sort_mem=1000000;
\t

CREATE TEMP TABLE audit (
    date        date,
    ECTsum        numeric(20) default 0,
    ECTblcksum    numeric(20) default 0,
    ECTteamsum    numeric(20) default 0,
    PCTsum        numeric(20) default 0,
    PCsum        numeric(20) default 0,
    PCsumtoday    numeric(20) default 0,
    DSsum         numeric(20) default 0,
    DSunits        numeric(20) default 0,
    DSusers        int default 0,
    ECsum        numeric(20) default 0,
    ECsumtoday    numeric(20) default 0,
    ECblcksumtdy    numeric(20) default 0,
    ECblcksum    numeric(20) default 0,
    ECteamsum    numeric(20) default 0,
    ERsumtoday    numeric(20) default 0,
    ERsum        numeric(20) default 0,
    TMsumtoday    numeric(20) default 0,
    TMsum        numeric(20) default 0,
    TRsumtoday    numeric(20) default 0,
    TRsum        numeric(20) default 0
) WITHOUT OIDs
;
INSERT INTO audit (date)
    SELECT last_date
    FROM project_statsrun
    WHERE project_id = :ProjectID
;
ANALYZE audit;

-- **************************
--   ECTsum
-- **************************
\echo Sum of work in email_contrib_today for project id :ProjectID
UPDATE audit
    SET ECTsum = (SELECT coalesce(sum(work_units), 0)
        FROM email_contrib_today
        WHERE project_id = :ProjectID)
;
SELECT ECTsum FROM audit
;



-- **************************
--   ECTblcksum
-- **************************
\echo Total work units ignored today (listmode >= 10)
UPDATE audit
    SET ECTblcksum = (SELECT coalesce(sum(d.work_units), 0)
                FROM email_contrib_today d, stats_participant_blocked spb
                WHERE project_id = :ProjectID
                    AND d.credit_id = spb.ID
                    AND spb.block_date <= audit.date
            )
;
SELECT ECTblcksum FROM audit
;




-- **************************
--   ECTteamsum
-- **************************
\echo Sum of team work in email_contrib_today
UPDATE audit
    SET ECTteamsum = (SELECT coalesce(sum(d.work_units), 0)
        FROM email_contrib_today d
        WHERE project_id = :ProjectID
            AND d.credit_id NOT IN (SELECT ID
                        FROM stats_participant_blocked spb
                        WHERE spb.ID = d.credit_id
                            AND spb.block_date <= audit.date
                    )
            AND d.TEAM_ID > 0
            AND d.TEAM_ID NOT IN (SELECT TEAM_ID
                        FROM STATS_Team_Blocked stb
                        WHERE stb.TEAM_ID = d.TEAM_ID
                            AND stb.block_date <= audit.date
                    )
        )
;
SELECT ECTteamsum FROM audit
;



-- **************************
--   PCTsum
-- **************************
\echo Sum of work in Platform_Contrib_Today for project id %1!, :ProjectID
UPDATE audit
    SET PCTsum = (SELECT coalesce(sum(work_units), 0)
        FROM platform_contrib_today
        WHERE project_id = :ProjectID)
;
SELECT PCTsum FROM audit
;



-- **************************
--   PCsumtoday
-- **************************
SELECT 'Sum of work in Platform_Contrib for today (' || date || ')' FROM audit
;
UPDATE audit
    SET PCsumtoday = (select coalesce(sum(work_units), 0)
        FROM platform_contrib
        WHERE project_id = :ProjectID
            AND date = audit.date)
;
SELECT PCsumtoday FROM audit
;



-- **************************
--   PCsum
-- **************************
\echo Total work units in Platform_Contrib
UPDATE audit
    SET PCsum = (SELECT coalesce(sum(work_units),0)
        FROM Platform_Contrib
        WHERE project_id = :ProjectID)
;
SELECT PCsum FROM audit
;



-- **************************
--   DSsum
-- **************************
\echo Total work units in Daily_Summary
UPDATE audit
    SET DSsum = (SELECT coalesce(sum(work_units),0)
        FROM Daily_Summary
        WHERE project_id = :ProjectID)
;
SELECT DSsum FROM audit
;



-- **************************
--   DSunits, DSusers
-- **************************
SELECT 'Work Units, Participants in Daily_Summary for today (' || date || ')' FROM audit
;
update audit
    SET DSunits = work_units
            , DSusers = participants
    FROM daily_summary ds
    WHERE audit.date = ds.date
        AND project_id = :ProjectID
;
SELECT DSunits, DSusers FROM audit
;



-- **************************
--   ECsum, ECblcksum, ECteamsum
-- **************************
-- Build a summary table, which dramatically cuts down the time needed for this
\echo Total work units, ignored work, team work in Email_Contrib
UPDATE audit
    SET ECsum = sum_workunits
            , ECblcksum = sum_blocked
            , ECteamsum = sum_team
    FROM (
            SELECT sum(work_units) AS sum_workunits
                    , sum(CASE WHEN spb.id IS NOT NULL
                                        AND spb.block_date <= a.date
                                THEN work_units
                            END) AS sum_blocked
                    ,  sum(CASE WHEN ws.team_id >= 1
                                    AND spb.id IS NULL
                                    AND stb.team_id IS NULL
                                    AND stb.block_date <= a.date
                                THEN ws.work_units
                            END) AS sum_team
            FROM audit a
                , email_contrib ws
                LEFT JOIN stats_participant_blocked spb ON (ws.id = spb.id)
                LEFT JOIN stats_team_blocked stb ON (ws.team_id = stb.team_id)
            WHERE ws.project_id = :ProjectID
        ) b
;

SELECT ECsum, ECblcksum, ECteamsum FROM audit
;


-- **************************
--   ECsumtoday
-- **************************
SELECT 'Sum of work in Email_Contrib for today (' || date || ')' FROM audit
;
BEGIN;
    --SET LOCAL enable_seqscan = off;
    UPDATE audit
        SET ECsumtoday = (SELECT coalesce(sum(work_units), 0)
            FROM email_contrib ec
            WHERE project_id = :ProjectID
                AND audit.date = ec.date
                            )
    ;
COMMIT;
SELECT ECsumtoday FROM audit
;



-- **************************
--   ECblcksumtdy
-- **************************
\echo Total work units ignored in Email_Contrib for today (listmode >= 10)
;

-- This will find all work for participants who are blocked, including people retired to them
UPDATE audit
    SET ECblcksumtdy = (SELECT coalesce(sum(e.work_units), 0)
        FROM email_contrib e, stats_participant_blocked spb
        WHERE project_id = :ProjectID
            AND e.date = (SELECT last_date FROM project_statsrun WHERE project_id = :ProjectID)
            AND e.id = spb.id
            AND spb.block_date <= audit.date
        )
;

SELECT ECblcksumtdy FROM audit
;



-- **************************
--   ERsumtoday, ERsum
-- **************************
\echo Total work reported in Email_Rank for Today, Overall
UPDATE audit
    SET ERsumtoday = e.sumtoday, ERsum = e.sum
    FROM (SELECT sum(WORK_TODAY) AS sumtoday, sum(WORK_TOTAL) AS sum
                FROM email_rank
                WHERE project_id = :ProjectID
            ) e
;
SELECT ERsumtoday, ERsum FROM audit
;



-- **************************
--   TMsumtoday, TMsum
-- **************************
\echo Total work reported in Team_Members for Today, Overall
UPDATE audit
    SET TMsumtoday = t.sumtoday
        , TMsum = t.sum
    FROM (SELECT coalesce(sum(WORK_TODAY), 0) AS sumtoday, coalesce(sum(WORK_TOTAL), 0) AS sum
                FROM team_members
                WHERE project_id = :ProjectID
            ) t
;
SELECT TMsumtoday, TMsum FROM audit
;


-- **************************
--   TRsumtoday, TRsum
-- **************************
\echo Total work reported in Team_Rank for Today, Overall
UPDATE audit
    SET TRsumtoday = t.sumtoday
        , TRsum = t.sum
    FROM (SELECT coalesce(sum(WORK_TODAY), 0) AS sumtoday, coalesce(sum(WORK_TOTAL), 0) AS sum
                FROM team_rank
                WHERE project_id = :ProjectID
            ) t
;
SELECT TRsumtoday, TRsum FROM audit
;




\echo !! begin sanity checks !!
;

/* ECTsum, ECsumtoday, PCTsum, PCsumtoday, and DSunits should all match */
\echo checking total work units submitted today....
SELECT 'ERROR! email_contrib_today sum (ECTsum=' || ECTsum
        || ') != Email_Contrib sum for today (ECsumtoday=' || ECsumtoday || ')'
    FROM audit WHERE ECTsum <> ECsumtoday;
SELECT 'ERROR! email_contrib_today sum (ECTsum=' || ECTsum
        || ') != Platform_Contrib_Today sum (PCTsum=' || PCTsum || ')'
    FROM audit WHERE ECTsum <> PCTsum;
SELECT 'ERROR! email_contrib_today sum (ECTsum=' || ECTsum
        || ') != Platform_Contrib sum for today (PCsumtoday=' || PCsumtoday || ')'
    FROM audit WHERE ECTsum <> PCsumtoday;
SELECT 'ERROR! email_contrib_today sum (ECTsum=' || ECTsum
        || ') != Daily_Summary for today (DSunits=' || DSunits || ')'
    FROM audit WHERE ECTsum <> DSunits;

/* ECsum, PCsum, and DSsum should all match, ERsum + ECblcksum should equal ECsum */
\echo checking total work units submitted....
SELECT 'ERROR! Email_Contrib sum (ECsum=' || ECsum
        || ') != Platform_Contrib sum (PCsum=' || PCsum || ')'
    FROM audit WHERE ECsum <> PCsum;
SELECT 'ERROR! Email_Contrib sum (ECsum=' || ECsum
        || ') != Daily_Summary sum (DSsum=' || DSsum || ')'
    FROM audit WHERE ECsum <> DSsum;

/* ECTblcksum should equal ECblcksumtdy */
\echo checking total units blocked today...
SELECT 'ERROR! EMail_Contrib_Today blocked sum (ECTblcksum=' || ECTblcksum
        || ') != Email_Contrib blocked sum for today (ECblcksumtdy=' || ECblcksumtdy || ')'
    FROM audit WHERE ECTblcksum <> ECblcksumtdy;

/* ECTblcksum + ERsumtoday should equal ECTsum */
SELECT 'ERROR! email_contrib_today blocked sum (ECTblcksum=' || ECTblcksum
        || ') + Email_Rank sum today (ERsumtoday=' || ERsumtoday
        || ') != email_contrib_today sum (ECTsum=' || ECTsum || ')'
    FROM audit WHERE  (ECTblcksum + ERsumtoday) <> ECTsum ;

/* ECblcksum + ERsum should equal ECsum */
SELECT 'ERROR! Email_Contrib blocked sum (ECblcksum=' || ECblcksum
        || ') + Email_Rank sum (ERsum=' || ERsum
        || ') != Email_Contrib sum (ECsum=' || ECsum || ')'
    FROM audit WHERE  (ECblcksum + ERsum) <> ECsum;

/* ECteamsum, TMsum, and TRsum should all match */
\echo checking team information...
SELECT 'ERROR! Email_Contrib team sum (ECteamsum=' || ECteamsum
        || ') != Team_Members sum (TMsum=' || TMsum || ')'
    FROM audit WHERE ECteamsum <> TMsum;
SELECT 'ERROR! Email_Contrib team sum (ECteamsum=' || ECteamsum
        || ') != Team_Rank sum (TRsum=' || TRsum || ')'
    FROM audit WHERE ECteamsum <> TRsum;

/* ECTteamsum, TMsumtoday, and TRsumtoday should all match */
SELECT 'ERROR! email_contrib_today team sum (ECTteamsum=' || ECTteamsum
        || ') != Team_Members sum today (TMsumtoday=' || TMsumtoday || ')'
    FROM audit WHERE ECTteamsum <> TMsumtoday;
SELECT 'ERROR! email_contrib_today team sum (ECTteamsum=' || ECTteamsum
        || ') != Team_Rank sum today (TRsumtoday=' || TRsumtoday || ')'
    FROM audit WHERE ECTteamsum <> TRsumtoday;
