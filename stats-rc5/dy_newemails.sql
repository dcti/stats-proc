#!/usr/bin/sqsh -i
#
# $Id: dy_newemails.sql,v 1.2 2003/09/11 02:04:01 decibel Exp $
#
# Adds new participants to stats_participant
#
# Arguments:
#       Project

print "!! Adding new emails to stats_participant"
go

print "::  Inserting all new emails from daytable"
go
select distinct email
	into #${1}_dayemails
	from rc5_64_daytable_master
	order by email
go

delete from #${1}_dayemails
	where email in (select email from STATS_participant)
go
alter table #${1}_dayemails
 add id numeric(10, 0) identity
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

