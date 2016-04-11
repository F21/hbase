# HBase 1.1.4

FROM f21global/hadoop-base:2.7.1
MAINTAINER Francis Chuang <francis.chuang@boostport.com>

ENV HBASE_VER 1.1.4

RUN apt-get update \
    && apt-get install --no-install-recommends -y wget xmlstarlet hadoop-client \
    && mkdir -p /opt/hbase \
    && adduser --system --home /opt/hbase --disabled-login --ingroup hadoop hbase  \
    && wget -q -O - http://apache.mirror.digitalpacific.com.au/hbase/$HBASE_VER/hbase-$HBASE_VER-bin.tar.gz | tar -xzf - -C /opt/hbase  --strip-components 1 \
    && chown -R hbase:hadoop /opt/hbase