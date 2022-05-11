#!/bin/sh
ZKSRVR="${ZK:-host.docker.internal:2199}"
CLUSTER="${CNAME:-MYCLUSTER}"

./helix-core/target/helix-core-pkg/bin/helix-admin.sh --zkSvr $ZKSRVR --addCluster $CLUSTER &
./helix-core/target/helix-core-pkg/bin/run-helix-controller.sh --zkSvr $ZKSRVR --cluster $CLUSTER 2>&1
