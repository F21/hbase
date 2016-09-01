#!/usr/bin/env bash

: ${HBASE_ROLE:?"HBASE_ROLE is required and should be master or regionserver."}

source roles/boostrap.sh

if [[ ${HBASE_ROLE,,} = master ]]; then
    # Create directory in hdfs if it doesn't exist
    java -jar /opt/hadoop/hdfs-fs.jar -conf $HBASE_CONF_DIR/hdfs-site.xml -test -d "hdfs://${HDFS_CLUSTER_NAME}/${CLUSTER_NAME}"

    if [ $? != 0 ]; then
        java -jar /opt/hadoop/hdfs-fs.jar -conf $HBASE_CONF_DIR/hdfs-site.xml -mkdir "hdfs://${HDFS_CLUSTER_NAME}/${CLUSTER_NAME}"
        java -jar /opt/hadoop/hdfs-fs.jar -conf $HBASE_CONF_DIR/hdfs-site.xml -chown hbase:hadoop "hdfs://${HDFS_CLUSTER_NAME}/${CLUSTER_NAME}"
    fi

    echo "Starting hbase master..."

    exec su-exec hbase /opt/hbase/bin/hbase --config /opt/hbase/conf master start

elif [[ ${HBASE_ROLE,,} = regionserver ]]; then
    echo "Starting hbase regionserver..."

    exec su-exec hbase /opt/hbase/bin/hbase --config /opt/hbase/conf regionserver start

else
    echo "HBASE_ROLE's value must be one of: master or regionserver"
    exit 1
fi