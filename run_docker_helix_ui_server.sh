#!/bin/sh
ZKSRVR="${ZK:-host.docker.internal:2199}"
CLUSTER="${CNAME:-MYCLUSTER}"

./helix-front/target/helix-front-pkg/bin/start-helix-ui.sh
