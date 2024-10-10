# Spring Cloud Alibaba Nacos学习笔记

## 1. 简介

### 1.1 Spring Cloud Alibaba是什么？

​	Spring Cloud Alibaba是阿里巴巴集团下的开源组件和云产品在Spring Cloud规范下的实现。2018年10月31日，Spring Cloud Alibaba正式入驻Spring Cloud官方孵化器，并发布了第一个预览版本。2019年8月1日在Alibaba仓库发布第一个毕业版本。

​	Spring Cloud Ablibaba主要为微服务开发提供一站式的解决方案，使开发者通过Spring Cloud编程模型轻松的解决微服务架构下的各类技术问题。

`官网地址`：https://spring.io/projects/spring-cloud-alibaba#overview

`github地址`：https://github.com/alibaba/spring-cloud-alibaba/blob/master/README-zh.md

### 1.2 主要功能

- `服务限流降级`：默认支持 WebServlet、WebFlux, OpenFeign、RestTemplate、Spring Cloud Gateway, Zuul, Dubbo 和 RocketMQ 限流降级功能的接入，可以在运行时通过控制台实时修改限流降级规则，还支持查看限流降级 Metrics 监控。
- `服务注册于发现`：适配 Spring Cloud 服务注册与发现标准，默认集成了 Ribbon 的支持。
- `分布式配置管理`：支持分布式系统中的外部化配置，配置更改时自动刷新。
- `消息驱动能力`：基于 Spring Cloud Stream 为微服务应用构建消息驱动能力。
- `分布式事务`：使用 @GlobalTransactional 注解， 高效并且对业务零侵入地解决分布式事务问题。
- `阿里云对象存储`：阿里云提供的海量、安全、低成本、高可靠的云存储服务。支持在任何应用、任何时间、任何地点存储和访问任意类型的数据。
- `分布式任务调度`：提供秒级、精准、高可靠、高可用的定时（基于 Cron 表达式）任务调度服务。同时提供分布式的任务执行模型，如网格任务。网格任务支持海量子任务均匀分配到所有 Worker（schedulerx-client）上执行。
- `阿里云短信服务`：覆盖全球的短信服务，友好、高效、智能的互联化通讯能力，帮助企业迅速搭建客户触达通道。

## 2. Nacos的基本使用

### 2.1 Nacos的简介和下载

​	`Nacos`(Dynamic Naming and Configuration Service) 致力于解决微服务中的统一配置、服务注册与发现等问题。它提供了一组简单易用的特性集，帮助开发者快速实现动态服务发现、服务配置、服务元数据及流量管理。

![image-20201221162341761](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201221162341761.png)

> Nacos = Eureka + Config + Bus

`下载地址`：https://github.com/alibaba/nacos/releases

### 2.2 Nacos的安装

```markdown
# 1.将下载的安装包放到/opt目录并解压
	> sudo tar -zxvf nacos-server-1.4.0.tar.gz
# 2.运行bin目录下的startup.sh
	> sudo sh startup.sh -m standalone
# 3.启动完成后访问http://127.0.0.1:8848/nacos
	默认用户名/密码：nacos/nacos
```

> Nacos依赖Java环境，并且要求使用JDK1.8以上版本。

### 2.3 Nacos集成Spring Boot实现服务注册与发现

- 新建一个Spring Boot工程cloudalibaba-provider-payment，作为服务提供者。

- 修改pom文件，添加mvn依赖。

  ```markdown
  <dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
  </dependency>
  ```

- 在application.yml文件中添加以下配置。

  ```yaml
  server:
    port: 9001
  spring:
    application:
      name: nacos-payment-provider
    cloud:
      nacos:
        discovery:
          server-addr: localhost:8848
  management:
    endpoints:
      web:
        exposure:
          include: '*'
  ```

- 创建PaymentController类，添加以下业务代码，用来做测试，非Nacos配置。

  ```java
  @RestController
  public class PaymentController {
      @Value("${server.port}")
      private String serverPort;
  
      @GetMapping(value = "/payment/nacos/{id}")
      public String getPayment(@PathVariable("id") Integer id) {
          return "nacos registry, serverPort:" + serverPort + "\t id:" + id;
      }
  }
  ```

