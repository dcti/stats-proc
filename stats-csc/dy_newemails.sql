#!/usr/bin/sqsh -i
#
# $Id: dy_newemails.sql,v 1.1 2003/09/11 02:05:45 decibel Exp $
#
# Adds new participants to stats_participant
#
# Arguments:
#       Project

print "!! Adding new emails to stats_participant"
go
print "::  Creating temp table with identity"
go
create table #${1}_dayemails
(
	id		numeric(10, 0)	identity,
	email		varchar(64)	not NULL
)
go

print "::  Inserting all new emails from daytable"
go
select distinct email
	into #${1}_allemails
	from ${1}_daytable_master
	order by email
go

delete from #${1}_allemails
	where email in (select email from STATS_participant)
go

insert into #${1}_dayemails (email)
	select email
	from #${1}_allemails
go

print "::  Adding new participants to stats_participant"
go
declare @idoffset int

select @idoffset = max(id)
	from STATS_Participant
	where id < 5000000

-- [BW] If we switch to retire_to = id as the normal condition,
--	this insert should insert (id, email, retire_to)
--	from id + @idoffset, email, id + @idoffset
insert into STATS_participant (id, email)
	select id + @idoffset, email
	from #${1}_dayemails
go

