#!/usr/bin/sqsh -i
#
# $Id: dy_maxdate.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $

select convert(char(8),max(date),112) as maxdate from ${1}_master 
# turn off header and rows affected output
go -f -h

