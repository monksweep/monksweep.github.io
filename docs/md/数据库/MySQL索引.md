# MySQL索引

## 1.  简介

### 1.1 索引是什么

MySQL官方对索引的定义为：索引（Index）是帮助MySQL高效获取数据的数据结构。

可以得到索引的本质：索引是数据结构。

简单的理解为：`排好序的快速查找数据结构。`

> 我们平常所说的索引，如果没有特别指明，都是指`B树`（多路搜索树，并不一定是二叉的）结构组织的索引。其中聚集索引，次要索引，覆盖索引，复合索引，前缀索引，唯一索引默认都是使用B+树索引，统称索引。除了B+树这种类型的索引之外，还有哈希索引（Hash Index）等。

### 1.2 索引分类

```markdown
# 单值索引
	一个索引只包含单个列，一个表可以有多个单列索引
# 唯一索引
	索引列的值必须唯一，但允许有空值
# 复合索引
	即一个索引包含多个列
# 覆盖索引
	select的数据列只用从索引中就能够取得，不必读取数据行，MySQL可以利用索引返回select列表中的字段，而不必根据索引再次读取数据文件,换句话说查询列要被所建的索引覆盖。
```

### 1.3 基本语法

1. 创建

```sql
方式一： create [UNIQUE] index indexName on mytable(columnname(length));
方式二： alter mytable add [UNIQUE] index [indexName] on (columnname(length));
```

2. 删除

```sql
drop index [indexName] on mytable;
```

3. 查看

```sql
show index from table_name;
```

- 扩展 >>>

有四种方式来添加数据表的索引：

```sql
1. alter table mytable add primary key(cloumn_list);
	 该语句添加一个主键，这意味着索引值必须是唯一的，且不能为NULL
2. alter table mytable add unique index_name(column_list);
	 该语句创建索引的值必须是唯一的，除了NULL外（NULL可能出现多次）
3. alter table mytable add index index_name(column_list);
	 添加普通索引，索引值可出现多次
4. alter table mytable add fulltext index_name(column_list);
	 该语句指定了索引为fulltext，用于全文索引
```

### 1.4 建索引的注意事项

- 需要建立索引的场景
  1. 主键自动建立唯一索引
  2. 频繁作为查询条件的字段
  3. 查询中与其他表关联的字段，外键关系建立索引
  4. 查询中的排序字段若通过索引去访问将大大提高排序速度
  5. 查询中统计或者分组的字段
- 不需要建立索引的场景
  1. 表记录太少
  2. 经常增删改的表
  3. 数据重复且分布平均的字段
  4. Where条件里用不到的字段不创建索引

## 2. 性能分析

### 2.1 MySQL Query Optimizer

1. Mysql中有`专门负责优化SELECT语句的优化器模块`，主要功能：通过计算分析系统中收集到的统计信息 ，为客户端请求的Query提供他认为最优的执行计划（他认为最优的数据检索方式，但不见得是DBA认为是最优的，这部分最耗费时间）
2. 当客户端向MySQL请求一条Query，命令解析器模块完成请求分类，区别出是SELECT并转发给MySQL Query Optimizer时，MySQL Query Optimizer首先会对整条Query进行优化，处理掉一些常 量表达式的预算，直接换算成常量值。并对Query中的查询条件进行简化和转换，如去掉一些无用或显而易见的条件、结构调整等。然后分析Query中的Hint信息(如果有)，看显示Hint信息是否可以完全确定该Query的执行计划。如果没有Hint或Hint信息还不足以完全确定执行计划，则会读取所涉及对象的统计信息，根据Query进行写相应的计算分析，然后再得出最后的执行计划。

### 2.2 MySQL常见瓶颈

1. `CPU`：CPU在饱和的时候一般发生在数据装入内存或从磁盘上读取数据时候
2. `IO`：磁盘I/O瓶颈发生在装入数据远大于内存容量的时候
3. `服务器硬件的性能瓶颈`：top,free, iostat和vmstat来查看系统的性能状态

### 2.3 Explain

#### 2.3.1 是什么

使用EXPLAIN关键字可以模拟优化器执行SQL查询语句，从而知道MySQL是如何处理你的SQL语句的。分析你的查询语句或是表结构的性能瓶颈。（查看执行计划）

#### 2.3.2 能干什么

