#!/usr/bin/sqsh -i
#
# $Id: dy_newemails.sql,v 1.2 2000/02/10 15:13:54 bwilson Exp $
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
	where email <> 'rc5@distributed.net'
	order by email
/*
**	Eliminate all the rc5@distributed.net rows on the first pass
**	We know this id exists, so don't clutter up the temp tables
**	grouping them together.
*/

create unique index iemail on #${1}_allemails(email)
go

delete #${1}_allemails
	from STATS_Participant
	where #${1}_allemails.email = STATS_Participant.email
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

