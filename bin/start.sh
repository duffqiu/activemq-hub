#!/bin/bash

#ROLE=0  (0:master, 1:slave 1, 2:slave2)
if [ -z $ROLE ]; then
  ROLE=0 
fi

if [ -z $REPLIC_NUM ]; then
  REPLIC_NUM=0 
fi

if [ -z $BASE_REPLIC_PORT ]; then
  BASE_REPLIC_PORT=61719 
fi

let REPLIC_PORT=$BASE_REPLIC_PORT+$ROLE*10


if [ -z $ZK_STR ]; then
  ZK_STR="zookeeper-1:2181"
fi

if [ -z $REPLIC_WEIGHT ]; then
  REPLIC_WEIGHT=1
fi


echo "INFO: zookeeper string is $ZK_STR"


if [ -z $NODE_ID ]; then
  NODE_ID=1 
fi

if [ -z $BROKER_NAME ]; then
  BROKER_NAME="core$NODE_ID-$ROLE" 
fi

if [ -z $HUB_NUM ]; then
  HUB_NUM=1 
fi

if [ -z $BASE_PORT ]; then
  BASE_PORT=61716 
fi

NODE_START=1

let OPENWIRE_PORT=$BASE_PORT+$ROLE*10

let MASTER_PORT=$BASE_PORT
let SLAVE1_PORT=$MASTER_PORT+10
let SLAVE2_PORT=$SLAVE1_PORT+10

rm -rf nw.config

until [ $NODE_START -gt $HUB_NUM ]; do
  if [ $NODE_ID -ne $NODE_START ]; then
cat >> .nw.config << EOF
          <networkConnector
            name="topic-core$NODE_ID->core$NODE_START"
            uri="static:failover:(nio://core$NODE_START-0:$MASTER_PORT,nio://core$NODE_START-1:$SLAVE1_PORT,nio://core$NODE_START-2:$SLAVE2_PORT)?randomize=false"
            duplex="true"
            decreaseNetworkConsumerPriority="false"
            networkTTL="3"
            conduitSubscriptions="true"
            suppressDuplicateQueueSubscriptions="true"
            dynamicOnly="true">
            <excludedDestinations>
              <queue physicalName=">" />
            </excludedDestinations>
          </networkConnector>
          <networkConnector
            name="queue-core$NODE_ID->core$NODE_START"
            uri="static:failover:(nio://core$NODE_START-0:$MASTER_PORT,nio://core$NODE_START-1:$SLAVE1_PORT,nio://core$NODE_START-2:$SLAVE2_PORT)?randomize=false"
            duplex="true"
            decreaseNetworkConsumerPriority="false"
            networkTTL="3"
            conduitSubscriptions="true"
            suppressDuplicateQueueSubscriptions="true"
            dynamicOnly="true">
            <excludedDestinations>
              <topic physicalName=">" />
            </excludedDestinations>
          </networkConnector>
EOF

  fi

  let NODE_START+=1
done

cat /activemq/conf/activemq.xml.tmp | \
    sed -e "s:%node.id%:$NODE_ID:g" | \
    sed -e "s:%broker.name%:$BROKER_NAME:g" | \
    sed -e "s:%leveldb.weight%:$REPLIC_WEIGHT:g" | \
    sed -e "s#%zk.str%#$ZK_STR#g" | \
    sed -e "s#%replic.num%#$REPLIC_NUM#g" | \
    sed -e "s#%replic.port%#$REPLIC_PORT#g" | \
    sed -e "s#%openwire.port%#$OPENWIRE_PORT#g" | \
    sed -e "/<networkConnectors>/r .nw.config" > \
    /activemq/conf/activemq.xml

rm -rf .nw.config

/activemq/bin/activemq console
