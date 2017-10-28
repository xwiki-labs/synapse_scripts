#!/bin/bash
source ~/.bashrc
psql -Umatrix synapse < ./synapse_janitor.sql
ps -ef | grep 'synapse.app.' | grep -v grep | awk '{print "kill "$2}'
