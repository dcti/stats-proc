@Echo Off
:Start
	Set Procdrive=D:
	Set Procdir=D:\Incoming
	Set Webdrive=C:
	Set Webroot=C:\rc5web
	Set AllDone=D:\holding
	Set StatsIP=205.149.163.207
	Set SQL=RC5STATS
	Set Debug=Rem

	If "%1%"=="" Goto End
	Goto %1%
	Goto End

:STATSOFF
	Rem This will hopefully shut down the stats server for the duration of the update.
	%Procdrive%
	Cd %Procdir%
	WGET http://eris.best.net:8064/mu-apache.cgi
	Del mu-*
Rem	Echo Blerg > nologs.lck
	NET STOP "FTP Publishing Service"
	Goto End

:CLEARIMPORT
	Rem This clears out the import table.  (It's the only way to be sure)
	%Procdrive%
	Cd %Procdir%
	isql -U Bovine -P mookow5624 -e -p -S %SQL% < DY_CLEARIMPORT.SQL
	%Debug%
	Goto End


:IMPORT
	%Procdrive%
	Cd %Procdir%\Workdir
	for %%i in (*.log) do TR.EXE -s \015 \015 < %%i > INFILE
	Copy *.log INFILE
	BCP.EXE import in INFILE /UBovine /Pmookow5624 /S%SQL% -eerrors.log /c /t,
	isql -U Bovine -P mookow5624 -e -p -S %SQL% < ..\PROCSTATUS.SQL | grep :5 > %Webroot%\PROCSTATUS.TXT
	isql -U Bovine -P mookow5624 -e -p -S %SQL% < ..\DY_FIXBLOCKSIZE.SQL
Rem	isql -U Bovine -P mookow5624 -e -p -S %SQL% < ..\DY_KILLOLDVER.SQL
	%Debug%
	%Debug%
	Goto End

:CLEARDAY
	Rem This clears out *everything* import-related.  (It's the only way to be sure)
	%Procdrive%
	Cd %Procdir%
	isql -U Bovine -P mookow5624 -e -p -S %SQL% < DY_CLEARDAYTABLES.SQL
	%Debug%
	Goto End

:INTEGRATE
	Rem Works with a fresh import table and adds it to the day_* tables
	%Procdrive%
	Cd %Procdir%
	isql -U Bovine -P mookow5624 -e -p -S %SQL% < DY_INTEGRATE.SQL
	%Debug%
	Goto End

:MOVEAWAY
	Rem Moves imported logfiles to a holding bin
	%Procdrive%
	Cd %Procdir%
	wc -c -l workdir\rc5*.log >> ldlog.txt
Rem     Move workdir\rc5*.log %AllDone%
Rem     gzip -9 %AllDone%\rc5*.log
	Del workdir\rc5*.log
	%Debug%
	Goto End        

:DAYADD 
	Rem This will take the day_* tables and add them to the tot_* tables.
	%Procdrive%
	Cd %Procdir%
	isql -U Bovine -P mookow5624 -n -w999 -S %SQL% < DY_REPORT.SQL | grep statsbox | cut -c2-999 | nc -w 2 ircmonitor.distributed.net 812
	%Debug%
	isql -U Bovine -P mookow5624 -e -p -S %SQL% < DY_APPEND.SQL
	%Debug%
	isql -U Bovine -P mookow5624 -e -p -S %SQL% < MAKE_DAILY_BLOCKS.SQL
	%Debug%
	Goto End

:DAYREPORT
	Rem This will take the day_* tables and add them to the tot_* tables.
	%Procdrive%
	Cd %Procdir%
	isql -U Bovine -P mookow5624 -n -w999 -S %SQL% < DY_REPORT.SQL | grep statsbox | cut -c2-999 | nc -w 2 ircmonitor.distributed.net 812
	%Debug%
	Goto End

:MAKERANK
	Rem This rebuilds the rankings tables.  (slooow)
	%Procdrive%
	Cd %Procdir%
	ISQL -U Bovine -P mookow5624 -e -p -S %SQL% < STRIP_HTML.SQL
	%Debug%
	ISQL -U Bovine -P mookow5624 -e -p -S %SQL% < EM_MAKERANK.SQL
	isql -U Bovine -P mookow5624 -n -w999 -S %SQL% < EM_REPORT.SQL | grep statsbox | cut -c2-999 | nc -w 2 ircmonitor.distributed.net 812
	%Debug%
	ISQL -U Bovine -P mookow5624 -e -p -S %SQL% < TM_MAKERANK.SQL
	isql -U Bovine -P mookow5624 -n -w999 -S %SQL% < TM_REPORT.SQL | grep statsbox | cut -c2-999 | nc -w 2 ircmonitor.distributed.net 812
	%Debug%
:MEMCRASH
	ISQL -U Bovine -P mookow5624 -e -p -S %SQL% < TM_MAKEMEMBERS.SQL
	isql -U Bovine -P mookow5624 -n -w999 -S %SQL% < MM_REPORT.SQL | grep statsbox | cut -c2-999 | nc -w 2 ircmonitor.distributed.net 812
	%Debug%
	Goto Emailnew

:EMAILNEW
	%Procdrive%
	Cd %Procdir%\Emails
	Echo @Echo Off > %Procdir%\Emails\NEWEMSET.BAT
	ISQL -U Bovine -P mookow5624 -w999 -S %SQL% < ..\NEWEMSET.SQL | grep @ | grep -v -f ..\greppat >> %Procdir%\Emails\NEWEMSET.BAT
	Echo Exit >> %Procdir%\Emails\NEWEMSET.BAT
	Start /MIN %Procdir%\Emails\NEWEMSET.BAT
	Goto End

:UPDCHARITY
	%Procdrive%
	Cd %Procdir%
	Del pc_money.idc
	WGET http://%StatsIP%/cgi/pc_money.idc
	copy pc_money.idc %WebRoot%\money.html
	Del pc_money.idc
	WGET http://rc5stats.distributed.net/money.html?
	Goto End


:UPDWEB
	Rem This creates the pre-calculated web pages
	%Procdrive%
	Cd %Procdir%
	Del pc_index.idc
	Del pc_emtop100.idc
	Del pc_emyst100.idc
	Del pc_tmtop100.idc
	Del pc_tmyst100.idc
	Del pc_cpulist.idc
	Del pc_oslist.idc
	Del pc_cpuosfull.idc
	Del pc_money.idc
	Del pc_problems.idc
	Del pc_teamlist.idc

	WGET http://%StatsIP%/cgi/pc_index.idc
	WGET http://%StatsIP%/cgi/pc_emtop100.idc
	WGET http://%StatsIP%/cgi/pc_emyst100.idc
	WGET http://%StatsIP%/cgi/pc_tmtop100.idc
	WGET http://%StatsIP%/cgi/pc_tmyst100.idc
	WGET http://%StatsIP%/cgi/pc_cpulist.idc
	WGET http://%StatsIP%/cgi/pc_oslist.idc
	WGET http://%StatsIP%/cgi/pc_cpuosfull.idc
	WGET http://%StatsIP%/cgi/pc_money.idc
	WGET http://%StatsIP%/cgi/pc_problems.idc
	WGET http://%StatsIP%/cgi/pc_teamlist.idc
	%Debug%

	copy pc_index.idc %WebRoot%\index.html
	copy pc_emtop100.idc %WebRoot%\emtop100.html
	copy pc_emyst100.idc %WebRoot%\emyst100.html
	copy pc_cpulist.idc %WebRoot%\cpulist.html
	copy pc_oslist.idc %WebRoot%\oslist.html
	copy pc_cpuosfull.idc %WebRoot%\cpuosfull.html
	copy pc_tmtop100.idc %WebRoot%\tm_top100.html
	copy pc_tmyst100.idc %WebRoot%\tm_yst100.html
	copy pc_money.idc %WebRoot%\money.html
	copy pc_problems.idc %WebRoot%\problems.html
	copy pc_teamlist.idc %WebRoot%\teamlist.html
	%Debug%
	
	Del pc_index.idc
	Del pc_emtop100.idc
	Del pc_emyst100.idc
	Del pc_tmtop100.idc
	Del pc_tmyst100.idc
	Del pc_cpulist.idc
	Del pc_oslist.idc
	Del pc_cpuosfull.idc
	Del pc_money.idc
	Del pc_problems.idc
	Del pc_teamlist.idc
	Goto End

:STATSON
	Rem This one will re-enable the stats server
	WGET http://eris.best.net:8064/mu-squid.cgi
	Del mu-*
	Rem This mails the log to anyone who cares
	type ldlog.txt >> ldlog.all
	del ldlog.txt
Rem	del nologs.lck
	NET START "FTP Publishing Service"
	del page*.cgi*
	Goto End

:PAGEBEGIN
	Rem Page Dave with stats started message
Rem	Start /min WGET "http://suburbia.slacker.com/cgi-bin/pagebegin.cgi"
	Goto End

:PAGEEND
	Rem Page Dave with stats done message
Rem	Start /min WGET "http://suburbia.slacker.com/cgi-bin/pageend.cgi"
	Goto End

:PAGEPANIC
	Rem Page Dave with stats started message
Rem	Start /min WGET "http://suburbia.slacker.com/cgi-bin/pagepanic.cgi"
	Goto End

:End
