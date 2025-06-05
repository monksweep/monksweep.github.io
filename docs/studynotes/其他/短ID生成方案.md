# 别再用雪花算法生成ID了！试试这个吧



大家好啊，今天继续聊服务器中唯一ID生成。唯一ID生成中雪花算法大家都比较熟，那如果加一个要求呢：

> 尽量短的数字ID

![image.png](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/611c0c2b7f5d48de8b9d5ce4c7132dd2~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=2XWBKvldvDtff%2FjMZm3KNNf3QTQ%3D)



## 背景

之前的项目有个需求：为用户账号生成账号ID。最开始用的是UUID（长字符串ID），但是字符串账号相对于数字账号，存储和传输性能都稍逊，也不利于记忆和传播。

因此，生成一套业务内的数字账号，并且尽量简短就是当务之急。

## 初步版本

我们最开始考虑的是雪花算法方案，使用的是经典的 twitter开源的算法 snowflake。这个算法非常强大，生成的是 64bit 的数字id，天然支持分布式。

有关这个算法的详细分析，可以查看我前一段时间发的这篇文章：[【收藏级】唯一ID生成探讨：论ID与猪肉？](https://juejin.cn/post/7386243179278041128)

雪花算法看起来无懈可击，但是唯一的问题就是生成的64位 ID 太长了。账号ID希望能控制的尽量短，个人理解有以下原因：

- 账号id一般显示在个人设置里，会暴露给用户，需要便于输入 + 记忆，这样客服查询起来更方便；
- 账号id短并且有序能提高账号库的写入性能；

于是着手改进。

## 改进版本

一个比较可行的方案是利用数据库的自增 ID 特性。

为了便于理解，我们先来看一下业务里的账号登录流程：

- 客户端上传第三方openid及token来登录，登录服拿到openid后需要查询是否已经注册账号
- 如果能查到账号ID，表明已经注册，再根据查到的数字账号来做后续登录逻辑
- 如果查不到，则需要新注册一个账号到账号表
- 新建账号首先需要生成一个数字的账号ID，在目前的机制中，通过一张专门的`ID生成表`来做的。

OK，先来看我们如何在mysql中存储账号相关信息的：

- **账号表**，accid就是我们说的数字账号。考虑到账号数量级可能到千万甚至上亿，单表的性能肯定不理想，因此我们分了10张表。其表结构为

  ```sql
  CREATE TABLE `tbl_global_user_map_00` (
  
    `account` varchar(32) NOT NULL,
  
    `accid` bigint(20) NOT NULL,
  
    `created_at` datetime DEFAULT NULL,
  
    PRIMARY KEY (`account`) USING BTREE
  
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8 
  ```

- **账号ID生成表**，其表结构为

  ```sql
  CREATE TABLE `tbl_accid` (
  
    `id` bigint(20) NOT NULL AUTO_INCREMENT,
  
    `stub` char(1) NOT NULL DEFAULT '',
  
    PRIMARY KEY (`id`) USING BTREE,
  
    UNIQUE KEY `UQE_tbl_accid_stub` (`stub`) USING BTREE
  
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8 
  ```

数据为

![img](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/619f946e0d5d4d43b4301ceefc7fe72a~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=bVW3sv4RpX6Y07Xh2zA4grGhrW0%3D)

整个表只有一行数据，id列为自增列，它的值就是最新生成的账号ID值。这个ID生成的原理是：

- 设置id列为自增，这样每插入一列id值就会自动递增
- 如果没有其他限制，这张表的数据就会随着insert的次数越来越多，假如账号有几千万，这张表就有几千万行数据
- 为此，我们增加了一列 stub，设置其为 unique key，并且每次insert其值都是一样的（例如设置为 'a'），这样就保证整个表只有一行数据，而id会随着每次insert自动递增。
- 如果直接用 insert into 语句来做插入，肯定每次都返回错误（除了第1次），因为 stub 为 ‘a’ 的记录已经存在了，每次插入都会失败。
- 我们改用 MySQL 扩展的 SQL 语句 replace into 来实现。replace 必须要配合唯一索引来使用。

于是 SQL 语句就是

```scss
REPLACE INTO tbl_accid(`stub`) VALUES('a');
```

它的效果如下：

- 如果 stub 为 'a' 的记录不存在，则插入，类似 insert 操作
- 如果 stub 为 'a' 的记录已经存在，则先 delete 该条记录，再 insert 新记录。由于删除已有的记录时，表的自增值不会变化，再新增记录时 id 会在老的自增值基础上继续递增

**有同学可能要问了，为什么要搞一个单独的`ID生成表`来生成自增id？将自增字段直接放到账号表中不行么？**

关键的问题在于`业务要分表`。假如账号表分了10张，要合并自增id列的话，需要划分好每张表的生成范围。

例如我们设计每张表可以生成 100w 个id，那 10 张表的起始id 分别是 1， 1000001，2000001， ...

跨度非常大，和我们当初的设计：简短并尽量连续的要求违背。

因此，专门的账号ID生成表是必要的。

## 问题暴露

上述方案完成之后，我就去吃火锅唱歌去了。

![image.png](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/3c600e315527497c9ecb076df6baf09a~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=lAUrqqT86a%2B8%2FS5oi7mmBiJfv3g%3D)

然后，就出现了一个比较棘手的问题。某天晚上QA同事反馈压力测试有报错，登录服会间歇性返回db错误，如下：

```vbnet
ERROR : Deadlock found when trying to get lock; try restarting transaction
```

登录服收到该返回后打印了错误日志，提示客户端服务器发生错误。很明显，这个方案有死锁问题。

![image.png](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/5d99e66462354fd9b43d352d0e5a7261~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=HOrKNUACuPnP5LlMqnC12Neufl4%3D)

google了一下 replace 在并发情况下的死锁问题，大致和 replace 被分解成 delete + insert 有关，而 innodb又是行锁机制。详细的原因非常复杂，有关资料为

[yq.aliyun.com/articles/41…](https://link.juejin.cn/?target=https%3A%2F%2Fyq.aliyun.com%2Farticles%2F41190)

[techlog.cn/article/lis…](https://link.juejin.cn/?target=https%3A%2F%2Ftechlog.cn%2Farticle%2Flist%2F10183451%23l)

[blog.itpub.net/7728585/vie…](https://link.juejin.cn/?target=http%3A%2F%2Fblog.itpub.net%2F7728585%2Fviewspace-2141409%2F)

很多博客也给出了建议：

> 通过几个死锁案例，我们强烈建议在生产环境中尽量避免使用REPLACE INTO和INSERT INTO ON DUPLICATE UPDATE语句，改用普通INSERT操作，并对INSER操作部分代码加入异常加查，当INSERT失败时改为UPDATE操作。

为了再验证一次死锁的并非语言或者API的bug，我用了 mysql 自带的压测工具 mysqlslap 做了个简单测试：

```mysql
mysqlslap -uroot -p --create-schema="db_global_200" --concurrency=2 --iterations=5 --number-of-queries=500 --query="replace_innodb.sql"

mysqlslap: Cannot run query REPLACE INTO tbl_yptest_innodb(`stub`) VALUES('a'); ERROR : Deadlock found when trying to get lock; try restarting transaction
```

结果显示并发数为 2 时就出现了死锁问题。然后我又尝试将表引擎改为 myisam，再次压测，虽然没有出现死锁问题，但是MYISAM引擎更新数据的效率比较低。因此我们不得不放弃了mysql自增ID的方案，再想其他方案。

![image.png](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/938df8142d5c46b689b6dd0b3ac38870~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=6KtqgpiiDLuByZdE2ZF0G1dXyIs%3D)

## 其他方案1

继续尝试其他方案。其实，我们最新的ID生成方案参考了美团技术团队的一篇文章，有兴趣的可以查阅：[Leaf——美团点评分布式ID生成系统](https://link.juejin.cn/?target=https%3A%2F%2Ftech.meituan.com%2F2017%2F04%2F21%2Fmt-leaf.html)

文中提到了一种Flickr团队的改进方案：

![img](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/4480cb7273d04e89a1e6321236f73f61~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=Wf2iyKbpb2RMdjlF0kxAr6vLhZc%3D)

然而这种方式部署限制和消耗都太大，而且我们的登录服是多开的，即使在单登录服内控制串行，多个进程也不好控制，因此这个初始的方案只能被pass。

回到开始的思路，能不能将自增id合并到 账号表_xx 中，从而放弃 replace 呢？

我们可以将每个 tbl_global_user_map 分表类比成上图中的 mysql-01, mysql-02, ...

然后自增时，采取 **间隔步长N** 的方式（默认的自增步长是1，每次自增加1）

举例：

tbl_global_user_map_00 表，起始id 20000，每次加10，其生成的 id 每次是 20000, 20010, 20020, 20030...

tbl_global_user_map_01 表，起始id 20001，也是每次加10，其生成的 id 每次是 20001, 20011, 20021, 20031...

...

这个id看起来间隔很小，看起来非常理想。

需要做的事情就是设置 auto_increment_increment 和 auto_increment_offset 两个mysql中的变量。

然后很可惜，这两个变量属于 全局 或者 session（连接会话） 级别，没有 table 级别的设置。

如果我们设置了这两个变量，很容易影响其他表，产生其他错误。

## 其他方案2

再想其他方案。

仔细整理一下我们的需求，就会发现我们的账号表一般只有新增，没有删除和修改。能不能利用`读写分离`的思想，在插入新映射关系（同时生成自增账号ID）时，只有一张表可写，自增id可以每次只加1；而查询时，属于读，读的数据可以分布在10张表中。我们要做的就是定期将可写表中已有的一些数据迁移到只读的这10张表中（根据账号ID做shard），控制可写表的数量级不能太大。

账号ID在写表中自增，相当于自动分配账号ID。

![image.png](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/682a620181e24786ab8ab768572ab1d3~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=%2BsC5SKSyIVNukg2bHn2hff1mi5w%3D)

这个机制有点类似于我们的`日志滚动`，当前正在写的日志文件不停被写入（插入日志），当超过一定大小或者日期切换时会滚动成只读的文件。

**这个方案理论上可行，但是有运维复杂性**：需要配合运维来做数据迁移，维护成本比较高，因此组内讨论后我们决定pass掉。

## 其他方案3（最终方案）

我之前所在的成熟项目也用过上述【其他方案1】中类似美团的方案，即`预申请一批ID`的方式。

对比来看，我们之前申请ID都是一次自增1，而这种预申请一批的方式，是一次申请N个ID，自增N，可以减少请求量和并发。当请求量明显下降后，之前方案里担忧的问题：ID生成表插入行数过多也就不存在了。

`唯一的问题是：预申请的ID可能会被浪费`。如果申请了一段区间的id，但是没有用完，服务器停服再启动后会再申请一段新的，原来未使用的ID就被浪费了。

因此我们着手优化这种算法，目的很明显：

> 减少浪费的ID，去除空洞号段，并自动兼容登录服扩容与容灾的情况。

如果这个目的能达成，那就完美契合了我们当初的需求。

![image.png](https://p6-xtjj-sign.byteimg.com/tos-cn-i-73owjymdk6/ecb900659c764adfa081d9430ab09ace~tplv-73owjymdk6-jj-mark-v1:0:0:0:0:5o6Y6YeR5oqA5pyv56S-5Yy6IEAg56CB6LSi5ZCM6KGM:q75.awebp?rk3s=f64ab15b&x-expires=1749255795&x-signature=uox%2Fdf9u9O4tMoeJ%2BT2fm9f%2F%2FFE%3D)



## 短ID方案细节

设计发号表 tbl_account_freeid

| 号段编号，自增 | svr编号  | 号段内剩余freeid数量 |
| -------------- | -------- | -------------------- |
| segment        | loginsvr | left                 |

每个登陆服要申请一批账号ID时，就来表中插入一行，规定每次申请1000个，由于segment自增，相当于申请了 [(segment - 1) * 1000, segment * 1000) 这段区间，申请时候默认 left 是 0

登录服正常停服维护时将剩余未用完的数量写入 left，防止浪费，下次启动时候还可以再利用。

以下分析各种case：

a) 初始 tbl_account_freeid 没有数据，假如 loginsvr 开3个实例，实例编号分别是1，2，3。

服务器启动时候需要做一次查找，要找对应 实例编号的segment。如果找到了，且 left 不为 0，则说明该号段还可以用；如果找不到，或者left为0，则需要新申请（新插入一行记录）。

于是第一次启服后数据为

| 号段编号，自增 | svr编号  | 号段内剩余freeid数量 |                       |
| -------------- | -------- | -------------------- | --------------------- |
| segment        | loginsvr | left                 |                       |
| 1              | 2        | 0                    | 内存中号段为 1-1000   |
| 2              | 1        | 0                    | 内存中号段为1001-2000 |
| 3              | 3        | 0                    | 内存中号段为2001-3000 |

b) 如果loginsvr发现内存中号段用完了，就不用再查找，直接申请，往数据库插入一行数据，假定实例编号 1 和 3 的 号段用完了，新申请。

然后各个登录服正常停服，left 回写。可能的数据情况如下：

| 号段编号，自增 | svr编号  | 号段内剩余freeid数量 |                        |
| -------------- | -------- | -------------------- | ---------------------- |
| segment        | loginsvr | left                 |                        |
| 1              | 2        | 200                  |                        |
| 2              | 1        | 0                    | （使用完毕，该行可删） |
| 3              | 3        | 0                    | （使用完毕，该行可删） |
| 4              | 1        | 800                  |                        |
| 5              | 3        | 750                  |                        |

c) 再次起服时，查找到各个编号的实例都有号段可用。无需新插入数据，但是对应的 left 要改为0（相当于申请了 left 个）

| 号段编号，自增 | svr编号  | 号段内剩余freeid数量 |                                             |
| -------------- | -------- | -------------------- | ------------------------------------------- |
| segment        | loginsvr | left                 |                                             |
| 1              | 2        | 0                    | 登录服内存中号段为 801-1000（剩余的200个）  |
| 2              | 1        | 0                    | （使用完毕，该行可删除）                    |
| 3              | 3        | 0                    | （使用完毕，该行可删除）                    |
| 4              | 1        | 0                    | 登录服内存中号段为3201-4000（剩余的800个）  |
| 5              | 3        | 0                    | 登录服内存中号段为4251-5000 （剩余的750个） |

d) 如果此时 loginsvr 扩容，新增编号 4 - 10 的 svr，和初始情况类似，需要先查找，没有则申请。此时数据可能为

| 号段编号，自增 | svr编号  | 号段内剩余freeid数量 |                                             |
| -------------- | -------- | -------------------- | ------------------------------------------- |
| segment        | loginsvr | left                 |                                             |
| 1              | 2        | 0                    | 登录服内存中号段为 801-1000（剩余的200个）  |
| 2              | 1        | 0                    | （使用完毕，该行可删除）                    |
| 3              | 3        | 0                    | （使用完毕，该行可删除）                    |
| 4              | 1        | 0                    | 登录服内存中号段为3201-4000（剩余的800个）  |
| 5              | 3        | 0                    | 登录服内存中号段为4251-5000 （剩余的750个） |
| 6              | 4        | 0                    | 登录服内存中号段为5001-6000                 |
| 7              | 5        | 0                    | 登录服内存中号段为6001-7000                 |
| 8              | 6        | 0                    | 登录服内存中号段为7001-8000                 |
| 9              | 7        | 0                    | 登录服内存中号段为8001-9000                 |
| 10             | 8        | 0                    | 登录服内存中号段为9001-10000                |
| 11             | 9        | 0                    | 登录服内存中号段为10001-11000               |
| 12             | 10       | 0                    | 登录服内存中号段为11001-12000               |

这种方式的特点就是，登录服服务过程中，对应数据库里的 left 为 0，如果停了，数据库里 left 为号段内剩余的可用数量。

如果登录服宕机，则没有回写 left 的过程，则对应号段内没有用完的（最多1000）会浪费。

## 结尾

以上就是我们在账号短ID生成上的探索，最终方案经历了长时间的生产环境的测试，运转正常。如果小伙伴们有更优秀的经验欢迎一起交流。