## 问题描述

本来想在Centos7上面使用yum安装软件（如git，nodejs等），但是发现报错：

```markdown
Could not retrieve mirrorlist http://mirrorlist.centos.org?arch=x86_64&release=7&repo=sclo-rh error was
14: curl#6 - "Could not resolve host: mirrorlist.centos.org; Unknown error"

 One of the configured repositories failed (Unknown),
 and yum doesn't have enough cached data to continue. At this point the only
 safe thing yum can do is fail. There are a few ways to work "fix" this:

// 省略中间部分...

Cannot find a valid baseurl for repo: centos-sclo-rh/x86_64
```



然后网上查找答案，让我更新yum，于是又报错：

```markdown
Loaded plugins: fastestmirror, refresh-packagekit, security
```

......



网上找了好多方案，给了许多命令，但不管执行啥命令，一直报这个错，折腾了好久。

后来自己研究了一下，最后总算是弄好了，记录一下。



## 解决方案

### 1. 查看当前yum的仓库

看返回的内容意思大概是`http://mirrorlist.centos.org`这个镜像地址访问不了，我们查看一下仓库里的镜像地址配置。

进入`/etc/yum.repos.d/`目录先查一下所有的仓库：

```bash
[root@monksweep yum.repos.d]# pwd
/etc/yum.repos.d
[root@monksweep yum.repos.d]# ll
total 56
-rw-r--r--. 1 root root 2534 Oct 23 17:38 CentOS-Base.repo
-rw-r--r--. 1 root root 1309 May 21 22:48 CentOS-CR.repo
-rw-r--r--. 1 root root  649 May 21 22:48 CentOS-Debuginfo.repo
-rw-r--r--. 1 root root  314 May 21 22:48 CentOS-fasttrack.repo
-rw-r--r--. 1 root root  630 May 21 22:48 CentOS-Media.repo
-rw-r--r--. 1 root root  998 Oct 23 11:06 CentOS-SCLo-scl.repo
-rw-r--r--. 1 root root  971 Oct 23 11:04 CentOS-SCLo-scl-rh.repo
-rw-r--r--. 1 root root 1331 May 21 22:48 CentOS-Sources.repo
-rw-r--r--. 1 root root 9454 May 21 22:48 CentOS-Vault.repo
-rw-r--r--. 1 root root  616 May 21 22:48 CentOS-x86_64-kernel.repo
-rw-r--r--. 1 root root  262 Oct 21 14:18 nodesource-nodejs.repo
-rw-r--r--. 1 root root  262 Oct 21 14:18 nodesource-nsolid.repo
```



> 这些文件都是 YUM（Yellowdog Updater Modified）仓库配置文件，用于定义不同的软件仓库及其相关的配置信息。每个文件通常对应一个特定的软件仓库或一组相关的仓库。以下是对这些文件的简要说明：
>
> - CentOS-Base.repo：这是 CentOS 基础仓库的配置文件，包含了主要的软件包源。
> - CentOS-CR.repo：这是 CentOS Continuous Release 仓库的配置文件，包含即将发布的更新包。
> - CentOS-Debuginfo.repo：这是 CentOS 调试信息仓库的配置文件，包含调试符号文件，用于调试目的。
> - CentOS-fasttrack.repo：这是 CentOS 快速通道仓库的配置文件，包含紧急更新包。
> - CentOS-Media.repo：这是 CentOS 安装介质仓库的配置文件，用于从安装介质（如 DVD）安装软件包。
> - CentOS-SCLo-scl.repo：这是 CentOS Software Collections (SCL) 仓库的配置文件，包含额外的软件集合。
> - CentOS-SCLo-scl-rh.repo：这是 CentOS Software Collections (SCL) Red Hat 兼容仓库的配置文件，包含 Red Hat 兼容的软件集合。
> - CentOS-Sources.repo：这是 CentOS 源代码仓库的配置文件，包含源代码包。
> - CentOS-Vault.repo：这是 CentOS 存档仓库的配置文件，包含旧版本的 CentOS 发行版。
> - CentOS-x86_64-kernel.repo：这是 CentOS 内核仓库的配置文件，包含内核相关的软件包。
> - nodesource-nodejs.repo 和 nodesource-nsolid.repo：这些是 Node.js 和 N|Solid 仓库的配置文件，包含 Node.js 相关的软件包。



然后查看仓库镜像地址的配置（我这里查看的是CentOS-SCLo-scl-rh.repo仓库）：

```bash
[root@monksweep yum.repos.d]# cat CentOS-SCLo-scl-rh.repo
# CentOS-SCLo-rh.repo
#
# Please see http://wiki.centos.org/SpecialInterestGroup/SCLo for more
# information

[centos-sclo-rh]
name=CentOS-7 - SCLo rh
#baseurl=http://mirror.centos.org/centos/7/sclo/$basearch/rh/
mirrorlist=http://mirrorlist.centos.org?arch=$basearch&release=7&repo=sclo-rh
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-testing]
name=CentOS-7 - SCLo rh Testing
baseurl=http://buildlogs.centos.org/centos/7/sclo/$basearch/rh/
gpgcheck=0
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-source]
name=CentOS-7 - SCLo rh Sources
baseurl=http://vault.centos.org/centos/7/sclo/Source/rh/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-debuginfo]
name=CentOS-7 - SCLo rh Debuginfo
baseurl=http://debuginfo.centos.org/centos/7/sclo/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
```



可以看到里面的镜像配置：

```bash
mirrorlist=http://mirrorlist.centos.org?arch=$basearch&release=7&repo=sclo-rh
```



发现就是这个配置访问不了，然后我又相继查看了其他仓库镜像，都是这个地址。说明问题就出在了镜像源上面，那么我们就修改一下镜像地址。



### 2. 修改为阿里的镜像源

说明：接下来主要是为了修改`CentOS-Base.repo`仓库的镜像地址



 备份原有的 yum 源配置文件： 

```bash
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
```



方式一：

如果当前操作系统有`wget`

```bash
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```



方式二：

如果没有`wget`，可以使用`curl`来下载：

```bash
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
```



执行完命令后，查看`CentOS-Base.repo`仓库里的镜像地址是否都变成了阿里的镜像源。

```bash
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/os/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/os/$basearch/
gpgcheck=1
#plugins=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#released updates 
[updates]
name=CentOS-$releasever - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/updates/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/extras/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/centosplus/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/centosplus/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
 
#contrib - packages by Centos Users
[contrib]
name=CentOS-$releasever - Contrib - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/contrib/$basearch/
        http://mirrors.aliyuncs.com/centos/$releasever/contrib/$basearch/
        http://mirrors.cloud.aliyuncs.com/centos/$releasever/contrib/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-
```



### 3. 禁用报错的仓库

yum会默认加载 `/etc/yum.repos.d/`目录下的所有 .repo 文件。具体哪些仓库会被启用取决于文件中的 [repository] 部分的 enabled 参数。如果 enabled = 1，则该仓库会被启用；如果 enabled = 0，则该仓库会被禁用。



找到镜像源配置为`mirrorlist=http://mirrorlist.centos.org`的，然后将其禁用。



禁用完后，可以使用以下命令查看当前启用的仓库：

```bash
yum repolist
```

这将列出所有启用的仓库及其状态。



重新执行yum install命令，发现可以正常使用。



至此，yum开头遇到的问题就都解决了。