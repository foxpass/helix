#!/bin/sh
ZKSRVR="${ZK:-host.docker.internal:2199}"
CLUSTER="${CNAME:-MYCLUSTER}"
IP=`wget -qO- $ECS_CONTAINER_METADATA_URI_V4 | jq  '.Networks[0].IPv4Addresses[0]'`
SUBNET=`echo $IP | awk -F . '{print $3}'`
HELIX_API_ENDPOINT="${HELIX_API_ENDPOINT:-'http://helix-api.docker.internal:8100'}"


./helix-core/target/helix-core-pkg/bin/helix-admin.sh --zkSvr $ZKSRVR --addCluster $CLUSTER
./helix-core/target/helix-core-pkg/bin/helix-admin.sh --zkSvr $ZKSRVR --setConfig CLUSTER $CLUSTER allowParticipantAutoJoin=true
./helix-core/target/helix-core-pkg/bin/helix-admin.sh --zkSvr $ZKSRVR --addResource $CLUSTER ldap_master 1 MasterSlave
./helix-core/target/helix-core-pkg/bin/helix-admin.sh --zkSvr $ZKSRVR --rebalance $CLUSTER  ldap_master 1
./helix-core/target/helix-core-pkg/bin/run-helix-controller.sh --zkSvr $ZKSRVR --cluster $CLUSTER --mode DISTRIBUTED --controllerName helix-controller-$SUBNET 2>&1
