# $Id: dy_maxdate.sql,v 1.1 1999/07/27 20:49:04 nugget Exp $

select convert(char(8),max(date),112) as maxdate from RC5_64_master 
go