- 表的读取顺序
- 数据读取操作的操作类型
- 哪些索引可以使用
- 哪些索引被实际使用
- 表之间的引用
- 每张表有多少行被优化器查询

#### 2.3.3 怎么用

**Explain + SQL语句**

+----+----------------+--------+------+--------------------+------+-----------+------+--------+--------+

| id  | select_type | table | type | possible_keys |  key | key_len |  ref  | rows  | extra |

+----+----------------+--------+------+--------------------+------+-----------+------+--------+--------+

各字段解释 >>>

`id`：**select查询的序列号，包含一组数字，表示查询中执行select子句或操作表的顺序。**

三种情况：

1. id相同，执行顺序由上至下
2. id不同，如果是子查询，id的序号会递增，id值越大优先级越高，越先被执行
3. id相同不同，同时存在

`select_type`：**查询类型，主要是用于区别普通查询、联合查询、子查询等的复杂查询。**

查询类型：

1. **SIMPLE**：简单的select查询，查询中不包含子查询或者UNION
2. **PRIMARY**：查询中若包含任何复杂的子查询，最外层查询则被标记为PRIMARY
3. **SUBQUERY**：在select或where列表中包含了子查询
4. **DERIVED**：在from列表中包含的子查询被标记为DERIVED(衍生)，MySQL会递归执行这些子查询，把结果放在临时表里
5. **UNION**：若第二个select出现在UNION之后，则被标记为UNION；若UNION包含在from子句的子查询中，外层select将被标记为：DERIVED
6. **UNION RESULT**：从UNION表获取结果的select

`table`：**显示这一行的数据是关于哪张表的。**

`type`：**显示查询使用了何种类型，<font color="red">从最好到最差依次是：</font>**

​	<font color="red"> system > const > eq_ref > ref > range > index > all</font>

一般来说，得保证查询至少达到range级别，最好能达到ref。

1. **system**：表只有一行记录(等于系统表)，这是const类型的特列，平时不会出现，这个也可以忽略不计
2. **const**：表示通过索引一次就找到了，const用于比较primary key或者unique索引。因为只匹配一行数据， 所以很快。如将主键置于where列表中，MySQL就能将该查询转换为一个常量
3. **eq_ref**：唯一性索引扫描，对于每个索引键，表中只有一条记录与之匹配。常见于主键或唯一索引扫描
4. **ref**：非唯一性索引扫描，返回匹配某个单独值的所有行。本质上也是一种索引访问，它返回所有匹配某个单独值的行，然而它可能会找到多个符合条件的行，所以他应该属于查找和扫描的混合体
5. **range**：只检索给定范围的行,使用一个索引来选择行。key列显示使用了哪个索引，一般就是在你的where语句中出现了between、<、>、in等的查询。这种范围扫描索引扫描比全表扫描要好，因为它只需要开始于索引的某一点， 而结束于另一点，不用扫描全部索引
6. **index**：Full Index Scan, index 与ALL区别为index类型只遍历索引树。这通常比ALL快，因为索引文件通常比数据文件小。(也就是说虽然all和Index都是读全表，但index是从索引中读取的，而all是从硬盘中读的)
7. **all**：Full Table Scan，将遍历全表以找到匹配的行

`possible_keys`：**显示可能应用在这张表中的索引，一个或多个。**查询涉及到的字段上若存在索引，则该索引将被列出，<font color="red">但不一定被查询实际使用</font>。

`key`：**实际使用的索引。如果为NULL，则没有使用索引。**查询中若使用了覆盖索引，则该索引仅出现在key列表中</font>。

`key_len`：**表示索引中使用的字节数。**可通过该列计算查询中使用的索引的长度。在不损失精确性的情况下，长度越短越好。key_ len显示的值为索引字段的最大可能长度，<font color="red">并非实际使用长度</font>，即key_ len是根据表定义计算而得，不是通过表内检索出的。

`ref`：**显示索引的哪一列被使用了，如果可能的话，是一个常数。**哪些列或常量被用于查找索引列上的值。（其实就是进一步说明，使用到的索引具体是哪一列）

`rows`：**根据表统计信息及索引选用情况，大致估算出找到所需的记录所需要读取的行数。**

`extra`：**包含不适合在其他列中显示但十分重要的额外信息**

1. **Using filesort**：说明MySQL会对数据使用一个外部的索引排序，而不是按照表内的索引顺序进行读取。MySQL中无法利用索引完成的排序操作称为“文件排序”

