print "Dropping indexes"
go
drop index Email_Contrib_Today.iID
drop index Email_Contrib_Today.iTEAM_ID
go

print "Deleting data"
go
delete Email_Contrib_Today where project_id=${1}
delete Platform_Contrib_Today where project_id=${1}
go