- 运行主启动类PaymentApp。

  ```java
  @SpringBootApplication
  @EnableDiscoveryClient
  public class PaymentApp {
      public static void main(String[] args) {
          SpringApplication.run(PaymentApp.class, args);
      }
  }
  ```

- 回到Nacos控制台，可以看到已经注册到服务列表

  ![image-20201221181322903](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201221181322903.png)

### 2.4 Nacos的负载均衡

> Nacos自带`负载均衡`，原因是Nacos依赖中集成了Ribbon。

- 参照上述步骤，克隆一份端口为9002的项目作为另一个服务提供者，用于演示负载均衡。

- 新建Spring Boot工程cloudalibaba-consumer-nacos-order，用来做服务消费者。

- 修改pom文件，添加以下依赖，与服务提供方一致。

  ```markdown
  <dependency>
  	<groupId>com.alibaba.cloud</groupId>
  	<artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
  </dependency>
  ```

- 修改application.yml文件，添加以下配置

  ```yaml
  server:
    port: 83
  spring:
    application:
      name: nacos-order-consumer
    cloud:
      nacos:
        discovery:
          server-addr: localhost:8848
  
  # 消费者将要去访问的微服务名称(注册成功到nacos的微服务提供者)
  # 非Nacos配置
  service-url:
    nacos-user-service: http://nacos-payment-provider
  ```

- 创建OrderController类，添加如下业务代码，用于测试。

  ```java
  @RestController
  public class OrderController {
      @Resource
      private RestTemplate restTemplate;
  
      @Value("${service-url.nacos-user-service}")
      private String serviceURL;
  
      @GetMapping(value = "/consumer/payment/nacos/{id}")
      public String paymentInfo(@PathVariable("id") Integer id) {
          return restTemplate.getForObject(
                  serviceURL + "/payment/nacos/" + id, 
                  String.class);
      }
  }
  ```

- 创建JavaConfig类，将RestTemplate注入Spring容器。

  ```java
  @Configuration
  public class ApplicationContextConfig {
  
  	@Bean
  	@LoadBalanced
  	public RestTemplate restTemplate(){
  		return new RestTemplate();
  	}
  }
  ```

- 运行主启动类OrderNacosApp及两个服务提供者9001/9002。

  ```java
  @EnableDiscoveryClient
  @SpringBootApplication
  public class OrderNacosApp {
      public static void main(String[] args) {
          SpringApplication.run(OrderNacosApp.class, args);
      }
  }
  ```
  
- 负载均衡效果演示。

  ![ef2f5f74-8372-4d18-b21d-7f937a84c170](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/ef2f5f74-8372-4d18-b21d-7f937a84c170.gif)
## 3. 使用Nacos做服务配置中心

### 3.1 项目准备及基本配置

首先创建一个基于Spring Boot的项目，并集成Nacos配置中心。

- 创建一个工程cloudalibaba-config-nacos-client。

- 添加Nacos Config相关mvn依赖。

  ```markdown
  <dependency>
  	<groupId>com.alibaba.cloud</groupId>
  	<artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
  </dependency>
  ```

- 在application.yml中添加如下配置。

  ```yaml
  spring:
    profiles:
      active: dev # 表示开发环境
  ```

- 在bootstrap.yml中添加如下配置。

  ```yaml
  server:
    port: 3377
  spring:
    application:
      name: nacos-config-client
    cloud:
      nacos:
        discovery:
          # Nacos作为服务注册中心地址
          server-addr: localhost:8848
        config:
          # Nacos作为服务配置中心地址
          server-addr: localhost:8848
          file-extension: yaml
  ```

- 创建ConfigClientController类，用于从Nacos Server获取动态配置。

  ```java
  @RestController
  @RefreshScope // 支持Nacos的动态刷新功能
  public class ConfigClientController {
      @Value("${config.info}")
      private String configInfo;
  
      @GetMapping("/config/info")
      public String getConfigInfo(){
          return configInfo;
      }
  }
  ```

