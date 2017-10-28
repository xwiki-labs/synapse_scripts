#!/bin/bash

#exit;

source ~/.bashrc
cd ~/.synapse/
rm ./homeserver.log.* 2>/dev/null
rm ./synchrotron.log.* 2>/dev/null
export SYNAPSE_CACHE_FACTOR=1
(
    netstat -lnpt 2>/dev/null | grep -q 8008.*python && exit 0;
    ps -ef | awk '{ if ($0 ~ /synapse\.app\./) { print "kill "$2; } }' | bash
    /home/matrix/.synapse/bin/python2.7 -B -m synapse.app.homeserver --daemonize -c homeserver.yaml
)
(
    netstat -lnpt 2>/dev/null | grep -q 8083.*python && exit 0;
    /home/matrix/.synapse/bin/python2.7 -B -m synapse.app.synchrotron -c synchrotron_conf.yaml -c homeserver.yaml
)