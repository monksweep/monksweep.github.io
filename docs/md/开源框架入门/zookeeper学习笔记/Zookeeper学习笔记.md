# Zookeeper学习笔记

## 1. Zookeeper入门

### 1.1 概述

`Zookeeper`是一个开源的**分布式**的，为分布式应用提供协调服务的Apache项目。

Zookeeper从设计模式角度来理解：是一个基于观察者模式设计的分布式服务管理框架，它**负责存储和管理大家都关心的数据**，然后**接受观察者的注册**，一旦这些数据的状态发生变化，Zookeeper就将**负责通知已经在Zookeeper上注册的那些观察者**做出相应的反应。

![image-20210305144033191](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305144033191.png)

### 1.2 特点

![image-20210305144140146](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305144140146.png)

1. Zookeeper：一个领导者（Leader），多个跟随者（Follower）组成的集群
2. <font color="red">集群中只要有半数以上节点存活，Zookeeper集群就能正常服务</font>

3. 全局数据一致：每个Server保存一份相同的数据副本，Client无论连接哪个Server，数据都是一致的
4. 更新请求顺序进行，来自同一个Client的更新请求按其发送顺序依次执行

5. 数据更新原子性，一次数据更新要么成功，要么失败
6. 实时性，在一定时间范围内，Client能读到最新数据

### 1.3 数据结构

Zookeeper数据模型的结构与**Unix文件系统很类似**，整体上可以看作是一棵树，每个节点称作一个ZNode。每一个ZNode默认能够存储**1MB**的数据，每个ZNode都可以**通过其路径唯一标识**。

<img src="Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305145613367.png" alt="image-20210305145613367" style="zoom:50%;" />

### 1.4 应用场景

提供的服务包括：统一命名服务、统一配置管理、统一集群管理、服务器节点动态上下线、软负载均衡等。

在分布式环境下，经常需要对应用/服务进行统一命名，便于识别。例如：IP不容易记住，而域名容易记住。

<img src="Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305150341279.png" alt="image-20210305150341279" style="zoom:25%;" />

- ==统一配置管理==

![image-20210305150859799](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305150859799.png)

- ==统一集群管理==

![image-20210305151306484](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305151306484.png)

- ==服务器动态上下线==

![image-20210305152541516](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305152541516.png)

- ==软负载均衡==

![image-20210305152846917](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305152846917.png)

### 1.5 下载地址

1. 官网首页

https://zookeeper.apache.org/

2. 下载版本

apache-zookeeper-3.6.2-bin.tar.gz

## 2. 安装

### 2.1 本地模式安装部署

1. 安装前准备

```markdown
# 1.安装JDK
# 2.拷贝安装包到linux目录下
# 3.解压到指定目录
[root@localhost opt]# tar -zxvf apache-zookeeper-3.6.2-bin.tar.gz
```

2. 配置修改

```markdown
# 1.将/opt/apache-zookeeper-3.6.2-bin/conf目录下的zoo_sample.cfg修改为zoo.cfg
[root@localhost conf]# cp zoo_sample.cfg zoo.cfg
# 2.在/opt/apache-zookeeper-3.6.2-bin/目录下创建zkData文件夹
[root@localhost apache-zookeeper-3.6.2-bin]# mkdir zkData
# 3.打开zoo.cfg文件，修改dataDir路径
dataDir=/opt/apache-zookeeper-3.6.2-bin/zkData
```

3. 操作Zookeeper

```markdown
# 1.启动服务端,进入/bin目录
[root@localhost bin]# sh zkServer.sh start
ZooKeeper JMX enabled by default
Using config: /opt/apache-zookeeper-3.6.2-bin/bin/../conf/zoo.cfg
Starting zookeeper ... STARTED
# 2.启动客户端
[root@localhost bin]# sh zkCli.sh
# 3.查看zookeeper状态
[root@localhost bin]# sh zkServer.sh status
```

### 2.2 配置参数解读

Zookeeper中的配置文件zoo.cfg中参数含义解读如下：

1. **tickTime =2000：通信心跳数，Zookeeper服务器与客户端心跳时间，单位毫秒**

   Zookeeper使用的基本时间，服务器之间或客户端与服务器之间维持心跳的时间间隔，也就是每个tickTime时间就会发送一个心跳，时间单位为毫秒。

   它用于心跳机制，并且设置最小的session超时时间为两倍心跳时间。(session的最小超时时间是2*tickTime)

