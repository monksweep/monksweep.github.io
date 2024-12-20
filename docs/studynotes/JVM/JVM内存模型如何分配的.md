# JVM内存模型如何分配的

## JVM内存模型的划分

>  由于我们生产环境使用的虚拟机HotSpot 居多，所以下面的描述都是基于HotSpot 虚拟机而言的，对于其他类型的虚拟机，如 JRockit（Oracle）、J9（IBM） 可能并不太一样

根据虚拟机规范，JVM的内存分为 堆、虚拟机栈、本地方法栈、程序计数器、本地方法栈5部分

JDK 1.8 同 JDK 1.7 比，最大的差别就是：元数据区取代了永久代。元空间的本质和永久代类似，都是对 JVM 规范中方法区的实现。不过元空间与永久代之间最大的区别在于：元数据空间并不在虚拟机中，而是使用本地内存

![在这里插入图片描述](images/JVM内存模型如何分配的/20190706155611749.PNG)



1. 虚拟机栈
   1. 每个线程有一个私有的栈，随着线程的创建而创建。栈里面存着的是一种叫“栈帧”的东西，每个方法会创建一个栈帧，栈帧中存放了局部变量表（基本数据类型和对象引用）、操作数栈、方法出口等信息。栈的大小可以固定也可以动态扩展。当栈调用深度大于JVM所允许的范围，会抛出StackOverflowError的错误
   2. 虚拟机栈的特点
      1. 局部变量表随着栈帧的创建而创建，它的大小在编译时确定，创建时只需分配事先规定的大小即可。在方法运行过程中，局部变量表的大小不会发生改变
      2. Java 虚拟机栈也是线程私有，随着线程创建而创建，随着线程的结束而销毁
      3. Java 虚拟机栈会出现两种异常：StackOverFlowError （若 Java 虚拟机栈的大小不允许动态扩展，那么当线程请求栈的深度超过当前 Java 虚拟机栈的最大深度时，抛出 StackOverFlowError 异常）和 OutOfMemoryError（若允许动态扩展，那么当线程请求栈时内存用完了，无法再动态扩展时，抛出 OutOfMemoryError 异常）

![jvm-stack](images/JVM内存模型如何分配的/1460000015398968)

1. 本地方法栈
   1. 本地方法栈是为 JVM 运行 Native 方法准备的空间，由于很多 Native 方法都是用 C 语言实现的，所以它通常又叫 C 栈。它与 Java 虚拟机栈实现的功能类似，只不过本地方法栈是描述本地方法运行过程的内存模型。本地方法被执行时，在本地方法栈也会创建一块栈帧，用于存放该方法的局部变量表、操作数栈、动态链接、方法出口信息等。方法执行结束后，相应的栈帧也会出栈，并释放内存空间。也会抛出 StackOverFlowError 和 OutOfMemoryError 异常。
2. PC 寄存器计数器
   1. PC 寄存器，也叫程序计数器。JVM支持多个线程同时运行，每个线程都有自己的程序计数器。倘若当前执行的是 JVM 的方法，则该寄存器中保存当前执行指令的地址；倘若执行的是native 方法，则PC寄存器中为空
3. 堆
   1. 堆内存是 JVM 所有线程共享的部分，在虚拟机启动的时候就已经创建。所有的对象和数组都在堆上进行分配。这部分空间可通过 GC 进行回收。当申请不到空间时会抛出 OutOfMemoryError
   2. 堆的特点：
      1. 线程共享，整个 Java 虚拟机只有一个堆，所有的线程都访问同一个堆。而程序计数器、Java 虚拟机栈、本地方法栈都是一个线程对应一个
      2. 在虚拟机启动时创建
      3. 垃圾回收的主要场所
      4. 可分为：新生代(Eden区 From Survior To Survivor)、老年代
4. 方法区
   1. Java 虚拟机规范中定义方法区是堆的一个逻辑部分。
   2. 方法区也是所有线程共享。主要用于存储已经被虚拟机加载的类的信息、常量池、方法数据、方法代码等。方法区逻辑上属于堆的一部分，但是为了与堆进行区分，通常又叫 非堆 。需要注意的是，方法区只是规范上面的一个逻辑概念，并不是真实的物理存储的命名
