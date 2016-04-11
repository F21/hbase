# HBase master

FROM f21global/hbase-base:1.1.4
MAINTAINER Francis Chuang <francis.chuang@boostport.com>

ADD run-master.sh /run-master.sh

EXPOSE 16010 16020 16030

CMD ["/run-master.sh"]