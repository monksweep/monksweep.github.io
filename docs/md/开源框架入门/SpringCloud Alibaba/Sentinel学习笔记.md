# Sentinel学习笔记

## 1. Sentinel简介

### 1.1 Sentinel是什么？

​	随着微服务的流行，服务和服务之间的稳定性变得越来越重要。`Sentinel `以流量为切入点，从流量控制、熔断降级、系统负载保护等多个维度保护服务的稳定性。

Sentinel的特征：

- `丰富的应用场景`：Sentinel 承接了阿里巴巴近 10 年的双十一大促流量的核心场景，例如秒杀（即突发流量控制在系统容量可以承受的范围）、消息削峰填谷、集群流量控制、实时熔断下游不可用应用等。
- `完备的实时监控`：Sentinel 同时提供实时的监控功能。您可以在控制台中看到接入应用的单台机器秒级数据，甚至 500 台以下规模的集群的汇总运行情况。
- `广泛的开源生态`：Sentinel 提供开箱即用的与其它开源框架/库的整合模块，例如与 Spring Cloud、Dubbo、gRPC 的整合。您只需要引入相应的依赖并进行简单的配置即可快速地接入 Sentinel。
- `完善的SPI扩展点`：Sentinel 提供简单易用、完善的 SPI 扩展接口。您可以通过实现扩展接口来快速地定制逻辑。例如定制规则管理、适配动态数据源等。

官网：https://github.com/alibaba/sentinel/

### 1.2 下载和安装

Sentinel分为两个部分：

- 核心库(Java客户端)：不依赖任何框架，能够运行于所有Java运行时环境。
- 控制台(Dashboard)：基于Spring Boot开发，打包后可以直接运行，不需要额外Tomcat容器。

`控制台下载地址`：https://github.com/alibaba/Sentinel/releases

```markdown
# 1.下载sentinel控制台jar包
	sentinel-dashboard-1.8.0.jar
# 2.运行jar包
	> java -jar sentinel-dashboard-1.8.0.jar
# 3.启动成功后，访问http://localhost:8080
	用户名/密码:sentinel/sentinel
```

## 2. Sentinel初始化监控

- 新建一个Spring Boot工程cloudalibaba-sentinel-service
- 修改pom文件，添加sentinel依赖

```markdown
<dependency>
	<groupId>com.alibaba.cloud</groupId>
	<artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>
```

- 修改yml文件

```yaml
server:
  port: 8401
spring:
  application:
    name: cloudalibaba-sentinel-service
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
    sentinel:
      transport:
        # 配置sentinel dashboard地址
        dashboard: localhost:8080
        # 默认8719端口，假如被占用会自动从8719开始依次+1扫描，直至找到未被占用的端口
        port: 8719

management:
  endpoints:
    web:
      exposure:
        include: '*'
```

- 添加一个简单的业务类

```java
@RestController
public class FlowLimitController {
    @GetMapping("/testA")
    public String testA(){
        return "-----testA-----";
    }
    @GetMapping("/testB")
    public String testB(){
        return "-----testB-----";
    }
}
```

- 运行主启动类

```java
@SpringBootApplication
@EnableDiscoveryClient
public class SentinelApp {
    public static void main(String[] args) {
        SpringApplication.run(SentinelApp.class, args);
    }
}
```

- 启动后直接在控制台找不到本服务，执行以下命令

```markdown
curl http://localhost:8401/testA
```

​		执行完以后就可以在控制台中看到本服务

![image-20201229114324670](Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201229114324670.png)

> Sentinel的`懒加载`说明：服务启动后不会立即被加载，必须手动执行一次访问。

## 3. 流量控制

​	`流量控制(flow control)`：其原理是监控应用流量的 QPS 或并发线程数等指标，当达到指定的阈值时对流量进行控制，以避免被瞬时的流量高峰冲垮，从而保障应用的高可用性。

一条限流规则主要由下面几个因素组成，我们可以组合这些元素来实现不同的限流效果：

- `resource`：资源名，即限流规则的作用对象
- `count`：限流阈值
- `grade`：限流阈值类型（QPS 或并发线程数）
- `limitApp`：流控针对的调用来源，若为 `default` 则不区分调用来源
- `strategy`: 调用关系限流策略
- `controlBehavior`: 流量控制效果（直接拒绝、Warm Up、匀速排队）

### 3.1 所有流控规则

- 阈值类型/单机阈值
  - QPS(每秒钟的请求数量)：当调用该api的QPS达到阈值的时候，进行限流
  - 线程数：当调用该api的线程数达到阈值的时候，进行限流
