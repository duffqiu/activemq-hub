#!/bin/bash

if [ -z $ZK_NUM ]; then
  ZK_NUM=3 
fi

if [ -z $REPLIC_NUM ]; then
  REPLIC_NUM=0 
fi

if [ -z $REPLIC_PORT ]; then
  REPLIC_PORT=61719 
fi

let ZK_START=$ZK_NUM-1
ZK_STR="zookeeper-1:2181"

until [ $ZK_START -gt $ZK_NUM ]; do
  ZK_STR="$ZK_STR,zookeeper-$ZK_START:2181"
  let ZK_START+=1
done

echo "INFO: zookeeper string is $ZK_STR"

echo "INFO: building network broker config"


if [ -z $NODE_ID ]; then
  NODE_ID=1 
fi

#ROLE=0  (0:master, 1:slave 1, 2:slave2)
if [ -z $ROLE ]; then
  ROLE=0 
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
            uri="masterslave:(nio://core$NODE_START:$MASTER_PORT,nio://core$NODE_START-s1:$SLAVE1_PORT,nio://core$NODE_START-s2:$SLAVE2_PORT)"
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
            uri="masterslave:(nio://core$NODE_START:$MASTER_PORT,nio://core$NODE_START-s1:$SLAVE1_PORT,nio://core$NODE_START-s2:$SLAVE2_PORT)"
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
    sed -e "s:%leveldb.weight%:1:g" | \
    sed -e "s#%zk.str%#$ZK_STR#g" | \
    sed -e "s#%replic.num%#$REPLIC_NUM#g" | \
    sed -e "s#%replic.port%#$REPLIC_PORT#g" | \
    sed -e "s#%openwire.port%#$OPENWIRE_PORT#g" | \
    sed -e "/<networkConnectors>/r .nw.config" > \
    /activemq/conf/activemq.xml

rm -rf .nw.config

/activemq/bin/activemq console
