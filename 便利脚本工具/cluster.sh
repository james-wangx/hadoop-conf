#!/bin/bash

if [ $# -lt 1 ]
then
    echo "No Args Input..."
    exit ;
fi

case $1 in
    "start")
        echo " =============== 启动 hadoop集群 ========="
        
        echo " --------------- 启动 hdfs ---------------"
        ssh master "$HADOOP_HOME/sbin/start-dfs.sh"
        echo " --------------- 启动 yarn ---------------"
        ssh slave1 "$HADOOP_HOME/sbin/start-yarn.sh"
        echo " --------------- 启动 historyserver ------"
        ssh master "$HADOOP_HOME/bin/mapred --daemon start historyserver"
    ;;
    "stop")
        echo " =============== 关闭 hadoop集群 ========="
        
        echo " --------------- 关闭 historyserver ------"
        ssh master "$HADOOP_HOME/bin/mapred --daemon stop historyserver"
        echo " --------------- 关闭 yarn ---------------"
        ssh slave1 "$HADOOP_HOME/sbin/stop-yarn.sh"
        echo " --------------- 关闭 hdfs ---------------"
        ssh master "$HADOOP_HOME/sbin/stop-dfs.sh"
    ;;
    *)
        echo "Input Args Error..."
    ;;
esac