- 是否集群：不需要集群
- 流控模式：
  - `直接`：api达到限流条件时，直接限流
  - `关联`：当关联的资源达到阈值时，就限流自己（例：支付接口达到阈值，限流下订单接口）
  - `链路`：只记录指定链路上的流量（指定资源从入口资源进来的流量，如果达到阈值，就进行限流）【api级别的针对来源】

- 流控效果：
  - `快速失败`：直接失败，抛异常
  - `Warm Up`：根据codeFactor（冷加载因子，默认3）的值，从阈值/codeFactor，经过预热时长，才达到设置的QPS阈值
  - `排队等待`：匀速排队，让请求以均匀的速度通过，阈值类型必须设置为QPS，否则无效
    - 匀速排队会严格控制请求通过的间隔时间，也即是让请求以均匀的速度通过，对应的是**漏桶算法**。
    - 这种方式主要用于处理间隔性突发的流量，例如**消息队列**。场景举例：在某一秒有大量的请求到来，而接下来的几秒则处于空闲状态，我们希望系统能够在接下来的空闲期间逐渐处理这些请求，而不是在第一秒直接拒绝多余的请求。

### 3.2 示例：QPS直接失败

1. 新增流控规则（两种方式）：

- 流控规则 -> 新增流控规则

- 簇点链路 -> 列表视图 -> 找到对应的资源名 -> +流控

<img src="Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201229181306671.png" alt="image-20201229181306671" style="zoom:50%;" />

2. 上述规则的含义为1秒内只允许查询一次，若超过1次，就直接-快速失败，我们执行一次以下命令

```markdown
curl http://localhost:8401/testA
```

这时候正常返回

```markdown
-----testA-----
```

如果快速执行两次（1秒内），则会报错，因为被sentinel限流了

```markdown
Blocked by Sentinel (flow limiting)
```

## 4. 熔断降级

### 4.1 三种熔断策略

Sentinel 提供以下几种熔断策略：

- 慢调用比例 (`SLOW_REQUEST_RATIO`)：选择以慢调用比例作为阈值，需要设置允许的慢调用 RT（即最大的响应时间），请求的响应时间大于该值则统计为慢调用。当单位统计时长（`statIntervalMs`）内请求数目大于设置的最小请求数目，并且慢调用的比例大于阈值，则接下来的熔断时长内请求会自动被熔断。经过熔断时长后熔断器会进入探测恢复状态（HALF-OPEN 状态），若接下来的一个请求响应时间小于设置的慢调用 RT 则结束熔断，若大于设置的慢调用 RT 则会再次被熔断。
- 异常比例 (`ERROR_RATIO`)：当单位统计时长（`statIntervalMs`）内请求数目大于设置的最小请求数目，并且异常的比例大于阈值，则接下来的熔断时长内请求会自动被熔断。经过熔断时长后熔断器会进入探测恢复状态（HALF-OPEN 状态），若接下来的一个请求成功完成（没有错误）则结束熔断，否则会再次被熔断。异常比率的阈值范围是 `[0.0, 1.0]`，代表 0% - 100%。
- 异常数 (`ERROR_COUNT`)：当单位统计时长内的异常数目超过阈值之后会自动进行熔断。经过熔断时长后熔断器会进入探测恢复状态（HALF-OPEN 状态），若接下来的一个请求成功完成（没有错误）则结束熔断，否则会再次被熔断。

> 注意：异常降级**仅针对业务异常**，对 Sentinel 限流降级本身的异常（`BlockException`）不生效。

### 4.1 示例：异常比例

1. 新增降级规则（1秒内异常比例达到20%且1秒内最小请求数大于1则开启熔断）

<img src="Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230111632417.png" alt="image-20201230111632417" style="zoom:50%;" />

2. 修改业务方法

```java
@GetMapping("/testA")
public String testA(){
  log.info("testA 测试熔断降级");
  int a = 10/0;
  return "-----testA-----";
}
```

3. 使用jMeter压测，1秒内请求10次

![image-20201230111949900](Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230111949900.png)

4. 启动jMeter后，执行以下命令

```markdown
curl http://localhost:8401/testA
```

​		会看到如下结果，原因：***错误率100% > 20% && 每秒请求10 > 1***，被sentinel熔断了

```markdown
Blocked by Sentinel (flow limiting)
```

​		不启动jMeter，1秒执行1次请求，不会被熔断，直接报错，因为不满足**大于最小请求数**的条件

```markdown
java.lang.ArithmeticException: / by zero
```

​		如果1秒内执行两次请求，则被熔断

## 5. 热点参数限流

### 5.1 什么是热点参数？

