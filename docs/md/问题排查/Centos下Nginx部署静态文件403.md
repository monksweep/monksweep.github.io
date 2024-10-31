# 记录一次Centos下Nginx部署静态文件403 Forbidden错误

## 一、环境说明

远程服务器：Centos7

Nginx版本：使用yum安装的1.20.1



我准备将本文档内容使用Nginx部署到服务器，配置如下：

```nginx
server {
  listen 80;
  server_name  localhost;

  location / {
    alias /data/gitee/work/docs/;
    index index.html;
  }
}
```

但是部署成功后，在客户端访问一直报错403 Forbidden，经过一顿排查，发现是`SELinux`的问题。



## 二、定位问题

可以通过查看日志确认是否是`SELinux`的问题。

```bash
sudo cat /var/log/audit/audit.log
```

我的日志如下：

```markdown
type=AVC msg=audit(1730281980.326:546): avc:  denied  { getattr } for  pid=1811 comm="nginx" path="/data/gitee/work/docs/index.html" dev="dm-0" ino=9862474 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:default_t:s0 tclass=file permissive=0
type=SYSCALL msg=audit(1730281980.326:546): arch=c000003e syscall=4 success=no exit=-13 a0=5624dc016a50 a1=7fff3a7bbad0 a2=7fff3a7bbad0 a3=5624d9dbe5d0 items=0 ppid=1809 pid=1811 auid=4294967295 uid=998 gid=996 euid=998 suid=998 fsuid=998 egid=996 sgid=996 fsgid=996 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)
type=PROCTITLE msg=audit(1730281980.326:546): proctitle=6E67696E783A20776F726B65722070726F63657373
```



由此可以断定是`SELinux`的问题。

## 三、解决方案

说明：如果是生产环境，不建议直接禁用SELinux，而是调整SELinux的策略！！！



### 1. 禁用SELinux

- 临时禁用

```bash
sudo setenforce 0
```

- 永久禁用

编辑 SELinux 配置文件来永久禁用它： 

```bash
sudo vi /etc/selinux/config
```

 将 `SELINUX=enforcing` 改为 `SELINUX=permissive` 或 `SELINUX=disabled`，然后重启系统。 

> 永久禁用后，如果想重新启用，只能修改配置文件重启系统；如果是临时禁用，重新启用的话只需将setenforce的值设置为1。

禁用后，就可以正常访问文档了。



### 2.  调整 SELinux 策略 

以下内容由AI生成，没有试过能否成功，仅供参考。

##### 2.1 使用 `audit2allow` 生成策略模块

你可以使用 `audit2allow` 工具来生成一个自定义的 SELinux 策略模块，以允许 Nginx 访问该目录和文件。

- **安装 `policycoreutils-python-utils`**:

  ```bash
  sudo yum install policycoreutils-python-utils
  ```

- **生成策略模块**: 将你的审计日志传递给 `audit2allow`：

  ```bash
  sudo grep nginx /var/log/audit/audit.log | audit2allow -M mynginx
  ```

  这将生成两个文件：`mynginx.te` 和 `mynginx.pp`。

- **加载策略模块**: 加载生成的策略模块：

  ```bash
  sudo semodule -i mynginx.pp
  ```

#####  2.2 手动设置文件上下文

如果你知道具体的文件或目录需要哪些 SELinux 上下文标签，可以手动设置这些标签。

- **查看当前文件上下文**:

  ```bash
  ls -Z /data/gitee/work/docs/index.html
  ```

- **设置正确的文件上下文**: 假设你需要将文件标记为 `httpd_sys_content_t`，这是 Nginx 默认用于静态内容的类型：

  ```bash
  sudo semanage fcontext -a -t httpd_sys_content_t "/data/gitee/work/docs(/.*)?"
  sudo restorecon -R /data/gitee/work/docs
  ```

  这会将 `/data/gitee/work/docs` 目录及其所有子目录和文件的 SELinux 类型设置为 `httpd_sys_content_t`。

##### 2.3 检查布尔值

确保相关的 SELinux 布尔值已启用。例如，如果 Nginx 需要访问其他非标准目录，可以启用以下布尔值：

- **允许 Nginx 访问用户家目录**:

  ```bash
  sudo setsebool -P httpd_enable_homedirs on
  ```

- **允许 Nginx 访问任意目录**:

  ```bash
  sudo setsebool -P httpd_unified on
  ```

- **允许 Nginx 访问网络**:

  ```bash
  sudo setsebool -P httpd_can_network_connect on
  ```

##### 2.4 重新启动 Nginx

完成上述步骤后，重新启动 Nginx 服务以应用更改：

```bash
sudo systemctl restart nginx
```

##### 2.5 验证

- **检查 Nginx 是否正常工作**: 访问你的 Nginx 服务器，确认是否仍然出现 403 错误。

- **检查 SELinux 日志**: 再次检查 SELinux 日志，确保没有新的 AVC（Access Vector Cache）拒绝记录：

  ```bash
sudo cat /var/log/audit/audit.log | audit2why
  ```

通过以上步骤，你应该能够在不关闭 SELinux 的情况下解决 Nginx 访问文件的问题。如果问题仍然存在，请提供更多的日志信息以便进一步诊断。



## 四、扩展

### 1. 什么是SELinux

SELinux（Security-Enhanced Linux）是一个安全模块，它为 Linux 内核提供了一种强制访问控制（MAC）机制。与传统的基于用户和组的访问控制不同，SELinux 通过定义详细的策略来控制进程对文件、网络端口和其他资源的访问。这提供了更细粒度的安全控制，有助于防止恶意软件和未经授权的访问。

### 2. SELinux 的工作原理

- **类型强制（Type Enforcement, TE）**: 这是 SELinux 的核心功能，它为系统中的每个进程和文件分配一个类型标签，并根据预定义的策略规则来控制它们之间的交互。
- **角色基础访问控制（Role-Based Access Control, RBAC）**: 允许管理员为用户和进程分配角色，进一步细化访问控制。
- **多级安全（Multi-Level Security, MLS）**: 提供了对敏感信息的分类和标记，通常用于高度安全的环境。

### 3. 关闭 SELinux 的影响

关闭 SELinux 会移除这些额外的安全层，可能会导致以下影响：

1. **安全性降低**:
   - 没有 SELinux 的强制访问控制，系统的安全性将依赖于传统的 Unix 权限和 ACL（访问控制列表），这可能不足以防御某些类型的攻击。
   - 如果你的系统中存在未被发现的安全漏洞，关闭 SELinux 可能会让攻击者更容易利用这些漏洞。
2. **合规性问题**:
   - 在某些受监管的环境中，如政府机构或金融机构，可能需要启用 SELinux 以符合安全标准和法规要求。关闭 SELinux 可能会导致不合规。
3. **性能影响**:
   - 虽然 SELinux 会在一定程度上增加系统开销，但现代硬件通常可以轻松处理这种开销。关闭 SELinux 不会对性能产生显著影响，除非在非常特定的情况下。
4. **应用程序兼容性**:
   - 有些应用程序可能没有正确配置 SELinux 策略，关闭 SELinux 可以解决这些问题。但在大多数情况下，正确的做法是调整 SELinux 策略以适应应用程序的需求。