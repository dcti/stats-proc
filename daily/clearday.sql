#!/usr/local/bin/sqsh -i
-- $Id: clearday.sql,v 1.4 2001/12/29 08:50:50 decibel Exp $

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
