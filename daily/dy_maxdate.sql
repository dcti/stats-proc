#!/usr/bin/sqsh -i
#
# $Id: dy_maxdate.sql,v 1.4 2000/04/14 21:32:55 bwilson Exp $
#
# Parameters:
#	PROJECT_ID

select LAST_STATS_DATE
	from Projects
	where PROJECT_ID = ${1}
# turn off header and rows affected output
go -f -h

