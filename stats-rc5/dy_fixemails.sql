# $Id: dy_fixemails.sql,v 1.1 1999/07/27 20:49:03 nugget Exp $

update RC5_64_daytable_master set email = 'rc5@distributed.net' where email not like '%%@%%'
go

update RC5_64_daytable_master set email = 'rc5@distributed.net' where email like '%%>%%' or email like '%%<%%'
go