5. 直接内存（堆外内存）
   1. 直接内存是除 Java 虚拟机之外的内存，但也可能被 Java 使用，直接内存的大小不受 Java 虚拟机控制，但既然是内存，当内存不足时就会抛出 OutOfMemoryError 异常
   2. 直接内存与堆内存比较：
      1. 直接内存申请空间耗费更高的性能
      2. 直接内存读取 IO 的性能要优于普通的堆内存

## JVM内存模型各部分的存储信息

## ![](images/JVM内存模型如何分配的/javammode.png)





## 针对JDK6、JDK7、JDK8三个版本的JVM内存模型调整说明

### 对永久代PermGen的说明

- 永久代是方法区在hotspot的一个具体实现。通过在**运行时数据区域开辟空间**实现方法区。
- hotspot jdk7 之前的永久代，比较完整
- 从jdk7以后方法区就“四分五裂了”，不再是在单一的一个去区域内进行存储
- 在jdk8，移除了永久代，被Metsspace取代了，且Metsspace不在JVM堆内，放入了本地内存，元空间也就成了方法区的主要存放位置

绝大部分 Java 程序员应该都见过 **java.lang.OutOfMemoryError: PermGen space ** 这个异常

这里的 “PermGen space”其实指的就是方法区。不过方法区和“PermGen space”又有着本质的区别。前者是 JVM 的规范，而后者则是 JVM 规范的一种实现，并且**只有 HotSpot 才有 “PermGen space”，而对于其他类型的虚拟机，如 JRockit（Oracle）、J9（IBM） 并没有“PermGen space”**。由于方法区主要存储类的相关信息，所以对于动态生成类的情况比较容易出现永久代的内存溢出。最典型的场景就是，在 jsp 页面比较多的情况，容易出现永久代内存溢出

### 对Metaspace元空间的说明

1. 元空间的本质和永久代类似，都是对JVM规范中方法区的实现。元空间通过**在本地内存区域开辟空间实现方法区**。**元空间并不在虚拟机中，而是使用本地内存，所以默认情况下，元空间的大小仅受本地内存限制**，但可以通过以下参数来指定元空间的大小：

```
-XX:MetaspaceSize，初始空间大小，达到该值就会触发垃圾收集进行类型卸载，同时GC会对该值进行调整：如果释放了大量的空间，就适当降低该值；如果释放了很少的空间，那么在不超过MaxMetaspaceSize时，适当提高该值。
-XX:MaxMetaspaceSize，最大空间，默认是没有限制的。
除了上面两个指定大小的选项以外，还有两个与 GC 相关的属性：
-XX:MinMetaspaceFreeRatio，在GC之后，最小的Metaspace剩余空间容量的百分比，减少为分配空间所导致的垃圾收集
-XX:MaxMetaspaceFreeRatio，在GC之后，最大的Metaspace剩余空间容量的百分比，减少为释放空间所导致的垃圾收集
```



其实，移除永久代的工作从JDK1.7就开始了，JDK1.7中，存储在永久代的部分数据就已经转移到了Java Heap或者是 Native Heap。但永久代仍存在于JDK1.7中，并没完全移除。

譬如：

符号引用(Symbols)转移到了native heap；

字面量(interned strings)转移到了java heap；

类的静态变量(class statics)转移到了java heap



### 元空间特点

1. **类及相关的元数据的生命周期与类加载器的一致**，如果GC发现某个类加载器不再存活了，才会把相关的空间整个回收掉
2. 每个类加载器有专门的存储空间
3. 只进行线性分配，省掉了GC扫描及压缩的时间
4. 元空间里的对象的位置是固定的



## JVM内存划分调整的几个原因点分析

1. 字符串存在永久代中，容易出现性能问题和内存溢出
2. 类及方法的信息等比较难确定其大小，因此对于永久代的大小指定比较困难，太小容易出现永久代溢出，太大则容易导致老年代溢出
3. 永久代会为 GC 带来不必要的复杂度，并且回收效率偏低

