#!/bin/bash


DB=telegraf
DESTDB=telegrafyear
BACKFILL=true
CQS=$(  curl -s  -H "Accept: application/csv"  -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=SHOW CONTINUOUS QUERIES" | sed s/.*,,// | sed s/,.*// | grep -i auto_ )
for CQ in $CQS ;  do
 curl -s -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=DROP CONTINUOUS QUERY $CQ ON $DB" > /dev/null
done

curl -s -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=DROP DATABASE $DESTDB" > /dev/null
curl -s -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=CREATE DATABASE $DESTDB" > /dev/null
curl -s -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=CREATE RETENTION POLICY \"default\" ON \"$DESTDB\" DURATION 52w REPLICATION 1 SHARD DURATION 7d DEFAULT" > /dev/null

set -e

MEASUREMENTS=$(curl  -s -H "Accept: application/csv" -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=SHOW MEASUREMENTS on telegraf" | sed s/.*,// | tail -n +2 )

for M in $MEASUREMENTS ; do
 VALUES=$( curl -s -H "Accept: application/csv" -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=SHOW FIELD KEYS on telegraf from $M" | grep -v ,string | sed s/.*,,// | sed s/,.*//  | tail -n +2 )
 VALUESSETTER=""
 for V in $VALUES ; do
   VALUESSETTER="$VALUESSETTER mean(\"$V\") as \"$V\","
 done
 VALUESSETTER=$( echo $VALUESSETTER | sed s/,\$// )
 echo generating CQ for $M
 curl -s -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=CREATE CONTINUOUS QUERY auto_${DB}_${M} ON $DB BEGIN SELECT $VALUESSETTER INTO ${DESTDB}.\"default\".:MEASUREMENT FROM ${DB}.\"default\".${M} GROUP BY time(15m), * END"  > /dev/null
 if $BACKFILL ; then
  echo backfilling for $M
  curl -s -XPOST -G 'http://localhost:8086/query?pretty=true'  --data-urlencode "q=SELECT $VALUESSETTER INTO ${DESTDB}.\"default\".:MEASUREMENT FROM ${DB}.\"default\".${M} GROUP BY time(15m),*"  > /dev/null
 fi

done
