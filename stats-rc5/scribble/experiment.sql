select distinct m.email as memail, s.email as semail
into mergedemails
from masteremails m, STATS_participant s
where m.email*=s.email and s.email = NULL
group by m.email, s.email
go
