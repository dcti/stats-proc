insert into RC5_64_daytable_master (timestamp, email, size)
select distinct convert(smalldatetime, convert(varchar(10),timestamp,101)) as timestamp, email, sum(size) as size
from import
group by convert(smalldatetime, convert(varchar(10),timestamp,101)), email
go

insert into RC5_64_daytable_platform (timestamp, cpu, os, ver, size)
select distinct convert(smalldatetime, convert(varchar(10),timestamp,101)) as timestamp, cpu, os, ver, sum(size) as size
from import
group by convert(smalldatetime, convert(varchar(10),timestamp,101)), cpu, os, ver
go

