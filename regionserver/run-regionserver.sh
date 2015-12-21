#!/usr/bin/env bash

CORE_SITE="/etc/hadoop/conf/core-site.xml"
HDFS_SITE="/etc/hadoop/conf/hdfs-site.xml"
HBASE_SITE="/opt/hbase/conf/hbase-site.xml"

addConfig () {

    if [ $# -ne 3 ]; then
        echo "There should be 3 arguments to addConfig: <file-to-modify.xml>, <property>, <value>"
        echo "Given: $@"
        exit 1
    fi

    xmlstarlet ed -L -s "/configuration" -t elem -n propertyTMP -v "" \
     -s "/configuration/propertyTMP" -t elem -n name -v $2 \
     -s "/configuration/propertyTMP" -t elem -n value -v $3 \
     -r "/configuration/propertyTMP" -v "property" \
     $1
}

ln -s $CORE_SITE /opt/hbase/conf/core-site.xml
ln -s $HDFS_SITE /opt/hbase/conf/hdfs-site.xml

# Update hbase-site.xml
: ${CLUSTER_NAME:?"CLUSTER_NAME is required."}
: ${HDFS_CLUSTER_NAME:?"HDFS_CLUSTER_NAME is required."}
addConfig $HBASE_SITE "hbase.rootdir" "hdfs://${HDFS_CLUSTER_NAME}/${CLUSTER_NAME}"
addConfig $HBASE_SITE "zookeeper.znode.parent" /$CLUSTER_NAME
addConfig $HBASE_SITE "hbase.cluster.distributed" "true"

: ${HBASE_ZOOKEEPER_QUORUM:?"HBASE_ZOOKEEPER_QUORUM is required."}
addConfig $HBASE_SITE "hbase.zookeeper.quorum" $HBASE_ZOOKEEPER_QUORUM

# Update core-site.xml
addConfig $CORE_SITE "fs.defaultFS" "hdfs://${HDFS_CLUSTER_NAME}"

# Update hdfs-site.xml
addConfig $HDFS_SITE "dfs.nameservices" $HDFS_CLUSTER_NAME
addConfig $HDFS_SITE "dfs.ha.namenodes.${HDFS_CLUSTER_NAME}" "nn1,nn2"

: ${DFS_NAMENODE_RPC_ADDRESS_NN1:?"DFS_NAMENODE_RPC_ADDRESS_NN1 is required."}
addConfig $HDFS_SITE "dfs.namenode.rpc-address.${HDFS_CLUSTER_NAME}.nn1" $DFS_NAMENODE_RPC_ADDRESS_NN1

: ${DFS_NAMENODE_RPC_ADDRESS_NN2:?"DFS_NAMENODE_RPC_ADDRESS_NN2 is required."}
addConfig $HDFS_SITE "dfs.namenode.rpc-address.${HDFS_CLUSTER_NAME}.nn2" $DFS_NAMENODE_RPC_ADDRESS_NN2

: ${DFS_NAMENODE_HTTP_ADDRESS_NN1:?"DFS_NAMENODE_HTTP_ADDRESS_NN1 is required."}
addConfig $HDFS_SITE "dfs.namenode.http-address.${HDFS_CLUSTER_NAME}.nn1" $DFS_NAMENODE_HTTP_ADDRESS_NN1

: ${DFS_NAMENODE_HTTP_ADDRESS_NN2:?"DFS_NAMENODE_HTTP_ADDRESS_NN2 is required."}
addConfig $HDFS_SITE "dfs.namenode.http-address.${HDFS_CLUSTER_NAME}.nn2" $DFS_NAMENODE_HTTP_ADDRESS_NN2

addConfig $HDFS_SITE "dfs.client.failover.proxy.provider.${HDFS_CLUSTER_NAME}" "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"

# Wait for hdfs cluster to be ready
until hdfs dfs -ls /; do
    echo "Waiting for hdfs to be available..."
    sleep 2
done

until hdfs dfsadmin -safemode wait; do
    echo "Waiting for hdfs to leave safemode"
    sleep 2
done

echo "Starting hbase regionserver..."

gosu hbase /opt/hbase/bin/hbase --config /opt/hbase/conf regionserver start
