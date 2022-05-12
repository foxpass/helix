#!/bin/sh
ZKSRVR="${ZK:-host.docker.internal:2199}"
CLUSTER="${CNAME:-MYCLUSTER}"

./helix-rest/target/helix-rest-pkg/bin/run-rest-admin.sh --zkSvr $ZKSRVR --port 8100