#!/usr/bin/sqsh -i
#
# $Id: dy_importcount.sql,v 1.2 2000/04/13 14:58:16 bwilson Exp $
#
# Returns the number of rows in the import table
#
# Arguments:
#       Project
#
# Returns:
#	Number of rows in table

/* select count(*) from ${1}_import */
/* Output of number of rows is now returned from dy_integrate.sql */
# Prevent output of the header or footer
go -f -h
