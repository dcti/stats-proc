#!/bin/sh
#
# $Id: ogr_status_update.sh,v 1.1 2008/05/06 11:46:41 thejet Exp $
#
# Update OGR stubspace status pages

export PATH=$PATH:/usr/sbin

cd /htdocs

do_wget ( ) {
    if wget -O${2}.new "http://localhost/${1}"; then
        chmod 644 ${2}.new
        chown cvsup:www ${2}.new
        mv ${2} ${2}.old
        mv ${2}.new ${2}
        return
    else
        echo "Error fetching ${1}"
        return 1
    fi
}

get_project ( ) {
    do_wget misc/update_ogr_status.php?project_id=$1 cache/ogr_stubspace_status_$1.inc
    do_wget pc_index.php?project_id=$1 cache/index_$1.inc
}

if [ x$1 = x ]; then
    echo "Error! No projects specified"
    exit 1
else
    args=$@
fi

echo "Updating ogr stubspace status for projects $args"
echo

for project in $args; do
    get_project $project
done
