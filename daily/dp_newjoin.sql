#!/usr/bin/sqsh -i
#
# $Id: dp_newjoin.sql,v 1.5 2000/04/14 21:32:55 bwilson Exp $
#
# Does team joins for past blocks
#
# Arguments:
#       PROJECT_ID

update Email_Contrib
	set TEAM_ID = sp.TEAM
	from STATS_Participant sp
	where Email_Contrib.TEAM_ID = 0
		and Email_Contrib.PROJECT_ID = ${1}
		and sp.ID = Email_Contrib.ID
		and sp.TEAM >= 1
go
