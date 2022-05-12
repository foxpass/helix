#!/bin/sh
ZKSRVR="${ZK:-host.docker.internal:2199}"
CLUSTER="${CNAME:-MYCLUSTER}"
IP=`wget -qO- $ECS_CONTAINER_METADATA_URI_V4 | jq  '.Networks[0].IPv4Addresses[0]'`
SUBNET=`echo $IP | awk -F . '{print $3}'`
HELIX_API_ENDPOINT="${HELIX_API_ENDPOINT:-'http://helix-api.docker.internal:8100'}"

./helix-core/target/helix-core-pkg/bin/helix-admin.sh --zkSvr $ZKSRVR --addCluster $CLUSTER
./helix-core/target/helix-core-pkg/bin/run-helix-controller.sh --zkSvr $ZKSRVR --cluster $CLUSTER --mode DISTRIBUTED --controllerName helix-controller-$SUBNET 2>&1

POST_PARAM_1 <<- EOF
{
 "id" : "$CLUSTER",
  "simpleFields" : {
    "REBALANCE_MODE": "true",
    "allowParticipantAutoJoin": "true",
    "PERSIST_INTERMEDIATE_ASSIGNMENT": "true"
  },
  "listFields" : {
  },
  "mapFields" : {
  }
}
EOF

POST_PARAM_2 <<- EOF
{
  "id":"ldap_master",
  "simpleFields" : {
    "BUCKET_SIZE" : "0",
    "NUM_PARTITIONS" : "1",
    "REBALANCE_MODE" : "FULL_AUTO",
    "REBALANCE_STRATEGY" : "DEFAULT",
    "REPLICAS" : "1",
    "STATE_MODEL_DEF_REF" : "MasterSlave",
    "STATE_MODEL_FACTORY_NAME" : "DEFAULT"
  }
}
EOF

curl -X POST -H "Content-Type: application/json" $HELIX_API_ENDPOINT/admin/v2/clusters/$CLUSTER/configs\?command\=update -d $POST_PARAM_1
curl -X POST -H "Content-Type: application/json" $HELIX_API_ENDPOINT/admin/v2/clusters/$CLUSTER/resources/ldap_master\?command\=rebalance\&replicas\=1 -d $POST_PARAM_2
