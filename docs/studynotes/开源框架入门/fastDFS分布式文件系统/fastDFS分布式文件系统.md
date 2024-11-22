# fastDFS分布式文件系统

## 1. 引言

### 1.1 技术应用场景

当一个网站中存在大量的图片，视频，文档等文件时，往往会碰见很多问题，比如大量文件如何高效存储，用户量太大如何保证下载速度？

分布式文件系统解决了`海量文件存储及传输访问的瓶颈问题`，对海量视频、图片的管理等。

### 1.2 文件系统

`文件系统`是负责管理和存储文件的系统`软件`，操作系统通过文件系统提供的接口去存取文件，用户通过操作系统访问磁盘上的文件。

常见的文件系统：FAT16/FAT32、NTFS、HSF、UFS、APFS、XFS、Ext4等。

### 1.3 分布式文件系统

为什么会有分布式文件系统？

​	`分布式文件系统`是面对互联网的需求而产生，互联网时代对海量数据如何存储？靠简单的增加硬盘个数已经满足不了我们的要求，因为硬盘传输速度有限但是数据在急剧增长，另外我们还要做好数据备份、数据安全等。

​	采用分布式文件系统可以将多个地点的文件系统通过网络连接起来，组成一个文件系统网络，节点之间通过网络进行通信，一台文件系统的存储和传输能力有限，我们让文件在多台计算机上存储，通过多台计算机共同传输。

<img src="fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20210312140040247.png" alt="image-20210312140040247" style="zoom:80%;" />

好处：

1. 一台计算机的文件系统处理能力扩充到多台计算机同时处理
2. 一台计算机挂了还有另外副本计算机提供数据
3. 每台计算机可以放在不同的区域，这样用户就可以就近访问，提高访问速度

### 1.3 主流的分布式文件系统

- NFS

`NFS`(Network File System)即`网络文件系统`，是FreeBSD支持的文件系统中的一种，它允许网络中的计算机之间通过TCP/IP网络共享资源。在NFS的应用中，本地NFS的客户端应用可以透明地读写位于远端NFS服务器上的文件，就像访问本地文件一样。

![image-20210312141203311](fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20210312141203311.png)

1. 在客户端上映射NFS服务器的驱动器
2. 客户端通过网络访问NFS服务器的硬盘完全透明

- GFS

`GFS`（googleFs）是一个可扩展的分布式文件系统，用于大型的、分布式的、对大量数据进行访问的应用。它运行于廉价的普通硬件上，可以提供容错功能。它可以给大量的用户提供总体性能较高的服务。

![gfs](fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/gfs.png)

1. GFS采用主从结构，一个GFS集群由一个master和大量的chunkserver组成
2. master存储了数据文件的元数据，一个文件被分成了若干块存储在多个chunkserver中
3. 用户从master中获取数据元信息，从chunkserver存储数据

- HDFS

`Hadoop分布式文件系统`(HDFS)被设计成适合运行在通用硬件上的分布式文件系统。它和现有的分布式文件系统有很多共同点。但同时，它和其他的分布式文件系统的区别也是很明显的。HDFS是一个高度容错性的系统，适合部署在廉价的机器上。HDFS能提供高吞吐量的数据访问，非常适合大规模数据集上的应用。HDFS放宽了一部分POSIX约束，来实现流式读取文件系统数据的目的。HDFS在最开始是作为Apache Nutch搜索引擎项目的基础架构而开发的。HDFS是Apache Hadoop Core项目的一部分。

<img src="fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/format,f_auto.gif" alt="img" style="zoom:80%;" />

1. HDFS采用主从结构，一个HDFS集群由一个名称节点和若干数据节点组成。名称节点存储数据的元信息，一个完整的数据文件分成若干块存储在数据节点。
2. 客户端从名称节点获取数据的元信息及数据分块的信息，得到信息客户端即可从数据块来存取数据。

### 1.4 分布式文件服务提供商

- 阿里的OSS
- 七牛云存储
- 百度云存储

## 2. fastDFS

### 2.1 fastDFS介绍

`FastDFS`是用c语言编写的一款开源的分布式文件系统，它是由淘宝资深架构师余庆编写并开源。FastDFS专为互联网量身定制，充分考虑了冗余备份、负载均衡、线性扩容等机制，并注重高可用、高性能等指标。使用FastDFS很容易搭建一套高性能的文件服务器集群提供文件上传、下载等服务。

为什么要使用fastDFS呢？

上边介绍的NFS、GFS都是通用的分布式文件系统。通用的分布式文件系统的优点的是开发体验好，但是系统复杂性高、性能一般，而专用的分布式文件系统虽然开发体验性差，但是系统复杂性低并且性能高。fastDFS非常适合存储图片等那些`小文件`，`fastDFS不对文件进行分块，所以它就没有分块合并的开销`，fastDFS网络通信采用socket，通信速度很快。

