#!/bin/sh
PASS=
BDAY=3

[ ! -d "/mongo/data/mongo_back" ] && mkdir "/mongo/data/mongo_back"

cd "/mongo/data/mongo_back"
/usr/local/bin/mongodump $PASS -o "$(date +%F)" 2>/dev/null
tar czf "$(date +%F)".tar.gz "$(date +%F)"
rm -rf "$(date +%F)"

#Retains the most recent 3-day backup
find "/mongo/data/mongo_back/" -mtime +$BDAY -type f -name "*.tar.gz" -exec \rm {} \; 2>/dev/null
