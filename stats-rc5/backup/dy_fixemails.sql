update RC5_64_daytable_master set email = 'rc5@distributed.net' where email not like '%%@%%'
go

update RC5_64_daytable_master set email = 'rc5@distributed.net' where email like '%%>%%' or email like '%%<%%'
go

