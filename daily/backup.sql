#!/usr/bin/sqsh -i
#
# $Id: backup.sql,v 1.9 2000/10/26 20:19:33 decibel Exp $
#
# Makes backup copies of Email_Rank, Team_Rank, and Team_Members
# Arguments:
#	Project

print "Deleting old data and any previous data for today."
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}
delete statproc.Email_Rank_Backup
	where PROJECT_ID = ${1} and BACKUP_DATE = @stats_date
delete statproc.Email_Rank_Backup
	where PROJECT_ID = ${1} and BACKUP_DATE < dateadd(dd, -7, @stats_date)
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}
delete statproc.Team_Rank_Backup
	where PROJECT_ID = ${1} and BACKUP_DATE = @stats_date
delete statproc.Team_Rank_Backup
	where PROJECT_ID = ${1} and BACKUP_DATE < dateadd(dd, -7, @stats_date)
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}
delete statproc.Team_Members_Backup
	where PROJECT_ID = ${1} and (BACKUP_DATE = @stats_date or BACKUP_DATE < dateadd(dd, -7, @stats_date)
go

print "Backing up Email_Rank"
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert into statproc.Email_Rank_Backup (BACKUP_DATE, PROJECT_ID, ID, FIRST_DATE, LAST_DATE,
		WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select @stats_date, ${1}, ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS
	from Email_Rank
	where PROJECT_ID = ${1}
go
print "Backing up Team_Rank"
go

declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert into statproc.Team_Rank_Backup (BACKUP_DATE, PROJECT_ID, TEAM_ID, FIRST_DATE, LAST_DATE,
		WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS, MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_CURRENT)
	select @stats_date, ${1}, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS,
		MEMBERS_TODAY, MEMBERS_OVERALL, MEMBERS_CURRENT
	from Team_Rank
	where PROJECT_ID = ${1}
go

print "Backing up Team_Members"
go
declare @stats_date smalldatetime
select @stats_date = LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}

insert into statproc.Team_Members_Backup (BACKUP_DATE, PROJECT_ID, ID, TEAM_ID,  FIRST_DATE, LAST_DATE,
		WORK_TODAY, WORK_TOTAL, DAY_RANK, DAY_RANK_PREVIOUS,
		OVERALL_RANK, OVERALL_RANK_PREVIOUS)
	select @stats_date, ${1}, ID, TEAM_ID, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL,
		DAY_RANK, DAY_RANK_PREVIOUS, OVERALL_RANK, OVERALL_RANK_PREVIOUS
	from Team_Members
	where PROJECT_ID = ${1}
go
