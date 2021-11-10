# Hadoop 集群搭建



> 翻译自：[https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)

## 目的

本文档描述了如何安装和配置 Hadoop 集群，从几个节点到数千节点的超大集群。要使用Hadoop，您可能首先需要将它安装在一台机器上（参见 [Single Node Setup](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html)）。

本文档不涉及安全（[Security](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SecureMode.html)）和高可用等高级话题。



## 先决条件

- 安装 Java。请参阅 [Hadoop Wiki](https://cwiki.apache.org/confluence/display/HADOOP/Hadoop+Java+Versions) 。
- 从 Apache 镜像下载一个稳定版本。



## 安装

安装 Hadoop 集群通常涉及在集群中的所有机器上解压缩软件，或者通过适合你的操作系统的打包系统安装软件。将硬件划分为功能是很重要的。

通常，集群中的一台机器被指定为 NameNode，另一台机器被指定为 ResourceManager。这些是 master。其他服务（如 Web 应用代理服务器和 MapReduce 作业历史服务器）通常运行在专用硬件或共享基础设施上，这取决于负载。



## 在非安全模式下配置 Hadoop

Hadoop 的 Java 配置由两种重要的配置文件决定：

- 只读默认配置 - `core-default.xml`，`hdfs-default.xml`，`yarn-default.xml` 和 `mapred-default.xml`。
- 特定网站配置 -  `etc/hadoop/core-site.xml`，`etc/hadoop/hdfs-site.xml`，`etc/hadoop/yarn-site.xml` 和 `etc/hadoop/mapred-site.xml`。

此外，你可以通过 `etc/hadoop/hadoop-env.sh` 和 `etc/hadoop/yarn-env.sh` 设置特定网站的值来控制发行版 bin/ 目录下的 Hadoop 脚本。

要配置 Hadoop 集群，您需要配置 Hadoop 守护进程执行的环境以及 Hadoop 守护进程的配置参数。

HDFS 的守护进程有 NameNode、SecondaryNameNode 和 DataNode。YARN 守护进程包括 ResourceManager、NodeManager 和 WebAppProxy。如果要使用 MapReduce，那么 MapReduce 作业历史记录服务器也将运行。对于大型安装，它们通常运行在独立的主机上。

### 配置 Hadoop 守护进程的环境

管理员应该使用 `etc/hadoop/hadoop-env.sh` 和可选的 `etc/hadoop/mapred-env.sh` 和 `etc/hadoop/yarn-env.sh` 脚本对 hadoop 守护进程的进程环境进行特定站点的定制。

至少，您必须指定 `JAVA_HOME`，以便在每个远程节点上正确地定义它。

管理员可以使用下表中所示的配置选项配置单个守护进程：

| Daemon                        | Environment Variable        |
| :---------------------------- | :-------------------------- |
| NameNode                      | HDFS_NAMENODE_OPTS          |
| DataNode                      | HDFS_DATANODE_OPTS          |
| Secondary NameNode            | HDFS_SECONDARYNAMENODE_OPTS |
| ResourceManager               | YARN_RESOURCEMANAGER_OPTS   |
| NodeManager                   | YARN_NODEMANAGER_OPTS       |
| WebAppProxy                   | YARN_PROXYSERVER_OPTS       |
| Map Reduce Job History Server | MAPRED_HISTORYSERVER_OPTS   |

例如，要配置 Namenode 使用 parallelGC 和4GB Java Heap，应该在 hadoop-env.sh 中添加以下语句:

```
export HDFS_NAMENODE_OPTS="-XX:+UseParallelGC -Xmx4g"
```

更多的例子请看 `etc/hadoop/hadoop-env.sh`

其它的你可以自定义的有用的参数包括：

- `HADOOP_PID_DIR` - 守护进程的进程id文件所在的目录。
- `HADOOP_LOG_DIR` - 存储守护进程日志文件的目录。如果不存在日志文件，则自动创建日志文件。
- `HADOOP_HEAPSIZE_MAX` - 用于 Java Heap 大小的最大内存量。这里也支持 JVM 支持的单元。如果没有单位存在，它将假定数字是兆字节。默认情况下，Hadoop 将让 JVM 决定使用多少。可以使用上面列出的适当的 `_OPTS` 变量在每个守护进程的基础上重写该值。例如，设置 `HADOOP_HEAPSIZE_MAX=1g` 和 `HADOOP_NAMENODE_OPTS="-Xmx5g"` 将为 NameNode 配置5GB Heap。

在大多数情况下，您应该指定 `HADOOP_PID_DIR` 和 `HADOOP_LOG_DIR` 目录，以便它们只能由将要运行 hadoop 守护进程的用户写入。否则就有可能发生符号链接攻击。

在系统范围的 shell 环境配置中配置 `HADOOP_HOME` 也是一种传统方式。例如，`/etc/profile.d` 中的一个简单脚本:

```bash
HADOOP_HOME=/path/to/hadoop
export HADOOP_HOME
```

### 配置 Hadoop 守护进程

本节讨论在给定的配置文件中指定的重要参数：

- `etc/hadoop/core-site.xml`

| 参数                  | 值           | 注意                                   |
| :-------------------- | :----------- | :------------------------------------- |
| `fs.defaultFS`        | NameNode URI | [hdfs://host:port/](hdfs://host:port/) |
| `io.file.buffer.size` | 131072       | 序列文件的读/写缓冲大小                |

- `etc/hadoop/hdfs-site.xml`
- NameNode 的配置：

| 参数                              | 值                                                         | 注意                                                         |
| :-------------------------------- | :--------------------------------------------------------- | :----------------------------------------------------------- |
| `dfs.namenode.name.dir`           | 本地文件系统上 NameNode 持久存储命名空间和事务日志的路径。 | 如果这是一个逗号分隔的目录列表，那么为了冗余，将在所有目录中复制名称表。 |
| `dfs.hosts` / `dfs.hosts.exclude` | 允许/不允许的 DataNode 列表                                | 如果必要，使用这些文件去控制允许的 DataNodes                 |
| `dfs.blocksize`                   | 268435456                                                  | 对于大文件系统，HDFS的块大小为256MB。                        |
| `dfs.namenode.handler.count`      | 100                                                        | 更多的 NameNode 服务器线程处理来自大量 DataNode 的rpc。      |

- DataNode 的配置：

| 参数                    | 值                                                      | 注意                                                         |
| :---------------------- | :------------------------------------------------------ | :----------------------------------------------------------- |
| `dfs.datanode.data.dir` | DataNode 的本地文件系统上存储块的以逗号分隔的路径列表。 | 如果这是一个以逗号分隔的目录列表，那么数据将存储在所有命名的目录中，通常是在不同的设备上。 |

- `etc/hadoop/yarn-site.xml`
- ResourceManager 和 NodeManager 的配置：

| 参数                          | 值               | 注意                                                         |
| :---------------------------- | :--------------- | :----------------------------------------------------------- |
| `yarn.acl.enable`             | `true` / `false` | 是否开启 ACLs，默认为false                                   |
| `yarn.admin.acl`              | Admin ACL        | ACL 用于在集群上设置管理员。ACLs是逗号用户分隔组。默认的特殊值是 * 意味着任何一个。特殊值空格意味着全都没有权限。 |
| `yarn.log-aggregation-enable` | *false*          | 开启或关闭聚合                                               |

- ResourceManager 的配置：

| 参数                                                         | 值                                                           | 注意                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| `yarn.resourcemanager.address`                               | `ResourceManager` 提交任务的客户端格式 host:port             | *host:port* 如果设置，将重写  `yarn.resourcemanager.hostname` 的主机名设置。 |
| `yarn.resourcemanager.scheduler.address`                     | `ResourceManager` ApplicationMaster 和 Scheduler 通信以获取资源的格式 host:port | *host:port* 如果设置，将重写  `yarn.resourcemanager.hostname` 的主机名设置。 |
| `yarn.resourcemanager.resource-tracker.address`              | `ResourceManager` NodeManager 的格式 host:port               | *host:port* 如果设置，将重写  `yarn.resourcemanager.hostname` 的主机名设置。 |
| `yarn.resourcemanager.admin.address`                         | `ResourceManager` 管理员命令格式 host:port                   | *host:port* 如果设置，将重写  `yarn.resourcemanager.hostname` 的主机名设置。 |
| `yarn.resourcemanager.webapp.address`                        | `ResourceManager` web-ui host:port.                          | *host:port* 如果设置，将重写  `yarn.resourcemanager.hostname` 的主机名设置。 |
| `yarn.resourcemanager.hostname`                              | `ResourceManager` 主机                                       | host 单个主机名，可以用来代替设置所有 `yarn.resourcemanager*address` 资源地址，用来设置 ResourceManager 组件的默认端口。 |
| `yarn.resourcemanager.scheduler.class`                       | `ResourceManager` 调度器类                                   | `CapacityScheduler` (推荐), `FairScheduler` (也推荐), or `FifoScheduler`. 使用完全限定类名，比如 `org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler`. |
| `yarn.scheduler.minimum-allocation-mb`                       | `ResourceManager`分配给每个容器的最小内存                    | 单位 MB                                                      |
| `yarn.scheduler.maximum-allocation-mb`                       | `ResourceManager`分配给每个容器的最大内存                    | 单位 MB                                                      |
| `yarn.resourcemanager.nodes.include-path` / `yarn.resourcemanager.nodes.exclude-path` | 允许/不允许的 NodeManager 列表                               | 如果必要, 这些文件将控制允许的 NodeManagers 列表             |

- NodeManager 配置：

| Parameter                                    | 值                                                 | 注意                                                         |
| :------------------------------------------- | :------------------------------------------------- | :----------------------------------------------------------- |
| `yarn.nodemanager.resource.memory-mb`        | 给定 NodeManager 的可用内存，以 MB 为单位          | 定义运行容器可以使用的 NodeManager 上的总可用资源            |
| `yarn.nodemanager.vmem-pmem-ratio`           | 任务的虚拟内存使用可能超过物理内存的最大比例       | 每个任务的虚拟内存使用可能超过其物理内存的限制。NodeManager上的任务使用的虚拟内存总量可能超过其物理内存使用量。 |
| `yarn.nodemanager.local-dirs`                | 写入中间数据的本地文件系统上以逗号分隔的路径列表。 | 多条路径有助于拓展磁盘。                                     |
| `yarn.nodemanager.log-dirs`                  | 以逗号分隔的日志写入本地文件系统上的路径列表。     | 多条路径有助于拓展磁盘。                                     |
| `yarn.nodemanager.log.retain-seconds`        | *10800*                                            | 在 NodeManager上保留日志文件的默认时间（以秒为单位）仅在禁用日志聚合时适用。 |
| `yarn.nodemanager.remote-app-log-dir`        | */logs*                                            | 在应用完成时，将应用日志移动到 HDFS 目录。需要设置适当的权限。仅在启用日志聚合时适用。 |
| `yarn.nodemanager.remote-app-log-dir-suffix` | *logs*                                             | 附加到远程日志目录的后缀。日志将被聚合到 ${yarn.nodemanager。remote-app-log-dir}/${user}/${thisParam} 仅在启用了日志聚合功能时有效。 |
| `yarn.nodemanager.aux-services`              | mapreduce_shuffle                                  | 需要为 MapReduce 应用程序设置的 Shuffle 服务。               |
| `yarn.nodemanager.env-whitelist`             | 容器从      NodeManager 继承的环境属性             | 对于mapreduce应用程序，除了默认值外，还应该添加HADOOP_MAPRED_HOME。属性值应该是 JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME |

- 历史服务器配置 (需要在其它地方移动):

| 参数                                                 | 值   | 注意                                                         |
| :--------------------------------------------------- | :--- | :----------------------------------------------------------- |
| `yarn.log-aggregation.retain-seconds`                | *-1* | 在删除聚合日志之前保留聚合日志的时间。-1禁用。请注意，将此值设置得太小，将向名称节点发送垃圾信息。 |
| `yarn.log-aggregation.retain-check-interval-seconds` | *-1* | 检查聚合日志保留的间隔时间。如果设置为0或负值，则该值将计算为聚合日志保留时间的十分之一。请注意，将此值设置得太小，将向名称节点发送垃圾信息。 |

- `etc/hadoop/mapred-site.xml`
- MapReduce 程序配置:

| 参数                                      | 值        | 注意                                             |
| :---------------------------------------- | :-------- | :----------------------------------------------- |
| `mapreduce.framework.name`                | yarn      | 执行框架设置为 Hadoop YARN                       |
| `mapreduce.map.memory.mb`                 | 1536      | 更大的 map 资源限制                              |
| `mapreduce.map.java.opts`                 | -Xmx1024M | 更大的 map 子 JVM Heap 大小                      |
| `mapreduce.reduce.memory.mb`              | 3072      | 更大的 reduce 资源限制                           |
| `mapreduce.reduce.java.opts`              | -Xmx2560M | 更大的 reduce 子 JVM Heap 大小                   |
| `mapreduce.task.io.sort.mb`               | 512       | 更高的内存限制以高效存储数据                     |
| `mapreduce.task.io.sort.factor`           | 100       | 在对文件进行排序时，会同时合并更多的流           |
| `mapreduce.reduce.shuffle.parallelcopies` | 50        | 运行更多的并行副本可以减少从大量映射中获取输出。 |

- MapReduce 历史服务器配置

| 参数                                         | 值                                      | 注意                                        |
| :------------------------------------------- | :-------------------------------------- | :------------------------------------------ |
| `mapreduce.jobhistory.address`               | MapReduce 历史服务器host:port*          | 默认端口是 10020.                           |
| `mapreduce.jobhistory.webapp.address`        | MapReduce 历史服务器 Web UI *host:port* | 默认端口是 19888.                           |
| `mapreduce.jobhistory.intermediate-done-dir` | /mr-history/tmp                         | MapReduce 任务写入历史文件的目录。          |
| `mapreduce.jobhistory.done-dir`              | /mr-history/done                        | 由 MR JobHistory Server管理历史文件的目录。 |



## 监测 NodeManager 的健康状况

Hadoop 提供了一种机制，管理员可以通过这种机制配置 NodeManager 来定期运行管理员提供的脚本，以确定节点是否健康。

管理员可以通过在脚本中执行他们选择的任何检查来确定节点是否处于健康状态。如果脚本检测到节点处于不健康状态，它必须在标准输出中打印以字符串 ERROR 开头的一行。NodeManager 定期生成脚本并检查其输出。如果脚本的输出包含字符串 ERROR（如上所述），则节点的状态将被报告为不健康状态，并被 ResourceManager 列入黑名单。不再向该节点分配任何任务。但是，NodeManager 会继续运行该脚本，因此如果该节点再次恢复健康，它将自动从 ResourceManager 上的黑名单节点中删除。管理员可以在 ResourceManager web 界面中查看节点的运行状况以及脚本的输出（如果它不正常）。web 界面上还显示节点处于正常运行状态的时间。

在 `etc/hadoop/yarn-site.xml` 中，以下参数可用于控制中的节点运行状况监控脚本：

| 参数                                                | 值                   | 注意                         |
| :-------------------------------------------------- | :------------------- | :--------------------------- |
| `yarn.nodemanager.health-checker.script.path`       | 节点健康脚本         | 检查节点健康状态的脚本       |
| `yarn.nodemanager.health-checker.script.opts`       | 节点健康脚本选项     | 检查节点健康状态的脚本的选项 |
| `yarn.nodemanager.health-checker.interval-ms`       | 节点健康脚本间隔     | 允许脚本的间隔               |
| `yarn.nodemanager.health-checker.script.timeout-ms` | 节点健康脚本超时间隔 | 健康脚本执行的超时时间       |

如果只有一些本地磁盘坏了，健康检查器脚本不应该给出 ERROR。NodeManager 能够定期检查本地磁盘的健康状况（特别是检查 NodeManager -local-dirs 和 NodeManager -log-dirs），并且在达到基于配置属性 yarn.nodemanager.disk-health-checker 设置的错误目录数量阈值之后。min-健康磁盘，整个节点被标记为不健康，此信息也发送到资源管理器。启动磁盘被突袭，或者运行状况检查程序脚本识别出启动磁盘中的故障。



## Slaves 文件

在你的 `/etc/hadoop/workers` 文件中列出所有 worker 的主机名，每行一个。帮助脚本（如下所述）将用 `etc/hadoop/workers`  文件在多个主机上同时运行命令。它不用于任何基于 Java 的 Hadoop 配置。为了使用此功能，必须为运行 Hadoop 的帐户建立 ssh 连接（ssh 免密登录或其他方式，如Kerberos）。



## Hadoop 机架感知

许多 Hadoop 组件都是感知机架的，并利用网络拓扑来提高性能和安全性。Hadoop 守护进程通过调用管理员配置的模块来获取集群中 wokers 的机架信息。有关更多具体信息，请参阅 [Rack Awareness](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/RackAwareness.html)。

强烈建议在启动 HDFS之 前配置机架感知。



## 操作 Hadoop 集群

完成所有必要的配置后，将这些文件分发到所有机器上的 `HADOOP_CONF_DIR` 目录。这应该是所有机器上的相同目录。

一般情况下，建议 HDFS 和 YARN 作为单独的用户运行。在大多数安装中，HDFS 进程以 HDFS 的形式执行。YARN 通常使用 YARN 帐户。

### 启动 Hadoop

为了启动 Hadoop 集群，你应该先启动 HDFS 和 YARN 集群

第一次打开 HDFS 时，必须对它进行格式化。格式化一个新的分布式文件系统为 hdfs：

```
[hdfs]$ $HADOOP_HOME/bin/hdfs namenode -format <cluster_name>
```

在指定的 HDFS 节点上，使用如下命令启动 HDFS NameNode：

```
[hdfs]$ $HADOOP_HOME/bin/hdfs --daemon start namenode
```

在每个 HDFS 节点上，使用如下命令启动 HDFS DataNode：

```
[hdfs]$ $HADOOP_HOME/bin/hdfs --daemon start datanode
```

如果所有的 workers 都配置了 ssh 免密登录（参阅 [Single Node Setup](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html)）所有的进程都可以用工具脚本启动：

```
[hdfs]$ $HADOOP_HOME/sbin/start-dfs.sh
```

在指定的 ResourceManager 上以 YARN 的形式运行，使用如下命令启动 YARN：

```
[yarn]$ $HADOOP_HOME/bin/yarn --daemon start resourcemanager
```

运行脚本在每个指定的主机上以 yarn 的形式启动 NodeManager：

```
[yarn]$ $HADOOP_HOME/bin/yarn --daemon start nodemanager
```

启动一个独立的 WebAppProxy 服务器。在 WebAppProxy 服务器上以 yarn 的形式运行。如果使用多个服务器进行负载平衡，则应该在每个服务器上运行：

```
[yarn]$ $HADOOP_HOME/bin/yarn --daemon start proxyserver
```

如果所有的 workers 都配置了 ssh 免密登录（参阅 [Single Node Setup](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html)）所有的进程都可以用工具脚本启动：

```
[yarn]$ $HADOOP_HOME/sbin/start-yarn.sh
```

使用如下命令启动 MapReduce JobHistory Server，在指定为 mapred 的服务器上运行：

```
[mapred]$ $HADOOP_HOME/bin/mapred --daemon start historyserver
```

### 关闭 Hadoop

停止 NameNode，在指定的 NameNode上执行如下命令：

```
[hdfs]$ $HADOOP_HOME/bin/hdfs --daemon stop namenode
```

运行脚本停止 DataNode：

```
[hdfs]$ $HADOOP_HOME/bin/hdfs --daemon stop datanode
```

如果所有的 workers 都配置了免密登录（参阅 [Single Node Setup](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html)）所有的进程都可以用工具脚本关闭：

```
[hdfs]$ $HADOOP_HOME/sbin/stop-dfs.sh
```

在指定的 ResourceManage r上以 yarn 运行，使用如下命令停止 ResourceManager：

```
[yarn]$ $HADOOP_HOME/bin/yarn --daemon stop resourcemanager
```

在 worker 上运行脚本停止 NodeManager：

```
[yarn]$ $HADOOP_HOME/bin/yarn --daemon stop nodemanager
```

如果所有的 workers 都配置了免密登录（参阅 [Single Node Setup](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html)）所有的进程都可以用工具脚本关闭：

```
[yarn]$ $HADOOP_HOME/sbin/stop-yarn.sh
```

停止 WebAppProxy 服务器。在 WebAppProxy 服务器上以 yarn 的形式运行。如果使用多个服务器进行负载平衡，则应该在每个服务器上运行：

```
[yarn]$ $HADOOP_HOME/bin/yarn stop proxyserver
```

使用如下命令停止 MapReduce JobHistory Server，在指定的服务器上以 mapred 运行：

```
[mapred]$ $HADOOP_HOME/bin/mapred --daemon stop historyserver
```



## Web 接口

一旦 Hadoop 集群启动并运行，检查组件的 web-ui，如下所述:

| 守护进程                    | Web 接口              | 注意                     |
| :-------------------------- | :-------------------- | :----------------------- |
| NameNode                    | http://nn_host:port/  | 默认 HTTP 端口 是 9870.  |
| ResourceManager             | http://rm_host:port/  | 默认 HTTP 端口 是 8088.  |
| MapReduce JobHistory Server | http://jhs_host:port/ | 默认 HTTP 端口 是 19888. |



> 翻译自：[https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)



-----

喜欢我的文章的话，欢迎`关注`👇`点赞`👇`评论`👇`收藏`👇	谢谢支持！！！

