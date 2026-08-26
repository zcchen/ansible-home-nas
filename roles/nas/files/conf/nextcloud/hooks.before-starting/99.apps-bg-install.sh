#!/usr/bin/env bash

cd /var/www/html/

nohup bash -c 'for f in $(ls -1 $(dirname `realpath $0`)/99.apps-bg-install/*.sh); do echo ">>> exec script <$f> in backgroud..."; $f; echo ">>> All background jobs done, return <$?>"; done' $0 2>&1 1>/tmp/99.apps-bg-install.log &
pid=$!
echo ">>> background running job, pid: $pid"
