#!/usr/bin/sqsh -i
#
# $Id: dp_newjoin.sql,v 1.3 2000/02/29 16:22:27 bwilson Exp $
#
# Does team joins for past blocks
#
# Arguments:
#       Project

update ${1}_master
	set team = STATS_Participant.team
	from STATS_Participant
	where STATS_Participant.id = ${1}_master.id
		and ${1}_master.team = 0 and
      		STATS_participant.team > 0
go