### 2.2 fastDFS工作原理

#### 2.2.1 fastDFS架构

fastDFS架构包括Tracker server和Storage server。客户端请求Tracker server进行文件上传、下载，通过Tracker server调度最终由Storage server完成文件上传和下载。

<img src="fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20210312144714952.png" alt="image-20210312144714952" style="zoom:80%;" />

#### 2.2.2 文件上传流程

![image-20210312144831507](fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20210312144831507.png)

客户端上传文件后存储服务盟将文件ID返回给客户端，此文件ID用于以后访问该文件的索引信息。文件索引信息包括：组名，虚拟磁盘路径，数据两级目录，文件名。

![image-20210312145026785](fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20210312145026785.png)

- 组名：文件上传后所在的storage组名称，在文件上传成功后有storage服务器返回，需要客户端自行保存。
- 虚拟磁盘路径：storage配置的虚拟路径，与磁盘选项store_path*对应。如果配置了store_path0则是M00，如果配置了store_path1则是M01 , 以此类推。
- 数据两级目录：storage服务器在每个虚拟磁盘路径下创建的两级目录，用于存储数据文件。
- 文件名：与文件上传时不同。是由存储服务器根据特定信息生成，文件名包含：源存储服务器IP地址、文件创建时间戳、文件大小、随机数和文件拓展名等信息。

#### 2.2.3 文件下载流程

![image-20210312150205248](fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20210312150205248.png)

tracker根据请求的文件路径即文件ID来快速定义文件。

比如请求下面的文件：

![image-20210312145026785](fastDFS%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20210312145026785.png)

1. 通过组名tracker能够很快的定位到客户端需要访问的存储服务器组是group1，并选择合适的存储服务器提供客户端访问。
2. 存储服务器根据“文件存储虚拟磁盘路径”和“数据文件两级目录”可以很快定位到文件所在目录，并根据文件名找到客户端需要访问的文件。

## 3. fastDFS安装与配置

### 3.1 安装libfastcommon

1. 获取libfastcommon安装包

   地址：https://github.com/happyfish100/libfastcommon/releases

2. 解压安装包：tar -zxvf libfastcommon-1.0.48.tar.gz

3. 进入目录：cd libfastcommon-1.0.48

4. 执行编译：./make.sh

5. 安装：./make.sh install

```sh
[root@localhost fastdfs]# ls
libfastcommon-1.0.48.tar.gz
[root@localhost fastdfs]# tar -zxvf libfastcommon-1.0.48.tar.gz
[root@localhost fastdfs]# cd libfastcommon-1.0.48
[root@localhost libfastcommon-1.0.48]# ls
doc  HISTORY  INSTALL  libfastcommon.spec  LICENSE  make.sh  php-fastcommon  README  src
[root@localhost libfastcommon-1.0.48]# ./make.sh 
[root@localhost libfastcommon-1.0.48]# ./make.sh install
```

### 3.2 安装FastDFS

1. 获取fastDFS安装包

   地址：https://github.com/happyfish100/fastdfs/releases

2. 解压安装包：tar -zxvf fastdfs-6.07.tar.gz

3. 进入目录：cd fastdfs-6.07

4. 执行编译：./make.sh

5. 安装：./make.sh install

```sh
[root@localhost fastdfs]# ls
fastdfs-6.07.tar.gz
[root@localhost fastdfs]# tar -zxvf fastdfs-6.07.tar.gz
[root@localhost fastdfs]# cd fastdfs-6.07
[root@localhost fastdfs-6.07]# ./make.sh 
[root@localhost fastdfs-6.07]# ./make.sh install
[root@localhost fastdfs-6.07]# ls -la /usr/bin/fdfs*
-rwxr-xr-x. 1 root root  369344 Mar 11 16:19 /usr/bin/fdfs_appender_test
-rwxr-xr-x. 1 root root  369120 Mar 11 16:19 /usr/bin/fdfs_appender_test1
-rwxr-xr-x. 1 root root  356040 Mar 11 16:19 /usr/bin/fdfs_append_file
-rwxr-xr-x. 1 root root  355464 Mar 11 16:19 /usr/bin/fdfs_crc32
-rwxr-xr-x. 1 root root  356096 Mar 11 16:19 /usr/bin/fdfs_delete_file
-rwxr-xr-x. 1 root root  356832 Mar 11 16:19 /usr/bin/fdfs_download_file
-rwxr-xr-x. 1 root root  356760 Mar 11 16:19 /usr/bin/fdfs_file_info
-rwxr-xr-x. 1 root root  376448 Mar 11 16:19 /usr/bin/fdfs_monitor
-rwxr-xr-x. 1 root root  356320 Mar 11 16:19 /usr/bin/fdfs_regenerate_filename
-rwxr-xr-x. 1 root root 1297488 Mar 11 16:19 /usr/bin/fdfs_storaged
-rwxr-xr-x. 1 root root  379248 Mar 11 16:19 /usr/bin/fdfs_test
-rwxr-xr-x. 1 root root  378464 Mar 11 16:19 /usr/bin/fdfs_test1
-rwxr-xr-x. 1 root root  522464 Mar 11 16:19 /usr/bin/fdfs_trackerd
-rwxr-xr-x. 1 root root  357024 Mar 11 16:19 /usr/bin/fdfs_upload_appender
-rwxr-xr-x. 1 root root  358048 Mar 11 16:19 /usr/bin/fdfs_upload_file
```

