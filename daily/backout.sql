#!/usr/bin/sqsh -i
#
# $Id: backout.sql,v 1.4 2000/07/18 10:46:58 decibel Exp $
#
# This script will back out all stats data to a given date
#
# Arguments
#	Project ID
#	The date to back out *to*. The data specified will *remain* in the database.

use stats
go

begin transaction
print "Deleting from Email_Contrib where DATE > '%1!'", "${2}"
delete from Email_Contrib where PROJECT_ID = ${1} and DATE > "${2}"

print "Deleting from Platform_Contrib where DATE > '%1!'", "${2}"
delete from Platform_Contrib where PROJECT_ID = ${1} and DATE > "${2}"

print "Deleting from Daily_Summary where DATE > '%1!'", "${2}"
delete Daily_Summary where PROJECT_ID = ${1} and DATE > "${2}"

print "Deleting from Email_Rank"
delete from Email_Rank where PROJECT_ID = ${1}

print "Deleting from Team_Rank"
delete from Team_Rank where PROJECT_ID = ${1}

print "Deleting from Team_Members"
delete from Team_Members where PROJECT_ID = ${1}

print "Inserting into Email_Rank"
insert into Email_Rank (PROJECT_ID, ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select ${1}, ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS
	from statproc.Email_Rank_Backup
	where PROJECT_ID = ${1}
		and BACKUP_DATE = "${2}"

print "Inserting into Team_Rank"
insert into Team_Rank (PROJECT_ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS,
		MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_CURRENT)
	select ${1}, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS,
		MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_CURRENT
	from statproc.Team_Rank_Backup
	where PROJECT_ID = ${1}
		and BACKUP_DATE = "${2}"

print "Inserting into Team_Members"
insert into Team_Members (PROJECT_ID, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select ${1}, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS
	from statproc.Team_Members_Backup
	where PROJECT_ID = ${1}
		and BACKUP_DATE = "${2}"
commit transaction
go
