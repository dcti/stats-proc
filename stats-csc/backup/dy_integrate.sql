#!/usr/bin/sqsh -i
#
# $Id: dy_integrate.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $
#
# Move data from the import table to the daytables
#
# Arguments:
#       Project

insert into ${1}_daytable_master (timestamp, email, size)
select distinct convert(smalldatetime, convert(varchar(10),timestamp,101)) as timestamp, email, sum(size) as size
from ${1}_import
group by convert(smalldatetime, convert(varchar(10),timestamp,101)), email
go

insert into ${1}_daytable_platform (timestamp, cpu, os, ver, size)
select distinct convert(smalldatetime, convert(varchar(10),timestamp,101)) as timestamp, cpu, os, ver, sum(size) as size
from ${1}_import
group by convert(smalldatetime, convert(varchar(10),timestamp,101)), cpu, os, ver
go