2. **initLimit =10：LF 初始通信时限**

   集群中的Follower跟随者服务器与Leader领导者服务器之间初始连接时能容忍的最多心跳数(tickTime的数量)，用它来限定集群中的Zookeeper服务器连接到Leader的时限。

3.  **syncLimit =5：LF 同步通信时限**

   集群中Leader与Follower之间的最大响应时间单位，假如响应超过syncLimit * tickTime, Leader认为Follwer死掉，从服务器列表中删除Follwer。

4. **dataDir：数据文件目录+数据持久化路径**

   主要用于保存Zookeeper中的数据

## 3. Zookeeper内部原理

### 3.1 选举机制(重点)

1. <font color="red">半数机制：集群中半数以上机器存活，集群可用。所以Zookeeper适合安装奇数台服务器。</font>

2. Zookeeper虽然在配置文件中并没有指定**Master**和**Slave**。但是，Zookeeper工作时是有一个节点为Leader，其他则为Follower，Leader是通过内部的选举机制临时产生的。

3. 以一个简单的例子来说明整个选举的过程：

   假设有五台服务器组成的Zookeeper集群，它们的id从1-5，同时它们都是最新启动的，也就是没有历史数据，在存放数据量这一点上，都是一样的。假设这些服务器依序启动，来看看会发生什么，如图所示

   ![image-20210305172901655](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305172901655.png)

1）服务器1启动，此时只有它一台服务器启动了，它发出去的报文没有任何响应，所以它的选举状态一直是LOOKING状态。

2）服务器2启动，它与最开始启动的服务器1进行通信，互相交换自己的选举结果，由于两者都没有历史数据，所以id值较大的服务器2胜出，但是由于没有达到超过半数以上的服务器都同意选举它(这个例子中的半数以上是3)，所以服务器1、2还是继续保持LOOKING状态。

3）服务器3启动，根据前面的理论分析，服务器3成为服务器1、2、3中的老大，而与上面不同的是，此时有三台服务器选举了它，所以它成为了这次选举的Leader。

4）服务器4启动，根据前面的分析，理论上服务器4应该是服务器1、2、3、4中最大的，但是由于前面已经有半数以上的服务器选举了服务器3，所以它只能接收当小弟的命了。

5）服务器5启动，同4一样当小弟。

### 3.2 节点类型

![image-20210305174234055](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305174234055.png)

### 3.3 stat结构体

1. czxid-创建节点的事务zxid

   每次修改ZooKeeper状态都会收到一个zxid形式的时间戳，也就是ZooKeeper事务ID。

   事务ID是ZooKeeper中所有修改总的次序。每个修改都有唯一的zxid，如果zxid1小于zxid2，那么zxid1在zxid2之前发生。

2. ctime - znode被创建的毫秒数(从1970年开始)

3. mzxid - znode最后更新的事务zxid

4. mtime - znode最后修改的毫秒数(从1970年开始)

5. pZxid-znode最后更新的子节点zxid

6. cversion - znode子节点变化号，znode子节点修改次数

7. dataversion - znode数据变化号

8. aclVersion - znode访问控制列表的变化号

9. ephemeralOwner- 如果是临时节点，这个是znode拥有者的session id。如果不是临时节点则是0

10. <font color="red">dataLength- znode的数据长度</font>

11. <font color="red">numChildren - znode子节点数量</font>

### 3.4 监听器原理(面试重点)

![image-20210305174343616](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305174343616.png)

### 3.5 写数据流程

![image-20210305174426323](Zookeeper%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210305174426323.png)

## 4. Zookeeper实战(开发重点)

### 4.1 客户端命令行操作

| 命令基本语法     | 功能描述                                                     |
| ---------------- | ------------------------------------------------------------ |
| help             | 显示所有操作命令                                             |
| ls path [watch]  | 使用 ls 命令来查看当前znode中所包含的内容                    |
| ls2 path [watch] | 查看当前节点数据并能看到更新次数等数据                       |
| create           | 普通创建<br />-s  含有序列<br />-e  临时（重启或者超时消失） |
| get path [watch] | 获得节点的值                                                 |
| set              | 设置节点的具体值                                             |
| stat             | 查看节点状态                                                 |
| delete           | 删除节点                                                     |
| rmr              | 递归删除节点                                                 |

### 4.2 API应用

1. 创建一个Maven工程
2. 