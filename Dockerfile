FROM openjdk:8-jdk-alpine
MAINTAINER Francis Chuang <francis.chuang@boostport.com>

ENV HBASE_VERSION=1.2.2 HBASE_CONF_DIR=/opt/hbase/conf

COPY hadoop-tools /tmp/hadoop-tools
COPY hadoop-config /opt/hbase/conf

RUN apk --no-cache --update add bash ca-certificates gnupg openssl su-exec tar \
 && apk --no-cache --update --repository https://dl-3.alpinelinux.org/alpine/edge/community/ add maven xmlstarlet \
 && update-ca-certificates \
\
# Set up directories
 && mkdir -p /opt/hbase \
 && mkdir -p /opt/hadoop \
\
# Download HBase
 && wget -O /tmp/KEYS https://www-us.apache.org/dist/hbase/KEYS \
 && gpg --import /tmp/KEYS \
 && wget -q -O /tmp/hbase.tar.gz http://apache.mirror.digitalpacific.com.au/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz \
 && wget -O /tmp/hbase.asc https://www-us.apache.org/dist/hbase/stable/hbase-$HBASE_VERSION-bin.tar.gz.asc \
 && gpg --verify /tmp/hbase.asc /tmp/hbase.tar.gz \
 && tar -xzf /tmp/hbase.tar.gz -C /opt/hbase  --strip-components 1 \
\
# Build hadoop fs
 && mkdir -p /tmp/hadoop-fs \
 && mv /tmp/hadoop-tools/fs-pom.xml /tmp/hadoop-fs/pom.xml \
 && mkdir -p /tmp/hadoop-fs/src/main/resources \
 && cp /opt/hbase/conf/core-site.xml /tmp/hadoop-fs/src/main/resources/core-site.xml \
 && cp /opt/hbase/conf/hdfs-site.xml /tmp/hadoop-fs/src/main/resources/hdfs-site.xml \
 && cd /tmp/hadoop-fs \
 && mvn clean package \
 && mv /tmp/hadoop-fs/target/hadoop-fs-1.0.jar /opt/hadoop/hdfs-fs.jar \
\
# Build hadoop dfsadmin
 && mkdir -p /tmp/hadoop-dfsadmin \
 && mv /tmp/hadoop-tools/dfsadmin-pom.xml /tmp/hadoop-dfsadmin/pom.xml \
 && mkdir -p /tmp/hadoop-dfsadmin/src/main/resources \
 && cp /opt/hbase/conf/core-site.xml /tmp/hadoop-dfsadmin/src/main/resources/core-site.xml \
 && cp /opt/hbase/conf/hdfs-site.xml /tmp/hadoop-dfsadmin/src/main/resources/hdfs-site.xml \
 && cd /tmp/hadoop-dfsadmin \
 && mvn clean package \
 && mv /tmp/hadoop-dfsadmin/target/hadoop-dfsadmin-1.0.jar /opt/hadoop/hdfs-dfsadmin.jar \
\
# Set up permissions
 && addgroup -S hadoop \
 && adduser -h /opt/hbase -G hadoop -S -D -H -s /bin/false -g hadoop hadoop \
 && chown -R hadoop:hadoop /opt/hbase \
 && chown -R hadoop:hadoop /opt/hadoop \
\
# Clean up
 && apk del gnupg maven openssl tar \
 && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ADD ["run-hbase.sh", "/"]
ADD ["roles", "/roles"]

EXPOSE 16010 16020 16030

CMD ["/run-hbase.sh"]