#!/bin/bash

echo "run benchmark."


if test ! -f data/source.csv; then
    test -f data/source.csv.7z || exit 0

    7z e -odata data/source.csv.7z
fi

if test -f result/report.csv; then
    mv result/report.csv result/report_old.csv
fi

touch result/report.csv

echo "=>Tokyo Cabinet: B+ tree database(hidden features of the misc method)"
ruby tc_bdb.rb

echo "=> Tokyo Cabinet: table database"
ruby tc_table.rb

echo "=> mongodb: multi colls"
echo "flushing quotest1 database first"
ruby mongo_mcolls.rb

echo "=> mongodb: 1 coll with index"
echo "flushing quotest2 database first"
ruby mongo_index.rb

echo "=> redis"
echo "flush db #5"
ruby redis_list.rb

python plot.py