2. **Using tempopary**：使了用临时表保存中间结果,MySQL在对查询结果排序时使用临时表。常见于排序orderby和分组查询groupby

3. **Using index**：表示相应的select操作中使用了覆盖索引(Covering Index)，避免访问了表的数据行，效率不错!如果同时出现Using where，表明索引被用来执行索引键值的查找；

   如果没有同时出现Using where，表明索引用来读取数据而非执行查找动作。

4. **Using where**：表明使用了where过滤

5. Using join buffer：使用了连接缓存

6. impossible where：Where子句的值总是false，不能用来获取任何元组

7. select tables optimized away：在没有GROUPBY子句的情况下，基于索引优化MIN/MAX操作或者对于MyISAM存储引擎优化COUNT(*)操作，不必等到执行阶段再进行计算，查询执行计划生成的阶段即完成优化

8. distinct：优化distinct操作，在找到第一匹配的元组后即停止找同样值的动作

## 3. 索引优化

### 3.1 索引分析

#### 3.1.1 案例一：单表

查询category_ id 为1且comments大于1的情况下,views最多的article_ id。

![image-20210224171144586](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210224171144586.png)

分析：很显然，type是ALL，即最坏的情况。Extra 里还出现了Using filesort,也是最坏的情况。优化是必须的。

**开始优化：**

1. 新建索引`idx_article_ccv`

```sql
create index idx_article_ccv on article(category_id,comments,views);
```

![image-20210224171839779](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210224171839779.png)

分析：type变成了range，这是可以忍受的。但是extra里使用Using filesort仍是无法接受的。

但是我们已经建立了索引，为啥没用呢?

这是因为按照BTree索引的工作原理，先排序category_ id，如果遇到相同的category_ id则再排序comments，如果遇到相同的comments则再排序views。当comments字段在联合索引里处于中间位置时，因comments>1条件是一个范围值(所谓range)，MySQL无法利用索引再对后面的views部分进行检索，即range类型查询字段后面的索引无效。

删掉该索引，重新尝试。

```sql
DROP INDEX idx_article_ccv ON article;
```

> 查看当前表的索引情况：show index from mytable;

2. 新建索引`idx_article_cv`

```sql
create index idx_article_cv on article(category_id,views);
```

![image-20210224173213397](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210224173213397.png)

分析：可以看到，type变为了ref，Extra中的Using filesort也消失了，结果非常理想。

#### 3.1.2 案例二：两表

![image-20210224174148423](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210224174148423.png)

分析：type有All

**开始优化：**

Q：给哪个表加？加到左表还是右表？

1. 先试一下给右表book表建索引

```sql
ALTER TABLE 'book' ADD INDEX Y('card');
```

![image-20210224174836842](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210224174836842.png)

分析：可以看到第二行的type变为了ref，rows 也变成了1，优化比较明显。

2. 试一下给左表class表建索引

```sql
ALTER TABLE 'class' ADD INDEX Y('card');
```

![image-20210224175536496](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210224175536496.png)

分析：可以看到第二行的type变为了index，rows没变，优化不理想。

> 结论：`左连接left join，索引加右表`。这是由左连接特性决定的。LEFT JOIN条件用于确定如何从右表搜索行，左边一定都有，所以右边是我们的关键点，一定需要建立索引。同理右连接索引加左表。

#### 3.1.3 案例三： 三表

![image-20210225085627436](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225085627436.png)

分析：type都是All

1. 给book表和phone表card字段建索引

```sql
ALTER TABLE 'book' ADD INDEX Y('card');
ALTER TABLE 'phone' ADD INDEX Z('card');
```

![image-20210225090113376](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225090113376.png)

分析：后2行的type都是ref且总rows优化很好，效果不错。因此索引最好设置在需要经常查询的字段中。

#### 3.1.4 Join语句的优化

1. 尽可能减少Join语句中的NestedLoop的循环总次数：“**永远用小结果集驱动大的结果集**”
2. 优先优化NestedLoop的内层循环
3. **保证Join语句中被驱动表上Join条件字段已经被索引**
4. 当无法保证被驱动表的Join条件字段被索引且内存资源充足的前提下，不要太吝惜JoinBuffer的设置

### 3.2 索引失效

#### 3.2.1 索引失效的场景

假设有一个员工表staffs，表中有name，age，pos，add_time字段，并为该表建立如下索引：

