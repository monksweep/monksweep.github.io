## 离线安装

### 一、下载地址

官网：https://nodejs.org/zh-cn/download/prebuilt-binaries

第三方镜像地址：https://nodejs.org/dist/v20.10.0/

第三方镜像地址：https://registry.npmmirror.com/binary.html?path=node/v20.10.0/

> `注意`:
>
> - Node.js需要C语言环境，所以需要gcc的支持，请检查系统是否安装gcc
>
>   ```bash
>   gcc -v
>   ```
>
> - 查看操作系统的glibc版本，从Node.js v18开始，需要 glibc2.27版本支持
>
>   ```bash
>   strings /lib64/libm.so.6 |grep GLIBC
>   ```
>
> 如需高版本（v18及以上）Node.js，请升级以上依赖。

### 二、解压安装

下载完成后，会获得安装包`node-v20.10.0-linux-x64.tar.gz`，将安装包丢到服务器上

```bash
[root@monksweep opt]# ls
node-v20.10.0-linux-x64.tar.gz
```

解压缩

```bash
[root@monksweep opt]# tar -zxvf node-v20.10.0-linux-x64.tar.gz
```

创建软连接，使得在任意目录下都可以直接使用node命令和npm命令

```bash
[root@monksweep opt]# ln -s /opt/node-v20.10.0-linux-x64/bin/node /usr/local/bin/node
[root@monksweep opt]# ln -s /opt/node-v20.10.0-linux-x64/bin/npm /usr/local/bin/npm
```

命令执行完成后，切换到`/usr/local/bin`目录，可以看到该目录下有两个文件

```bash
[root@monksweep opt]# cd /usr/local/bin/
[root@monksweep bin]# ll
lrwxrwxrwx. 1 root root 37 Oct 21 14:59 node -> /opt/node-v20.10.0-linux-x64/bin/node
lrwxrwxrwx. 1 root root 36 Oct 21 14:59 npm -> /opt/node-v20.10.0-linux-x64/bin/npm
```

### 三、配置环境变量

执行以下命令，编辑环境配置文件

```bash
vi /etc/profile
```

在文件底部增加以下两行命令

```bash
export NODE_HOME=/opt/node-v20.10.0-linux-x64/bin
export PATH=$PATH:$NODE_HOME:/usr/local/bin/
```

刷新配置文件，使更新立即生效

```bash
source /etc/profile
```

检查node及npm版本

```bash
node -v
npm -v
```

如果出现版本信息，则安装成功