`热点`即经常访问的数据。很多时候我们希望统计某个热点数据中访问频次最高的 Top K 数据，并对其访问进行限制。比如：

- 商品 ID 为参数，统计一段时间内最常购买的商品 ID 并进行限制
- 用户 ID 为参数，针对一段时间内频繁访问的用户 ID 进行限制

热点参数限流会统计传入参数中的热点参数，并根据配置的限流阈值与模式，对包含热点参数的资源调用进行限流。热点参数限流可以看做是一种特殊的流量控制，仅对包含热点参数的资源调用生效。

Sentinel 利用 LRU 策略统计最近最常访问的热点参数，结合**令牌桶算法**来进行参数级别的流控。热点参数限流支持集群模式。

### 5.2 简单热点参数限流

> 使用热点限流建议配合`@SentinelResource`使用，因为如果违背了限流规则，会抛出错误页面，不友好。

1. 添加业务方法

```java
@GetMapping("/testHotkey")
@SentinelResource(value = "testHotkey", blockHandler = "dealHotkey")
public String testHotkey(@RequestParam(value = "p1", required = false) String p1,
                         @RequestParam(value = "p2", required = false) String p2){
  return "---testHotkey---";
}
public String dealHotkey(String p1, String p2, BlockException blockException){
  return "---dealHotkey---";
}
```

2. 新增热点规则：包含第一个参数p1的请求，QPS不能大于1

<img src="Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230142404311.png" alt="image-20201230142404311" style="zoom:50%;" />

3. 执行一次以下命令

```markdown
http://localhost:8401/testHotkey?p1=a
```

​		返回正常，没有被限流

```markdown
---testHotkey---
```

​		多次执行以上命令(1秒内)，被限流

```markdown
---dealHotkey---
```

❌ http://localhost:8401/testHotkey?p1=a

❌ http://localhost:8401/testHotkey?p1=a&p2=b

✅ http://localhost:8401/testHotkey?p2=b

### 5.3 参数例外项

​	上述案例演示了当QPS > 1时马上被限流，但有时有些特殊情况：我们期望p1参数是某个特殊值时，他的限流和平时不一样。特例：假如当p1的值等于5时，它的阈值可以达到200。

1. 修改热点规则，点击高级选项（填完后必须点添加按钮）

<img src="Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230144852108.png" alt="image-20201230144852108" style="zoom:50%;" />

2. 执行以下命令

```markdown
curl http://localhost:8401/testHotkey?p1=5
```

​	疯狂请求，也不会被限流，如果将p1改为其他值，则QPS不能大于1

```markdown
curl http://localhost:8401/testHotkey?p1=1
---dealHotkey---
```

> 注意：参数必须是基本类型或者String

## 6. 系统规则

### 6.1 简介

Sentinel 系统自适应限流从整体维度对应用入口流量进行控制，结合应用的 Load、CPU 使用率、总体平均 RT、入口 QPS 和并发线程数等几个维度的监控指标，通过自适应的流控策略，让系统的入口流量和系统的负载达到一个平衡，让系统尽可能跑在最大吞吐量的同时保证系统整体的稳定性。

系统规则支持以下的模式：

- **Load 自适应**（仅对 Linux/Unix-like 机器生效）：系统的 load1 作为启发指标，进行自适应系统保护。当系统 load1 超过设定的启发值，且系统当前的并发线程数超过估算的系统容量时才会触发系统保护（BBR 阶段）。系统容量由系统的 `maxQps * minRt` 估算得出。设定参考值一般是 `CPU cores * 2.5`。
- **CPU usage**（1.5.0+ 版本）：当系统 CPU 使用率超过阈值即触发系统保护（取值范围 0.0-1.0），比较灵敏。
- **平均 RT**：当单台机器上所有入口流量的平均 RT 达到阈值即触发系统保护，单位是毫秒。
- **并发线程数**：当单台机器上所有入口流量的并发线程数达到阈值即触发系统保护。
- **入口 QPS**：当单台机器上所有入口流量的 QPS 达到阈值即触发系统保护。

## 7. @SentinelResource

### 7.1 自定义配置

1. 新建全局异常类

```java
public class CustomBlockHandler {
    public static CommonResult handleException(BlockException e){
        return new CommonResult(2020,"global exception1");
    }
    public static CommonResult handleException2(BlockException e){
        return new CommonResult(2020,"global exception2");
    }
}
```

2. 配置要限流的接口

```java
@GetMapping("/customBlockHandler")
@SentinelResource(value = "customBlockHandler",
                  blockHandlerClass = CustomBlockHandler.class,
                  blockHandler = "handleException2")
public CommonResult customBlockHandler(){
  return new CommonResult(200,"自定义配置",new Payment(2020L,"0001"));
}
```

