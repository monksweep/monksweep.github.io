# ✅ JDK1.7和1.8中ConcurrentHashMap的区别

| 比较 | ConcurrentHashMap1.7 | ConcurrentHashMap1.8 |
| --- | --- | --- |
| 数据结构 | Segment分段锁 | 数组+链表+红黑树 |
| 线程安全机制 | ReentrantLock | synchronized |
| 锁的粒度 | 对需要操作的Segment加锁 | 对每个数组元素加锁 |
| 时间复杂度 | O(N) | O(LogN) |

1. 数据结构：取消了Segment分段锁的数据结构，取而代之的是数组+链表+红黑树的结构。

2. 保证线程安全机制：
    1. JDK1.7中采用Segment的分段锁机制实现线程安全，其中Segment继承自ReentrantLock。
    2. JDK1.8中采用分段锁+CAS保证线程安全，分段锁基于synchronized关键字实现。

3. 锁的粒度：
    1. JDK1.7是对需要进行数据操作的Segment加锁。
    2. JDK1.8调整为对每个数组元素加锁（Node）。
    
4. 查询时间复杂度：
    1. JDK1.7遍历链表O(n)
    2. JDK1.8遍历红黑树O(LogN)