- 进入Nacos控制台，“配置管理” -> “配置列表” ->点击**“+”**创建配置。

  ![image-20201222113633312](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222113633312.png)

> `DataID规则`：${spring.application.name}-${spring.profiles.active}.${spring.cloud.nacos.config.file-extension}

- 启动服务并测试。

  ```java
  @SpringBootApplication
  @EnableDiscoveryClient
  public class ConfigClientApp {
      public static void main(String[] args) {
          SpringApplication.run(ConfigClientApp.class, args);
      }
  }
  ```

  执行以下命令

  ```markdown
  curl http://localhost:3377/config/info
  ```

  可以获得如下返回结果

  ```markdown
  config info for dev,from nacos config center.
  ```

> `Nacos Config自带动态刷新`:在控制台修改配置值，重新请求会获得最新的结果。

### 3.2 Nacos Config的分类配置

Nacos提供了解决多环境多项目的方案，使用Namespace+Group+Data ID来区分。默认情况下：Namespace=public，Group=DEFAULT_GROUP，Cluster是DEFALUT。

<img src="Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/1561217857314-95ab332c-acfb-40b2-957a-aae26c2b5d71-8633735.jpeg" alt="1561217857314-95ab332c-acfb-40b2-957a-aae26c2b5d71" style="zoom:50%;" />

```markdown
# Namespace 命名空间
	Namespace用于解决多环境多租户数据的隔离问题。在不同的Namespace下，可以存在相同的Group或DataId。
# Group 组
	Group是Nacos中用来实现Data ID分组管理的机制。对于Group的用法，没有固定的规定，比如它可以实现不同环境下的DataId的分组，也可以实现不同应用或组件下使用相同配置类型的分组，比如database_url。
# Data ID 配置集ID
	Data ID是Nacos中某个配置集的ID，它通常用于组织划分系统的配置集。比如通过配置文件名字来进行划分，或者通过Java包的全路径来划分，主要取决于Data ID的使用纬度。
```

> 官方的建议是，通过Namespace来区分不同的环境，而Group可以专注在业务层面的数据分组。

#### 3.2.1 Data ID方案

`目的`：指定spring.profile.active和配置文件的DataID来使不同环境下读取不同配置。

- 新建一个Data ID名称为nacos-config-client-test.yaml的配置文件。

  ![image-20201222150635071](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222150635071.png)

- 修改3377的application.yaml配置，切换环境。

  ```yaml
  spring:
    profiles:
      #active: dev # 表示开发环境
      active: test # 表示测试环境
  ```

- 重启3377服务，执行以下命令。

  ```markdown
  curl http://localhost:3377/config/info
  ```

  可以获得如下返回结果。

  ```markdown
  config info for test,from nacos config center. version=1
  ```

#### 3.2.2 Group方案

`目的`：测试Group的分组管理机制

- 新建一个名为TEST_GROUP组的配置。

  ![image-20201222152240582](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222152240582.png)

- 再新建一个名为DEV_GROUP组的配置。

  ![image-20201222152645283](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222152645283.png)

- 当前状态：相同Namespace，相同配置文件，不同组

  <img src="Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222153638506.png" alt="image-20201222153638506" style="zoom:50%;" />

- 在bootstrap.yml下增加一条group的配置，配置为两个组的任意一组皆可。

  ```yaml
  spring:
    cloud:
      nacos:
        config:
         	file-extension: yaml
          group: DEV_GROUP
  ```

  切换application.yml的环境为info。

  ```yaml
  spring:
    profiles:
      active: info
  ```

- 重启服务，执行以下命令。

  ```markdown
  curl http://localhost:3377/config/info
  ```

  可以获得如下返回结果。

  ```markdown
  nacos-config-client-info.yaml,DEV_GROUP,version=1
  ```

#### 3.2.3 Namespace方案

`目的`：使用Namespace实现多环境管理

- 新建dev/test的命名空间。

  ![image-20201222154859523](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222154859523.png)

- 在test命名空间新建一个与public命名空间内相同的配置文件nacos-config-client-test.yaml。

  ![image-20201222160025361](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222160025361.png)

