#!/usr/bin/sqsh -i
#
# $Id: dp_newjoin.sql,v 1.4 2000/04/13 14:58:16 bwilson Exp $
#
# Does team joins for past blocks
#
# Arguments:
#       Project

update Email_Contrib
	set TEAM_ID = sp.TEAM
	from STATS_Participant sp
	where sp.ID = Email_Contrib.ID
		and Email_Contrib.TEAM_ID = 0
		and sp.TEAM >= 1
go
