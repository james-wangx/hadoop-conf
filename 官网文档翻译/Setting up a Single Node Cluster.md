# Hadoop: Setting up a Single Node Cluster.



## 目的

此文档描述了如何搭建并配置 Hadoop 单节点安装，以便你可以用 Hadoop MapReduce 和 Hadoop Distributed File System (HDFS) 快速地执行简单的操作。



## 先决条件

### 平台支持

- GNU/Linux 可以支持开发和生产平台。Hadoop 已证实可以在 GNU/Linux 上部署2000个节点。
- Windows 同样也是支持的平台，但以下的步骤只适用于 Linux。若想在 Windows 上搭建Hadoop，请看 [wiki page](http://wiki.apache.org/hadoop/Hadoop2OnWindows)。

### 软件要求

Linux 平台需要的软件包括：

1. Java 必须安装。推荐的 Java 版本参考 [HadoopJavaVersions](https://cwiki.apache.org/confluence/display/HADOOP/Hadoop+Java+Versions)。
2. 如果要使用可选的启动和停止脚本，则必须安装 ssh 并运行 sshd 才能使用管理远程 Hadoop 守护进程的 Hadoop 脚本。另外，为了更好地管理 ssh 资源，建议也安装 pdsh。

### 安装软件

如果你的集群没有安装上述需要的软件，你需要安装它们。

比如在 Ubuntu Linux 上：

```
$ sudo apt-get install ssh
$ sudo apt-get install pdsh
```



## 下载

要获取 Hadoop 发行版，在 [Apache Download Mirrors](http://www.apache.org/dyn/closer.cgi/hadoop/common/) 中下载最新的稳定版本。



## 准备启动 Hadoop 集群

解压下载的 Hadoop 发行版。在发行版中，编辑 `/etc/hadoop/hadoop-env.sh` 文件定义如下一些参数：

```shell
# set to the root of your Java installation
export JAVA_HOME=/usr/java/latest
```

尝试如下命令：

```
bin/hadoop
```

这将会显示 hadoop 脚本是使用文档。

现在，你已经准备好以三种支持的模式之一启动 Hadoop 集群

- 本地（单机）模式
- 伪分布式
- 完全分布式



## 单机模式

默认地，Hadoop 被配置为非分布（non-distributed）模式，作为一个 Java 进程。这对调试很有帮助。

下面的示例复制未打包的 conf 目录作为输入，然后查找并显示给定正则表达式的每个匹配项。输出被写入给定的输出目录。

```
$ mkdir input
$ cp etc/hadoop/*.xml input
$ bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.1.jar grep input output 'dfs[a-z.]+'
$ cat output/*
```



## 伪分布式

Hadoop 还可以以伪分布式模式运行在单个节点上，其中每个 Hadoop 守护进程运行在单独的 Java 进程中。

### 配置

如下

`etc/hadoop/core-site.xml`:

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
```

`etc/hadoop/hdfs-site.xml`:

```xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
```

### ssh 免密登录

现在检查下你是否能用 ssh 免密登录 localhost

```
$ ssh localhost
```

如果你不能用 ssh 进行免密登录，执行以下命令：

```
$ ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
$ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
$ chmod 0600 ~/.ssh/authorized_keys
```

### 执行

下面的指令是在本地运行 MapReduce 作业。如果你想要在 YARN 上运行，请看 [YARN on Single Node](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html#YARN_on_a_Single_Node)。

1. 格式化文件系统：

   ```
   $ bin/hdfs namenode -format
   ```

2. 启动 NameNode 和 DataNode 守护进程：

   ```
   $ sbin/start-dfs.sh
   ```

   hadoop 守护进程的日志文件会被写入到 `$HADOOP_LOG_DIR` 目录（默认是 `$HADOOP_HOME/logs`）。

3. 浏览 NameNode 的 Web 界面；默认情况下是：

   - NameNode - `http://localhost:9870/`

4. 创建执行 MapReduce 任务所需的 HDFS 目录：

   ```
   $ bin/hdfs dfs -mkdir /user
   $ bin/hdfs dfs -mkdir /user/<username>
   ```

5. 复制输入文件到分布式文件系统：

   ```
   $ bin/hdfs dfs -mkdir input
   $ bin/hdfs dfs -put etc/hadoop/*.xml input
   ```

6. 运行提供的一些示例：

   ```
   $ bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.1.jar grep input output 'dfs[a-z.]+'
   ```

7. 检查输出文件：复制分布式文件系统文件到本地文件系统并检查：

   ```
   $ bin/hdfs dfs -get output output
   $ cat output/*
   ```

   或者

   在分布式文件系统上查看：

   ```
   $ bin/hdfs dfs -cat output/*
   ```

8. 当你搞定后，这样关闭守护进程：



## 单节点上运行YARN

通过设置一些参数，同时运行 ResourceManager 和 NodeManager 守护进程，可以在 YARN 上以伪分布式的方式运行 MapReduce 作业。

以下的命令假设上述命令的第1到4步已经执行。

1. 配置如下参数：

   `etc/hadoop/mapred-site.xml`:

   ```xml
   <configuration>
       <property>
           <name>mapreduce.framework.name</name>
           <value>yarn</value>
       </property>
       <property>
           <name>mapreduce.application.classpath</name>
           <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
       </property>
   </configuration>
   ```

   `etc/hadoop/yarn-site.xml`:

   ```xml
   <configuration>
       <property>
           <name>yarn.nodemanager.aux-services</name>
           <value>mapreduce_shuffle</value>
       </property>
       <property>
           <name>yarn.nodemanager.env-whitelist</name>
           <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
       </property>
   </configuration>
   ```

2. 启动 ResourceManager 和 NodeManager 守护进程

   ```
   $ sbin/start-yarn.sh
   ```

3. 浏览 ResourceManager 的 Web 界面；默认情况下是：

   - ResourceManager - `http://localhost:8088/`

4. 运行一个 MapReduce 任务。

5. 当你搞定了，这样关闭守护进程：

   ```
   $ sbin/stop-yarn.sh
   ```



## 完全分布式

有关搭建完全分布式非普通集群的信息，请查阅 [Cluster Setup](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)。