### 3.3 配置Tracker服务

1. 进入/etc/fdfs目录，有四个.sample后缀的文件，拷贝tracker.conf.sample并删除后缀

```sh
[root@localhost fastdfs-6.07]# cd /etc/fdfs/
[root@localhost fdfs]# ls
client.conf.sample  storage.conf.sample  storage_ids.conf.sample  tracker.conf.sample
[root@localhost fdfs]# cp tracker.conf.sample tracker.conf
```

2. 编辑tracker.conf：vi tracker.conf，修改相关参数

```markdown
# tracker存储data和log的根路径，必须提前创建好
base_path = /home/wangyg/fastdfs/tracker
```

3. 启动tracker（支持start|stop|restart）

```sh
[root@localhost fdfs]# /usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf start
```

### 3.4 配置Storage服务

1. 进入/etc/fdfs目录，拷贝storage.conf.sample并删除后缀
2. 编辑storage.conf：vi storage.conf，修改相关参数：

```markdown
# storage存储data和log的根路径，必须提前创建好
base_path = /home/wangyg/fastdfs/storage
group_name=group1  #默认组名，根据实际情况修改
store_path_count=1  #存储路径个数，需要和store_path个数匹配
store_path0=/home/wangyg/fastdfs/storage  #如果为空，则使用base_path
tracker_server=172.16.11.109:22122 #配置该storage监听的tracker的ip和port
```

3. 启动storage（支持start|stop|restart）

```sh
[root@localhost fdfs]# /usr/bin/fdfs_storaged /etc/fdfs/storage.conf start
```

### 3.5 在Storage上安装Nginx

在storage server上安装nginx的目的是对外通过http访问storage server上的文件。

使用nginx的模块FastDFS-nginx-module的作用是**通过http方式访问storage中的文件，当storage本机没有要找的文件时向源storage主机代理请求文件**。

所以说，nginx这块的安装和fastDFS本身没有关系，不要混淆。

地址：https://github.com/happyfish100/fastdfs-nginx-module

## 4. 测试环境搭建

### 4.1 文件上传

1. 新建一个maven工程，导入fastDFS依赖

```markdown
<dependency>
  <groupId>net.oschina.zcx7878</groupId>
  <artifactId>fastdfs-client-java</artifactId>
  <version>1.27.0.0</version>
</dependency>
```

2. 新建配置文件fastdfs-client.properties

```yaml
# http连接超时时间
fastdfs.connect_timeout_in_seconds=5
# tracker与stroage网络通信超时时间
fastdfs.network_timeout_in_seconds=30
fastdfs.charset=UTF-8
fastdfs.tracker_servers=172.16.11.109:22122
```

详细配置可参考官方文档：

https://github.com/happyfish100/fastdfs-client-java/blob/master/README.md

3. 新建一个测试类

```java
public static void main(String[] args) throws Exception{
  // 加载配置文件
  ClientGlobal.initByProperties("fastdfs-client.properties");
  // 定义trackerClient，用于请求TrackerServer
  TrackerClient trackerClient = new TrackerClient();
  // 连接tracker
  TrackerServer trackerServer = trackerClient.getConnection();
  // 获取storage
  StorageServer storeStorage = trackerClient.getStoreStorage(trackerServer);
  // 创建storageClient
  StorageClient1 storageClient1 = new StorageClient1(trackerServer, storeStorage);
  // 上传文件路径
  String uploadFilePath = "/Users/wangyg/file/test.docx";
  // 上传成功后拿到文件id
  String fileId = storageClient1.upload_file1(uploadFilePath, "docx", null);
  System.out.println(fileId);
}
```

执行成功后可以在控制台看到打印的文件ID：

```sh
group1/M00/00/00/rBALbWBK3oeAXQK8ACtcP-PRzzY66.docx
```

根据上面store_path0配置的路径下可以找到上传的文件。

