# activemq-hub
docker file for activemq to build a hub topology based on centos 7

### run a container with no data replicated only using leveldb for persistence

```
docker run -it --rm -p 61716:61716 -p 9161:8161  --dns=10.0.2.15 --dns-search=cluster.duffqiu.org duffqiu/activemq-hub
```

- note: must setup a dns and zookeeper before to run it