- 在bootstrap.yml中添加namespace，group配置。

  ```yaml
  spring:
    cloud:
      nacos:
        config:
         	file-extension: yaml
          group: TEST_GROUP
          namespace: fee9915c-0cb2-463f-b5ab-d19e200a4ca2
  ```

  切换application.yml的环境为test。

  ```yaml
  spring:
    profiles:
      active: test
  ```

- 重启服务，执行以下命令。

  ```markdown
  curl http://localhost:3377/config/info
  ```

  可以获得如下返回结果。

  ```markdown
  from test namespace,nacos-config-client-test.yaml,TEST_GROUP
  ```

## 4. Nacos集群和持久化配置

<img src="Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/1561258986171-4ddec33c-a632-4ec3-bfff-7ef4ffc33fb9-8634536.jpeg" alt="1561258986171-4ddec33c-a632-4ec3-bfff-7ef4ffc33fb9" style="zoom:50%;" />

### 4.1 安装环境要求

- 64 bit OS Linux/UNIX/Mac，推荐使用Linux系统
- 64 bit JDK 1.8及以上，下载并配置。
- Maven 3.2.x及以上，下载并配置。
- 3个或3个以上Nacos节点才能构成集群。
- MySQL数据库5.6.5及以上。

### 4.2 Nacos集群配置

​	在Nacos的conf目录下包含以下文件。

- `application.properties`：Spring Boot项目默认的配置文件。
- `cluster.conf.example`：集群配置样例文件。
- `nacos-mysql.sql`：MySQL数据库脚本。Nacos支持Derby和MySQL两种持久化机制，默认采用Derby数据库。如果采用MySQL，需要运行该脚本创建数据库和表。
- `nacos-logback.xml`：Nacos日志配置文件。

#### 4.2.1 配置MySQL数据库

- 新建nacos-config库，将配置文件中的nacos-mysql.sql在数据库中执行。

- 修改application.properties配置文件，增加如下配置。

  ```properties
  spring.datasource.platform=mysql
  db.num=1
  db.url.0=jdbc:mysql://localhost:3306/nacos-config
  db.user=root
  db.password=Lmg12580
  ```

#### 4.2.2 修改集群配置cluster.conf

```markdown
10.53.0.251:3333
10.53.0.251:4444
10.53.0.251:5555
```

> 这个IP不能写127.0.0.1，必须是Linux命令hostname -i能够识别的IP。

#### 4.2.3 修改启动脚本

编辑Nacos启动脚本startup.sh，使它能够接受不同的启动端口。

<img src="Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222173113916.png" alt="image-20201222173113916" style="zoom:50%;float:left" />

![image-20201222173238764](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222173238764.png)

修改完以后，就可以通过命令 `./startup.sh -n 3333`启动端口号为3333的服务实例。

#### 4.2.4 Nginx的配置

修改Nginx配置如下，改完后启动。

<img src="Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222174421015.png" alt="image-20201222174421015" style="zoom:50%; float:left" />

#### 4.2.5 测试通过Nginx访问Nacos

目前的状态：一个Nginx，三个Nacos，一个MySQL

- 启动三个Nacos服务，进入Nacos的bin目录下：

  ```markdown
  ./startup.sh -n 3333
  ./startup.sh -n 4444
  ./startup.sh -n 5555
  ```

- 在浏览器输入地址: http://localhost:1111/nacos/

  ![image-20201222181344642](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222181344642.png)

#### 4.2.6 验证MySQL配置的正确性

- 随便新建一个配置文件

  ![image-20201222183114737](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222183114737.png)

- 查看config_info表，可以看到刚才的配置信息，说明MySQL配置成功。

  ![image-20201222183414648](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222183414648.png)

#### 4.2.7 验证集群配置的正确性

将上述9002服务注册到Nacos集群。

- 修改application.yml文件，换成nginx的地址。

  ```yaml
  spring:
    application:
      name: nacos-payment-provider
    cloud:
      nacos:
        discovery:
          server-addr: localhost:1111 
  ```

- 重启9002服务，在Nacos控制台服务列表中可以查看到注册成功。

  ![image-20201222182635759](Nacos%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201222182635759.png)

- Nacos集群搭建成功(^_^)v