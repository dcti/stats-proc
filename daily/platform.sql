-- $Id: platform.sql,v 1.1 2002/06/06 03:19:20 decibel Exp $

delete from Platform_Summary where PROJECT_ID = ${1}
go

insert into Platform_Summary (PROJECT_ID, CPU, OS, VER, FIRST_DATE, LAST_DATE, WORK_TODAY, WORK_TOTAL)
	select PROJECT_ID, CPU, OS, VER, min(DATE), max(DATE), 0, sum(WORK_UNITS)
	from Platform_Contrib
	where PROJECT_ID = ${1}
	group by PROJECT_ID, CPU, OS, VER
go

update Platform_Summary set WORK_TODAY = WORK_UNITS
	from Platform_Contrib pc
	where PS.PROJECT_ID = pc.PROJECT_ID
		and PS.CPU = pc.CPU
		and PS.OS = pc.OS
		and PS.VER = pc.VER
		and PS.PROJECT_ID = ${1}
		and pc.PROJECT_ID = ${1}
		and pc.DATE = (select max(DATE) from Platform_Contrib where PROJECT_ID = ${1})
go
