#!/bin/bash
source ~/.bashrc
date >>./run_synapse_janitor.log
psql -Umatrix synapse < ./synapse_janitor.sql >>./run_synapse_janitor.log
ps -ef | grep 'synapse.app.' | grep -v grep | awk '{print "kill "$2}' | bash >/dev/null
