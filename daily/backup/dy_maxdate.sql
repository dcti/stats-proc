#!/usr/bin/sqsh -i
#
# $Id: dy_maxdate.sql,v 1.1 2000/02/09 16:13:58 nugget Exp $

select convert(char(8),max(date),112) as maxdate from ${1}_master 
# turn off header and rows affected output
go -f -h

