FROM duffqiu/dockerjdk7:latest
MAINTAINER duffqiu@gmail.com

RUN yum -y update

RUN yum -y install sed tar curl

RUN curl -LO http://mir2.ovh.net/ftp.apache.org/dist/activemq/5.11.1/apache-activemq-5.11.1-bin.tar.gz
RUN tar -xvzf apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz

RUN rm -rf apache-activemq-5.11.1-bin.tar.gz

RUN mv apache-activemq-5.11.1-bin.tar.gz /activemq

ADD bin/start.sh /activemq/bin/start.sh
RUN chmod +x /activemq/bin/start.sh

ADD conf/activemq.xml /activemq/conf/activemq.xml.tmp

ENV ZK_NUM=3 HUB_NUM=3


EXPOSE 61616 61619

WORKDIR /activemq

ENTRYPOINT [ "/activemq/bin/start.sh" ]
