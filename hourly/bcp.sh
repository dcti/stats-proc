#!/bin/sh
# $Id: bcp.sh,v 1.3 2005/05/10 20:59:53 nerf Exp $
database=$1
filename=$2
project=$3

if [ "${database}x" != "logdbx" ]
then
	cat $filename | psql -d $database -c "copy import_bcp FROM stdin DELIMITER ','"
else
	case "$project" in
		"ogr" )
		cat $filename | psql -d $database -c "copy import_ogr(return_time,ip_address,email,stub_marks,nodecount,os_type,cpu_type,version,status,project_id) FROM stdin DELIMITER ','"
		;;
		"r72" )
		cat $filename | psql -d $database -c "copy import_r72(return_time,ip_address,email,workunit_tid,iter,os_type,cpu_type,version,core,cmc_last,cmc_count,cmc_ok,project_id) FROM stdin DELIMITER ','"
		;;
		* )
		echo "ERROR:: No bcp handler for project $project"
		exit 100
	esac
fi
