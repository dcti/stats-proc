#!/usr/bin/sqsh -i
#
# $Id: dy_maxdate.sql,v 1.3 2000/04/13 14:58:16 bwilson Exp $

select LAST_STATS_DATE
	from Projects
	where NAME = "${1}"
# turn off header and rows affected output
go -f -h

