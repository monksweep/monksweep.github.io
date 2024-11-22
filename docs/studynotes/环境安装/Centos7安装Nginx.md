# Centos7安装Nginx



在CentOS系统上安装Nginx可以通过使用EPEL（Extra Packages for Enterprise Linux）仓库来完成。以下是安装Nginx的步骤：

1. 首先，确保您的系统已经安装了EPEL仓库。如果没有安装，可以使用以下命令安装EPEL仓库：

```bash
sudo yum install epel-release
```

2. 接下来，更新您的系统：

```bash
sudo yum update
```

3. 安装Nginx：

```bash
sudo yum install nginx
```

4. 启动Nginx服务：

```bash
sudo systemctl start nginx
```

5. （可选）设置Nginx开机自启：

```bash
sudo systemctl enable nginx
```

6. （可选）通过防火墙允许HTTP和HTTPS流量：

```bash
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
```

安装完成后，您可以通过访问服务器的IP地址或域名在Web浏览器中查看默认的Nginx欢迎页面。