3. 新增流控规则

<img src="Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230161349033.png" alt="image-20201230161349033" style="zoom:50%;" />

4. 1秒内多次请求以下地址

```markdown
curl http://localhost:8401/customBlockHandler
```

​	这时候会抛出我们的自定义异常2

```markdown
{"code": 2020,"message":"global exception2","data":null}
```

### 7.2 blockHandler和fallback

两个都是@SentinelResource注解内的属性，且都是用于降级，区别：

- `blockHandler`：负责sentinal控制台配置违规
- `fallback`：负责运行异常

> 若两者都进行了配置，则被限流降级而抛出BlockException时只会进入`blockHandler`处理逻辑

### 7.3 忽略属性

我们可以在注解@SentinelResource中添加`exceptionsToIgnore`属性，假如程序报指定的异常，也不会走fallback方法了，没有降级效果了。

```java
@GetMapping("/customBlockHandler")
@SentinelResource(value = "customBlockHandler",
                  fallback = "handlerFallback",
                  exceptionsToIgnore = { IllegalArgumentException.class }
                 )
public CommonResult customBlockHandler(){
  return new CommonResult(200,"自定义配置",new Payment(2020L,"0001"));
}
```

## 8. Sentinel整合OpenFeign实现服务熔断

### 8.1 配置

1. 修改pom文件，添加feign依赖

```markdown
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

2. 修改yml文件，激活sentinel对feign的支持

```yaml
feign:
  sentinel:
    enabled: true
```

3. 新建Feign接口PaymentService

```java
@FeignClient(value = "nacos-payment-provider", fallback = PaymentFallbackService.class)
public interface PaymentService {
    @GetMapping(value = "/payment/nacos/{id}")
    String getPayment(@PathVariable("id") Integer id);
}

@Component
public class PaymentFallbackService implements PaymentService{

    @Override
    public String getPayment(Integer id) {
        String result = "---getPayment fallback---";
        return result;
    }
}
```

4. Controller添加方法

```java
@Resource
private PaymentService paymentService;

@GetMapping(value = "/getPayment/{id}")
public String getPayment(@PathVariable("id") Integer id){
  return paymentService.getPayment(id);
}
```

5. 主启动添加注解@EnableFeignClients

```java
@SpringBootApplication
@EnableFeignClients
public class OrderNacosApp {
    public static void main(String[] args) {
        SpringApplication.run(OrderNacosApp.class, args);
    }
}
```

### 8.2 测试

1. 执行以下命令

```markdown
curl http://localhost:83/getPayment/1
```

​	可以看到如下结果

```markdown
nacos registry, serverPort:9001 id:1
```

2. 将服务提供方停掉，再次执行以上命令，可以发现降级配置成功

```markdown
---getPayment fallback---
```

## 9. Sentinel的持久化

### 9.1 为什么需要持久化

​	在sentinel控制台配置的所有规则，都是临时的，一旦重启应用，sentinel规则将消失，需要我们重新配置。它提供了一种持久化的方式：将配置规则持久化到Nacos保存，只要Nacos里的配置不删除，规则就一直存在。

### 9.2 持久化配置

1. 添加pom依赖

```markdown
<dependency>
  <groupId>com.alibaba.csp</groupId>
  <artifactId>sentinel-datasource-nacos</artifactId>
</dependency>
```

2. 修改yml文件

```yaml
spring:
  cloud:
    sentinel:
      datasource:
        ds1:
          nacos:
            server-addr: localhost:8848
            dataId: cloudalibaba-sentinel-service
            groupId: DEFAULT_GROUP
            data-type: json
            rule-type: flow
```

3. 进入Nacos控制台，新建配置

<img src="Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230182048835.png" alt="image-20201230182048835" style="zoom:50%;" />

- resource：资源名称
- limitApp：来源应用
- grade：阈值类型，0表示线程数，1表示QPS
- count：单机阈值
- strategy：流控模式，0：直接 1：关联 2：链路
- controlBehavior：流控效果，0：快速失败 1：Warm Up 2：排队等待
- clusterMode：是否集群，true：是 false：否

4. 重启服务，先执行以下命令

```markdown
curl http://localhost:8401/testB
```

​	在控制台中可以看到流控配置

![image-20201230182822308](Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230182822308.png)

5. 再次重启服务，快速执行以上命令(QPS  > 1)，发现流控效果仍然存在

```markdown
curl http://localhost:8401/testB
Blocked by Sentinel (flow limiting)
```

​	命令执行后Sentinel控制台仍然能看到该流控规则

![image-20201230183242140](Sentinel%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20201230183242140.png)