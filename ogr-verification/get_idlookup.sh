#! /bin/sh
# $Id: get_idlookup.sh,v 1.1 2003/02/16 22:56:04 nerf Exp $

TABLE=Nerf_id_lookup
FILENAME=/tmp/id_import.out
BCP=/usr/local/sybase/bin/bcp
USER=$1
PASSWORD=$2

if [ ${PASSWORD}foo = foo ]; then
  echo "Not enough paramaters"
  exit 2
fi

sqsh -SBLOWER -U ${USER} -P ${PASSWORD} -D stats << EOF
	DELETE FROM ${TABLE};
	INSERT INTO ${TABLE}
	SELECT email, id,
		(retire_to*(sign(retire_to))+id*(1-sign(retire_to)))
			AS stats_id
	FROM STATS_participant;
EOF

rm -f ${FILENAME}
${BCP} stats.dbo.${TABLE} out ${FILENAME} -c -S BLOWER -U ${USER} -P ${PASSWORD}
sed -e 's/\\/\\\\/g' < ${FILENAME} > ${FILENAME}.new &&
   mv ${FILENAME}.new ${FILENAME}
chmod 644 ${FILENAME}