```sql
ALTER TABLE staffs ADD INDEX idx_staffs_nameAgePos(name, age, pos);
```

1. 全值匹配我最爱

![image-20210225095113105](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225095113105.png)

2. <font color="red">最佳左前缀法则</font>

如果索引了多列，要遵守最左前缀法则。指的是查询从索引的最左前列开始并且**不跳过索引中的列**。

![image-20210225094315753](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225094315753.png)

3. 不在索引列上做任何操作(计算、函数、(自动or手动)类型转换)，会导致索引失效而转向全表扫描

4. 存储引擎不能使用索引中范围条件右边的列

![image-20210225100207323](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225100207323.png)

5. 尽量使用覆盖索引(只访问索引的查询(索引列和查询列一-致))，减少select*
6. mysql在使用不等于(!=或者<> )的时候无法使用索引会导致全表扫描
7. is null，is not null也无法使用索引
8. like以通配符开头("%ab...')mysql索引失效会变成全表扫描的操作

![image-20210225103243864](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225103243864.png)

**Q：解决like '%字符串%' 时索引不被使用的方法? ?**

**A：使用覆盖索引**

9. 字符串不加单引号索引失效
10. 少用or，用它来连接时会索引失效

#### 3.2.2 小总结

![image-20210225151534149](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225151534149.png)

#### 3.2.3 一般性建议

1. 对于单键索引，尽量选择针对当前query过滤性更好的索引
2. 在选择组合索引的时候，当前query中过滤性最好的字段在索引字段顺序中，位置越靠前越好
3. 在选择组合索引的时候，尽量选择可以能够包含当前query中的where子句中更多字段的索引
4. 尽可能通过分析统计信息和调整query的写法来达到选择合适索引的目的

## 4. 查询截取分析

### 4.1 查询优化

#### 4.1.1 <font color="red">永远小表驱动大表</font>

「小知识」：当A表的数据集小于B表的数据集时，用exists优于in

<img src="MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225154625342.png" onerror="this.src='/md/数据库/MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225154625342.png'" style="zoom:50%" />

> `公式`：SELECT .. FROM table WHERE EXISTS (subquery)

该语法可以理解为：将主查询的数据，放到子查询中做条件验证，根据验证结果(TRUE 或FALSE)来决定主查询的数据结果是否得以保留。

#### 4.1.2 Order By关键字优化

- ORDER BY子句，尽量使用Index方式排序,避免使用FileSort方式排序
- 尽可能在索引列上完成排序操作，遵照索引建的最佳左前缀
- 如果不在索引列上，filesort有两种算法：双路排序和单路排序

`双路排序`：MySQL4.1之前是使用双路排序,字面意思就是**两次扫描磁盘**，最终得到数据（读取行指针和orderby列，对他们进行排序，然后扫描已经排序好的列表，按照列表中的值重新从列表中读取对应的数据输出）。**从磁盘取排序字段，在buffer进行排序，再从磁盘取其他字段。**

取一批数据，要对磁盘进行了两次扫描，众所周知，I\O是很耗时的，所以在mysql4.1之后，

`单路排序`：从磁盘读取查询需要的所有列，按照order by列在buffer对它们进行排序，然后扫描排序后的列表进行输出，它的效率更快一些，避免了第二次读取数据。并且把随机IO变成了顺序IO，但是它会使用更多的空间，因为它把每一行都保存在内存中了。

```markdown
# 单路排序的问题：
	在sort_buffer中， 方法B比方法A要多占用很多空间，因为方法B是把所有字段都取出，所以有可能取出的数据的总大小超出了sort_buffer的容量，导致每次只能取sort_buffer容量大小的数据，进行排序(创建tmp文件，多路合并)，排完再取sort_buffer容量大小，再排....从而多次I/O。
	本来想省一次I/O操作，反而导致了量的I/O操作，反而得不偿失。
# 优化策略
	1. 增大sort_buffer_size参数的设置
	2. 增大max_length_for_sort_data参数的设置
# 提高Order By的速度
	1. Order by时select*是一个大忌，只Query需要的字段，这点非常重要。在这里的影响是:
		① 当Query的字段大小总和小于max_length_for_sort_data而且排序字段不是TEXT|BLOB类型时，会用改进后的算法——单路排序，否则用老算法——多路排序。
		② 两种算法的数据都有可能超出sort_buffer的容量，超出之后，会创建tmp文件进行合并排序，导致多次I/O，但是用单路排序算法的风险会更大一些,所以要提高sort_buffer_size。
	2. 尝试提高sort_buffer_size
	不管用哪种算法，提高这个参数都会提高效率，当然，要根据系统的能力去提高，因为这个参数是针对每个进程的
	3. 尝试提高max_length_for_sort_data
	提高这个参数，会增加用改进算法的概率。 但是如果设的太高，数据总容量超出sort_buffer_size的概率就增大，明显症状是高的磁盘I/O活动和低的处理器使用率
```

**「小总结」**

<img src="MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225171948718.png" onerror="this.src='/md/数据库/MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225171948718.png'" style="zoom:50%;" />

#### 4.1.3 Group By关键字优化

- group by实质是先排序后进行分组，遵照索引建的最佳左前缀
- 当无法使用索引列，增大max_length_for_sort_data参数的设置+增大sort_buffer_ size参数的设置
- where高于having，能写在where限定的条件就不要去having限定了

### 4.2 慢查询日志

#### 4.2.1 是什么

- MySQL的慢查询日志是MySQL提供的一种日志记录，它用来记录在MySQL中响应时间超过阀值的语句，具体指运行时间超过long_query_time值的SQL，则会被记录到慢查询日志中
- long_query_time的默认值为10，意思是运行10秒以上的语句
- 由他来查看哪些SQL超出了我们的最大忍耐时间值，比如一条SQL执行超过5秒钟，我们就算慢SQL，希望能收集超过5秒的SQL，结合之前explain进行全面分析

#### 4.2.2 怎么玩

1. **默认情况下，MySQL数据库没有开启慢查询日志，**需要我们手动来设置这个参数。当然，**如果不是调优需要的话，一般不建议启动该参数，**因为开启慢查询日志会或多或少带来一定的性能影响。慢查询日志支持将日志记录写入文件

2. 查看是否开启及如何开启？

```sql
默认：SHOW VARIABLES LIKE '%slow_query_log%';
```

<img src="MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225173535642.png" onerror="this.src='/md/数据库/MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225173535642.png'" style="zoom:50%;" />

```sql
开启：set global slow_query_log=1;
```

使用set global slow_query_log=1开启了慢查询日志**只对当前数据库生效**，如果MySQL重启后则会失效。

```markdown
# 如果要永久生效，就必须修改配置文件my.cnf (其它系统变量也是如此)
修改my.cnf文件，[mysqld]下增加或修改参数slow_query_log和slow_query_log_file后，然后重启MySQL服务器。也即将如下两行配置进my.cnf文件
	slow_query_log=1 
	slow_query_log_file=/var/ib/mysql/xxx-slow.log
	
关于慢查询的参数slow_query_log_file，它指定慢查询日志文件的存放路径，系统默认会给一个缺省的文件host_ _name-slow.log (如果没有指定参数slow_query_log_file的话)
```

3. 分析步骤

1）查看当前sql响应时间阈值

```sql
SHOW VARIABLES LIKE 'long_query_time%'
```

<img src="MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225175026612.png" onerror="this.src='/md/数据库/MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225175026612.png'" style="zoom:50%;" />

可以使用命令修改，也可以在my.cnf参数里面修改。假如运行时间正好等于long_query_time的情况，并不会被记录下来。也就是说，在mysql源码里是**判断大于long_query_time， 而非大于等于。**

2）修改响应时间阈值

```sql
set global long_query_time=3
```

问题：为什么设置后看不出变化？解决方式如下：

- 需要重新连接或新开一个会话才能看到修改值
- show **global** variables like 'long_ query_ time';

3）记录慢SQL并后续分析

```sql
模拟一条执行时间超过3秒的SQL：select sleep(4);
```

进入默认的慢日志文件查看：/var/ib/mysql/xxx-slow.log

![image-20210225181301740](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225181301740.png)

4）查询当前系统中有多少条慢查询记录

```sql
show global status like '%Slow_queries%';
```

<img src="MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225181633500.png" onerror="this.src='/md/数据库/MySQL%E7%B4%A2%E5%BC%95.assets/image-20210225181633500.png'" style="zoom:50%;" />

4. 配置版

【mysqlId】下配置：

```sql
slow_query_log=1;
slow_query_log_file=/var/lib/mysql/xxx-slow.log;
long_query_time=3;
log_ output=FILE;
```

#### 4.2.3 <font color="red">日志分析工具：mysqldumpslow</font>

​		在生产环境中，如果要手工分析日志，查找、分析SQL，显然是个体力活，MySQL提供了日志分析工具**mysqldumpslow**

1. 查看mysqldumpslow的帮助信息

```sql
mysqldumpslow --help
```

- s：是表示按照何种方式排序
- c：访问次数
- i：锁定时间
- r：返回记录
- t：查询时间
- al：平均锁定时间
- ar：平均返回记录数
- at：平均查询时间
- t：即为返回前面多少条的数据
- g：后边搭配一个正则匹配模式，大小写不敏感的

2. 工作常用参考

```markdown
# 得到返回记录集最多的10个SQL
mysqldumpslow -s r -t 10 /var/ib/mysql/xxx-slow.log

# 得到访问次数最多的10个SQL
mysqldumpslow -s c -t 10 /var/ib/mysql/xxx-slow.log

# 得到按照时间排序的前10条里面含有左连接的查询语句
mysqldumpslow -s t -t 10 -g "left join" /var/lib/mysql/xxx-slow.log

# 另外建议在使用这些命令时结合|和more使用，否则有可能出现爆屏情况
mysqldumpslow -s r -t 10 /var/lib/mysql/xxx-slow.log | more
```

### 4.3 批量数据脚本

目的：往表里插入1000W条数据

1. 建表
2. 设置参数log_bin_trust_function_creators

```markdown
创建函数，假如报错: This function has none of DETERMINISTIC……
# 由于开启过慢查询日志，因为我们开启了bin-log,我们就必须为我们的function指定一个参数。
show variables like 'log_bin_trust_function_creators';
set global log_bin_trust_function_creators=1; 

# 这样添加了参数以后，如果mysqld重启，上述参数又会消失，永久方法:
windows下 	my.init[mysqld]加上log_bin_trust_function_creators=1;
linux下 		/etc/my.cnf下my.cnf[mysqld]加上log_bin_trust_function_creators=1;
```

3. 创建函数，保证每条数据都不同

- 随机产生字符串

```sql
DELIMITER $$
CREATE FUNCTION rand_string(n INT) RETURNS VARCHAR(255)
BEGIN
DECLARE chars_str VARCHAR(1OO) DEFAULT 'abcdefghijklmnopqrstuvwxyzABCDEFJHIJKLMNOPQRSTUVWXYZ';
DECLARE return_str VARCHAR(255) DEFAULT '';
DECLARE i INT DEFAULT O;
WHILE i < n DO;
SET return_str=CONCAT(return_str,SUBSTRING(chars_str,FLOOR(1+RAND()*52),1));
SET i = i + 1;
END WHILE;
RETURN return_str;
END $$
```

- 随机产生部门编号

```sql
DELIMITER $$
CREATE FUNCTION rand_num()
RETURNS INT(5)
BEGIN
	DECLARE i INT DEFAULT O;
	SET i= FLOOR(100+RAND()*10);
RETURN i;
END $$
```

- 创建存储过程

```sql
DELIMITER $$
CREATE PROCEDURE insert_emp(IN START INT(10) ,IN max_num INT(10))
BEGIN
	DECLARE i INT DEFAULT 0;
	SET autocommit = 0;
	REPEAT
	SET i=i+1;
	INSERT INTO emp(empno,ename,job,mgr,hiredate,sal,comm,deptno) 
	VALUES((START+i),rand_string(6),'SALESMAN',0001,CURDATE(),2000,400,rand_num());
	UNTIL i = max_num
END REPEAT;
COMMIT;
END $$                                          
```

- 调用存储过程

```sql
DELIMITER;
CALL insert_emp(100001,500000);
```

### 4.4 Show Profile

#### 4.4.1 是什么

是MySQL提供可以用来分析当前会话中语句执行的资源消耗情况。可以用于SQL的调优的测量

默认情况下，参数处于关闭状态，并保存最近15次的运行结果

#### 4.4.2 分析步骤

1. 是否支持，看看当前的MySQL版本是否支持

```sql
Show variables like 'profiling';
```

2. 默认是关闭，使用前需要开启

```sql
set profiling=on;
```

3. 运行SQL
4. 查看结果

```sql
show profiles;
```

![image-20210226102934968](MySQL%E7%B4%A2%E5%BC%95.assets/image-20210226102934968.png)

5. 诊断SQL

```sql
show profile cpu, block io for query + Query_ID
```

「参数备注」：

- ALL：显示所有的开销信息
- BLOCK IO：显示块IO相关开销
- CONTEXT SWITCHES：上下文切换相关开销
- CPU：显示CPU相关开销信息
- IPC：显示发送和接收相关开销信息
- MEMORY：显示内存相关开销信息
- PAGE FAULTS：显示页面错误相关开销信息
- SOURCE：显示和Source_ function，Source_ file，Source_ line相关的开销信息
- SWAPS：显示交换次数相关开销的信息

6. <font color="red">日常开发需要注意的结论</font>

- converting HEAP to MyISAM查询结果太大，内存都不够用了往磁盘上搬了
- Creating tmp table创建临时表。拷贝数据到临时表，用完再删除
- Copying to tmp table on disk把内存中临时表复制到磁盘，危险!!!

- Locked

### 4.5 全局查询日志

<font color="red">仅限于测试环境使用，不能用于生产环境</font>

#### 4.5.1 配置启用

```markdown
在mysql的my.cnf中，设置如下：
# 开启
general_log=1
# 记录日志文件的路径
general_log_file=/path/logfile
# 输出格式
log_output=FILE
```

#### 4.5.2 编码启用

```markdown
> set global general_log=1;
> set global log_output='TABLE';

此后，你所编写的SQL语句，将会记录到MySQL库里的general_log表，可以用下面的命令查看
> select * from mysql.general_log;
```

## 5. MySQL锁机制

### 5.1 锁的基本概念

`锁`：锁是计算机协调多个进程或线程并发访问某一资源的机制。

在数据库中，除传统的计算资源(如CPU、RAM、I/O等)的争用以外，数据也是一种供许多用户共享的资源。如何保证数据并发访问的一致性、有效性是所有数据库必须解决的一个问题，锁冲突也是影响数据库并发访问性能的一个重要因素。从这个角度来说，锁对数据库而言显得尤其重要，也更加复杂。

### 5.2 三锁

#### 5.2.1 表锁(偏读)

【特点】偏向MyISAM存储引擎，开销小，加锁快；无死锁；锁定粒度大，发生锁冲突的概率最高，并发度最低。

**读锁会阻塞写，但是不会堵塞读。而写锁则会把读和写都堵塞。**

看看哪些表被锁了：

```sql
> show open tables;
```

**MyISAM的读写锁调度是写优先，这也是MyISAM不适合做写为主表的引擎。因为写锁后，其他线程不能做任何操作，大量的更新会使查询很难得到锁，从而造成永远阻塞**

#### 5.2.2 行锁(偏写)

【特点】

1. 向InnoDB存储引擎， 开销大，加锁慢；会出现死锁;锁定粒度最小，发生锁冲突的概率最低，并发度也最高
2. InnoDB与MyISAM的最大不同有两点：一是支持事务(TRANSACTION) ；二是采用了行级锁

【索引失效行锁变表锁】

某些情况下索引失效会导致行锁变表锁

【间隙锁】

1. 概念

当我们用范围条件而不是相等条件检索数据，并请求共享或排他锁时，InnoDB会给符合条件的已有数据记录的索引项加锁；对于键值在条件范围内但并不存在的记录，叫做“间隙(GAP)”，InnoDB也会对这个“间隙”加锁，这种锁机制就是所谓的间隙锁(Next-Key锁) 。

2. 危害

因为Query执行过程中通过过范围查找的话，他会锁定整个范围内所有的索引键值，即使这个键值并不存在。

间隙锁有一个比较致命的弱点，就是当锁定一个范围键值之后，即使某些不存在的键值也会被无辜的锁定，而造成在锁定的时候无法插入锁定键值范围内的任何数据。在某些场景下这可能会对性能造成很大的危害。

【如何锁定一行】

```sql
select * from mytable where id=1 for update;
```

【优化建议】

- 尽可能让所有数据检索都通过索引来完成，避免无索引行锁升级为表锁
- 合理设计索引，尽量缩小锁的范围
- 尽可能较少检索条件，避免间隙锁
- 尽量控制事务大小，减少锁定资源量和时间长度
- 尽可能低级别事务隔离

#### 5.2.3 页锁(了解)

【特点】开销和加锁时间界于表锁和行锁之间；会出现死锁；锁定粒度界于表锁和行锁之间，并发度一般。

