#
# $Id: recovercrash.sql,v 1.1 2003/09/11 02:04:02 decibel Exp $
#
# Use to recover team and participants tables in the event of a server
# crash when no additional records have been posted to either table.
#

use stats
go

create table STATS_participantnew
( id        numeric (10,0) IDENTITY NOT NULL,
  email     char (64) NOT NULL,
  password  char (8) NULL ,
  listmode  smallint NULL ,
  nonprofit int NULL ,
  team      int NULL ,
  retire_to int NULL,
  friend_a  int NULL,
  friend_b  int NULL,
  friend_c  int NULL,
  friend_d  int NULL,
  friend_e  int NULL,
  dem_yob   int NULL,
  dem_heard int NULL,
  dem_gender char (1) NULL,
  dem_motivation int NULL,
  dem_country char(8) NULL,
  contact_name char (50) NULL,
  contact_phone char (20) NULL,
  motto char (128) NULL
)
go


set identity_insert STATS_participantnew on
go

insert into STATS_participantnew
 (id,email,password,listmode,nonprofit,team,retire_to,friend_a,friend_b,
  friend_c,friend_d,friend_e,dem_yob,dem_heard,dem_gender,dem_motivation,
  dem_country,contact_name,contact_phone,motto)
 select
  id,email,password,listmode,nonprofit,team,retire_to,friend_a,friend_b,
  friend_c,friend_d,friend_e,dem_yob,dem_heard,dem_gender,dem_motivation,
  dem_country,contact_name,contact_phone,motto
from STATS_participant
where id < 500000
go

set identity_insert STATS_participantnew off
go

create index team on STATS_participantnew(team)
go

create index email on STATS_participantnew(email)
go

create index id on STATS_participantnew(id)
go

grant select,insert,update on STATS_participantnew to public
go

grant all on STATS_participantnew to wheel
go

drop table STATS_participantold
go

sp_rename STATS_participant, STATS_participantold
go

sp_rename STATS_participantnew, STATS_participant
go

use stats
go

CREATE TABLE stats.dbo.STATS_teamnew (
	team numeric (10,0) IDENTITY NOT NULL,
	listmode smallint NULL,
	password char (8) NULL,
	name char (64) NULL ,
	url char (64) NULL ,
	contactname char (64) NULL,
	contactemail char (64) NULL,
	logo char (64) NULL,
	showmembers char (3) NULL,
	showpassword char (16) NULL,
	description text NULL
)
go

set identity_insert STATS_teamnew on
go

insert into STATS_teamnew
 (team,listmode,password,name,url,contactname,contactemail,logo,showmembers,
  showpassword,description)
 select
  team,listmode,password,name,url,contactname,contactemail,logo,showmembers,
  showpassword,description
from STATS_team
where team < 500000
go

set identity_insert STATS_teamnew off
go

create index name on STATS_teamnew(name)
go

create index team on STATS_teamnew(name)
go


grant select,insert, update on STATS_teamnew to public
go

grant all on STATS_teamnew to wheel
go

drop table STATS_teamold
go

sp_rename STATS_team, STATS_teamold
go

sp_rename STATS_teamnew, STATS_team
go

