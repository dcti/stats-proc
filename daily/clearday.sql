#!/usr/local/bin/sqsh -i
-- $Id: clearday.sql,v 1.5 2002/01/09 20:07:21 decibel Exp $

print "Dropping indexes"
go
--drop index Email_Contrib_Today.iID
--drop index Email_Contrib_Today.iTEAM_ID
--go

print "Deleting data"
go
delete Email_Contrib_Today where project_id=${1}
delete Platform_Contrib_Today where project_id=${1}
go

print "Updating Project_statsrun"
go
update Project_statsrun
	set LOGS_FOR_DAY = 0,
		WORK_FOR_DAY = 0
	where PROJECT_ID=${1}
go
