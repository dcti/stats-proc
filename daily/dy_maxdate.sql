#!/usr/bin/sqsh -i
#
# $Id: dy_maxdate.sql,v 1.2 2000/03/29 18:22:10 bwilson Exp $

select LAST_STATS_DATE
	from Projects
	where NAME = '${1}'
# turn off header and rows affected output
go -f -h

