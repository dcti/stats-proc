-- $Id: platform.sql,v 1.2 2002/06/08 04:30:14 decibel Exp $

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
	where Platform_Summary.PROJECT_ID = pc.PROJECT_ID
		and Platform_Summary.CPU = pc.CPU
		and Platform_Summary.OS = pc.OS
		and Platform_Summary.VER = pc.VER
		and Platform_Summary.PROJECT_ID = ${1}
		and pc.PROJECT_ID = ${1}
		and pc.DATE = (select max(DATE) from Platform_Contrib where PROJECT_ID = ${1})
go
