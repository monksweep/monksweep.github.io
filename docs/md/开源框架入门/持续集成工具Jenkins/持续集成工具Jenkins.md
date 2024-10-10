# 持续集成工具Jenkins

## 1. 下载和安装

### 1. 1 下载

直接在官网下载war包 >>

![image-20210126163253942](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126163253942.png)

`下载地址`：https://www.jenkins.io/zh/download/

### 1.2 启动

```markdown
# 1.将下载好的war包上传到服务器/opt目录
	[root@localhost jenkins]# pwd
	/opt/jenkins
	[root@localhost jenkins]# ls
	jenkins.war 
# 2.执行启动命令（默认是8080端口，可以指定端口启动）
	> java -jar jenkins.war --httpPort=3917
# 3.注意修改的端口服务器有没有开放
```

首次启动会出现以下内容，这是登录的密码以及密码存放的地址（下次启动就不会展示这个信息了）

![image-20210126164209026](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126164209026.png)

### 1.3 安装向导

1. 在浏览器输入地址：http://localhost:3917/
2. 输入管理员密码使用
3. 安装推荐的插件
4. 使用admin账户继续
5. 进入首页

![image-20210126165019695](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126165019695.png)

## 2. 配置

### 2.1 全局安全配置

- 进入Manage Jenkins > Security > Configure Global Security
- 勾选允许用户注册，保存

### 2.2 全局工具配置

- 进入Manage Jenkins > System Configuration > Global Tool Configuration

- `修改maven配置`，使用文件系统中的settings文件

  1. 获取maven地址

  ```markdown
  [root@localhost jenkins]# echo $MAVEN_HOME
  /usr/local/apache-maven-3.6.3
  ```

  2. 最终路径：/usr/local/apache-maven-3.6.3/conf/settings.xml
  3. 两个配置路径都相同

![image-20210126180727948](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126180727948.png)

- `新增JDK`

  1. 随便取一个别名，必填项
  2. 取消勾选自动安装，获取jdk安装地址

  ```markdown
  [root@localhost jenkins]# echo $JAVA_HOME
  /usr/local/jdk1.8.0_261
  ```

![image-20210126171529991](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126171529991.png)

- `Maven`
  1. 随便取一个别名，必填项
  2. 取消勾选自动安装，获取maven安装地址

![image-20210126171752163](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126171752163.png)

- 保存

### 2.3 插件管理

- 进入Manage Jenkins > System Configuration > Manage Plugins
- 选择可选插件Tab页，搜索Deploy to container
- 勾选，直接安装

## 3. 构建项目配置

### 3.1 创建一个新任务

![image-20210126174703155](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126174703155.png)

### 3.2 源码管理

1. 选择Git填写仓库地址

![image-20210126175507827](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126175507827.png)

2. 添加Git的用户名和密码

![image-20210126175646648](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126175646648.png)

3. 选择添加的凭据和Git分支

![image-20210126180037624](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126180037624.png)

### 3.3 增加构建步骤

1. 选择构建环境Tab页

![image-20210126174110747](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210126174110747.png)

### 3.4 执行构建

1. 点击`立即构建`

2. 可以在构建进度里查看控制台信息
3. 构建完成后可以在目录中查看到

### 3.5 构建后操作

构建完成后可根据自己需求配置对应的操作：

比如在「构建」中「增加构建步骤」--->「执行Shell」

## 4. 构建触发器

### 4.1 触发远程构建

![image-20210201103936329](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210201103936329.png)

说明：

1. 身份验证令牌随便填
2. JENKINS_URL=http://ip:post/
3. 完整路径：http://ip:post/job/mbs-cost/build?token=MBSCOST_TOKEN

### 4.2 提交代码自动触发

1. Jenkins添加Gitlab Hook插件
2. 在GitLab中添加钩子

### 4.3 轮询SCM

![image-20210201110832056](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210201110832056.png)

每两分钟执行一次

> `轮询SCM`：定时检查源码变更（根据SCM软件的版本号），如果有更新就checkout最新code下来，然后执行构建动作。

### 4.4 定时构建

![image-20210201111601416](%E6%8C%81%E7%BB%AD%E9%9B%86%E6%88%90%E5%B7%A5%E5%85%B7Jenkins.assets/image-20210201111601416.png)

每5分钟执行一次构建