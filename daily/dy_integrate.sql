#!/usr/bin/sqsh -i
#
# $Id: dy_integrate.sql,v 1.2 2000/02/10 15:13:54 bwilson Exp $
#
# Move data from the import table to the daytables
#
# Arguments:
#       Project

insert into ${1}_daytable_master (timestamp, email, size)
select convert(varchar,timestamp,112) as timestamp, email, sum(size) as size
from ${1}_import
group by convert(varchar, timestamp, 112), email
go

insert into ${1}_daytable_platform (timestamp, cpu, os, ver, size)
select convert(varchar, timestamp, 112) as timestamp, cpu, os, ver, sum(size) as size
from ${1}_import
group by convert(varchar, timestamp, 112), cpu, os, ver
go

delete ${1}_import where 1 = 1
go
