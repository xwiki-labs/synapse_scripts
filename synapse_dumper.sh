#!/bin/bash
source ~/.bashrc
pg_dump synapse | gzip -1 > ~/matrix.sql.gz.next
rm ~/matrix.sql.gz 2>>/dev/null
mv ~/matrix.sql.gz.next ~/matrix.sql.gz
