# activemq-hub
docker file for activemq to build a hub topology based on centos 7

### run a container

```
docker run -it --rm -e ROLE=0 -e ZK_STR=10.0.2.15:2181 -e REPLIC_NUM=2 -p 61719:61719 -p 61716:61716 --dns=10.0.2.15 --dns-search=cluster.duffqiu.org duffqiu/activemq-hub
```

- note: must setup a dns and zookeeper before to run it
- you can get dns from duffqiu/skydns2 and zookeeper from duffqiu/zookeeper
