在电商、支付等领域，往往会有这样的场景，用户下单后放弃支付了，那这笔订单会在指定的时间段后进行关闭操作。

细心的你一定发现了像某宝、某东都有这样的逻辑，而且时间很准确，误差在 1s 内，那他们是怎么实现的呢？

一般实现的方法有几种：
- 使用 RocketMQ、RabbitMQ、Pulsar 等消息队列的延时投递功能
- 使用 Redisson 提供的 DelayedQueue

有一些方案虽然广为流传但存在着致命缺陷，不要用来实现延时任务：
- 使用 Redis 的过期监听
- 使用 RabbitMQ 的死信队列
- 使用非持久化的时间轮

## Redis 过期监听

在 Redis 官方手册的 keyspace-notifications: timing-of-expired-events 中明确指出：

> Basically expired events are generated when the Redis server deletes the key and not when the time to live theoretically reaches the value of zero

Redis 自动过期的实现方式是：定时任务离线扫描并删除部分过期键；在访问键时惰性检查是否过期并删除过期键。

Redis 从未保证会在设定的过期时间立即删除并发送过期通知。实际上，过期通知晚于设定的过期时间数分钟的情况也比较常见。

此外键空间通知采用的是发送即忘（fire and forget）策略，并不像消息队列一样保证送达。当订阅事件的客户端会丢失所有在断线期间所有分发给它的事件。

这是一种比定时扫描数据库更 “LOW” 的解决方案，请不要使用。

## RabbitMQ 死信

死信（Dead Letter）是 RabbitMQ 提供的一种机制。

当一条消息满足下列条件之一那么它会成为死信：
- 消息被否定确认（如 channel.basicNack）并且此时 requeue 属性被设置为 false。
- 消息在队列的存活时间超过设置的 TTL 时间
- 消息队列的消息数量已经超过最大队列长度

若配置了死信队列，死信会被 RabbitMQ 投到死信队列中。

在 RabbitMQ 中创建死信队列的操作流程大概是：
- 创建一个交换机作为死信交换机
- 在业务队列中配置 x-dead-letter-exchange 和 x-dead-letter-routing-key，将第一步的交换机设为业务队列的死信交换机
- 在死信交换机上创建队列，并监听此队列

死信队列的设计目的是为了存储没有被正常消费的消息，便于排查和重新投递。死信队列同样也没有对投递时间做出保证，在第一条消息成为死信之前，后面的消息即使过期也不会投递为死信。

为了解决这个问题，Rabbit 官方推出了延迟投递插件 rabbitmq-delayed-message-exchange，推荐使用官方插件来做延时消息。

这里说点题外话，使用 Redis 过期监听或者 RabbitMQ 死信队列做延时任务都是以设计者预想之外的方式使用中间件，这种出其不意必自毙的行为通常会存在某些隐患，比如缺乏一致性和可靠性保证，吞吐量较低、资源泄漏等。

比较出名的一个事例是很多人使用 Redis 的 List 作为消息队列，以致于最后作者看不下去写了 Disque 并最后演变为 Redis Stream。工作中还是尽量不要滥用中间件，用专业的组件做专业的事。

## 时间轮

时间轮是一种很优秀的定时任务的数据结构，然而绝大多数时间轮实现是纯内存没有持久化的。

运行时间轮的进程崩溃之后其中所有的任务都会灰飞烟灭，所以奉劝各位勇士谨慎使用。

### Redisson DelayQueue

Redisson DelayQueue 是一种基于 Redis Zset 结构的延时队列实现。DelayQueue 中有一个名为 timeoutSetName 的有序集合，其中元素的 score 为投递时间戳。

DelayQueue 会定时使用 zrangebyscore 扫描已到投递时间的消息，然后把它们移动到就绪消息列表中。

DelayQueue 保证 Redis 不崩溃的情况下不会丢失消息，在没有更好的解决方案时不妨一试。

在数据库索引设计良好的情况下，定时扫描数据库中未完成的订单产生的开销并没有想象中那么大。

在使用 Redisson DelayQueue 等定时任务中间件时可以同时使用扫描数据库的方法作为补偿机制，避免中间件故障造成任务丢失。

## 结论

总结了几点如下：
- 首先推荐使用 RocketMQ、Pulsar 等拥有定时投递功能的消息队列。
- 在不方便获得专业消息队列时可以考虑使用 Redisson DelayQueue 等基于 Redis 的延时队列方案，但要为 Redis 崩溃等情况设计补偿保护机制。
- 在无法使用 Redisson DelayQueue 等方案时可以考虑使用时间轮。由于时间轮重启后重要频繁，定时扫描等保护机制更为重要。
- 永远不要使用 Redis 过期监听实现定时任务。
