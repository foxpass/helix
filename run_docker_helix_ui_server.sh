#!/bin/sh
ZKSRVR="${ZK:-host.docker.internal:2199}"
CLUSTER="${CNAME:-MYCLUSTER}"

./helix-front/target/helix-front-pkg/bin/start-helix-ui.sh &
./helix-rest/target/helix-rest-pkg/bin/run-rest-admin.sh --zkSvr $ZKSRVR --port 8100
