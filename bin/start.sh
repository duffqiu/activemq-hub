#!/bin/bash

#ZK_NUM=3

let ZK_START=$ZK_NUM-1
ZK_STR="zookeeper-1:2181"

until [ $ZK_START -gt $ZK_NUM ]; do
  ZK_STR="$ZK_STR,zookeeper-$ZK_START:2181"
  let ZK_START+=1
done

echo "INFO: zookeeper string is $ZK_STR"

echo "INFO: building network broker config"

#HUB_NUM=3
#NODE_ID=1
#BROKER_NAME="core1"
NODE_START=1
NW_BK_STR=""

rm -rf nw.config

until [ $NODE_START -gt $HUB_NUM ]; do
  if [ $NODE_ID -ne $NODE_START ]; then
cat >> .nw.config << EOF
          <networkConnector
            name="topic-core$NODE_ID->core$NODE_START"
            uri="masterslave:(nio://core$NODE_START:61616,nio://core$NODE_START-s1:61616,nio://core$NODE_START-s2:61616)"
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
            uri="masterslave:(nio://core$NODE_START:61616,nio://core$NODE_START-s1:61616,nio://core$NODE_START-s2:61616)"
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

cat ../conf/activemq.xml.tmp | \
    sed -e "s:%node.id%:$NODE_ID:g" | \
    sed -e "s:%broker.name%:$BROKER_NAME:g" | \
    sed -e "s:%leveldb.weight%:1:g" | \
    sed -e "s#%zk.str%#$ZK_STR#g" | \
    sed -e "/<networkConnectors>/r .nw.config" > \
    ../conf/activemq.xml

rm -rf .nw.config

./activemq console
