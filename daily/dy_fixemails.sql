#!/usr/bin/sqsh -i
#
# $Id: dy_fixemails.sql,v 1.1 2000/02/09 16:13:57 nugget Exp $
#
# Sets invalid email addresses to 'rc5@distributed.net'
#
# Arguments:
#       Project

update ${1}_daytable_master set email = 'rc5@distributed.net' where email not like '%%@%%'
go

update ${1}_daytable_master set email = 'rc5@distributed.net' where email like '%%>%%' or email like '%%<%%'
go

