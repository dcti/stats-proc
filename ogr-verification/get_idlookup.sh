#! /bin/sh
# $Id: get_idlookup.sh,v 1.4 2003/07/20 23:29:59 nerf Exp $

TABLE=OGR_idlookup
FILENAME=/tmp/id_import.out
BCP=/usr/local/sybase/bin/bcp
SQLUSER=$1
SQLPASSWD=$2

if [ ${SQLPASSWD}foo = foo ]; then
  echo "$0: Not enough paramaters"
  exit 2
fi

sqsh -SBLOWER -U ${SQLUSER} -P ${SQLPASSWD} -D stats << EOF
	DELETE FROM ${TABLE};
	INSERT INTO ${TABLE}
	SELECT email, id,
		(retire_to*(sign(retire_to))+id*(1-sign(retire_to)))
			AS stats_id,
		retire_date,created
	FROM STATS_participant;
EOF

rm -f ${FILENAME} ${FILENAME}.new
${BCP} stats.dbo.${TABLE} out ${FILENAME} -c -S BLOWER -U ${SQLUSER} -P ${SQLPASSWD}
sed -e 's/\\/\\\\/g' < ${FILENAME} > ${FILENAME}.new &&
   mv ${FILENAME}.new ${FILENAME}
chmod 644 ${FILENAME}
