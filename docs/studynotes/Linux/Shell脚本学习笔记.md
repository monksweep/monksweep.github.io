# Shell脚本学习笔记

## 1. Shell脚本入门

### 1.1 脚本格式

脚本以`#!/bin/bash`开头（指定解析器）

### 1.2 第一个Shell脚本

1. 需求：创建一个Shell脚本，输出helloworld
2. 案例实操

```shell
Lmg12580:learn wangyg$ touch helloworld.sh
Lmg12580:learn wangyg$ vi helloworld.sh 
#!/bin/bash
echo "hello world shell"
```

3. 执行方式

1）方式一：

```sh
Lmg12580:learn wangyg$ sh helloworld.sh 
hello world shell
```

2）方式二：

```sh
Lmg12580:learn wangyg$ ./helloworld.sh 
-bash: ./helloworld.sh: Permission denied
Lmg12580:learn wangyg$ chmod 777 helloworld.sh 
Lmg12580:learn wangyg$ ./helloworld.sh 
hello world shell
```

> 注意：第一种执行方法，本质是bash解析器帮你执行脚本，所以脚本本身不需要执行权限。第二种执行方法，本质是脚本需要自己执行，所以需要执行权限。

### 1.3 第二个Shell脚本：多命令处理

1. 需求：

在/Users/wangyg/目录下创建一个test.txt，在test.txt文件中增加"learn shell"。

2. 案例实操

```sh
Lmg12580:learn wangyg$ touch batch.sh
Lmg12580:learn wangyg$ vi batch.sh 
#!/bin/bash
cd /Users/wangyg/
touch test.txt
echo "learn shell" >> test.txt
Lmg12580:learn wangyg$ sh batch.sh
Lmg12580:~ wangyg$ cat /Users/wangyg/test.txt 
learn shell
```

## 2. Shell中的变量

### 2.1 系统变量

常用系统变量

```markdown
$HOME、$PWD、$SHELL、$USER等
```

### 2.2 自定义变量

1. 基本语法

- 定义变量：`变量=值`

- 撤销变量：`unset 变量`

- 声明静态变量：readonly 变量，注意：不能unset

2. 变量定义规则

- 变量名称可以由字母、数字和下划线组成，但是不能以数字开头，==环境变量名建议大写==

- <font color="red">等号两侧不能有空格</font>
- 在bash中，变量默认类型都是字符串类型，无法直接进行数值运算
- 变量的值如果有空格，需要使用双引号或单引号括起来

> 可把变量提升为全局环境变量，可供其他Shell程序使用，语法：`export 变量`

### 2.3 特殊变量：$n

1. 基础语法

`$n` ( 功能描述: n为数字，$0代表该脚本名称，S1-S9 代表第一到第九个参数，十以上的参数需要用大括号包含，如${10}) 

2. 案例实操

```sh
Lmg12580:learn wangyg$ touch param.sh
Lmg12580:learn wangyg$ vi param.sh 
#!/bin/bash
echo "$0 $1 $2"
Lmg12580:learn wangyg$ sh param.sh 
param.sh  
Lmg12580:learn wangyg$ sh param.sh p1
param.sh p1 
Lmg12580:learn wangyg$ sh param.sh p1 p2
param.sh p1 p2
Lmg12580:learn wangyg$ sh param.sh p1 p2 p3
param.sh p1 p2
```

### 2.4 特殊变量：$#

1. 基本语法

`$#` (功能描述:获取所有输入参数个数，常用于循环)

2. 案例实操

获取输入参数的个数

```sh
Lmg12580:learn wangyg$ vi param.sh
Lmg12580:learn wangyg$ cat param.sh 
#!/bin/bash
echo "$0 $1 $2"
echo $#
Lmg12580:learn wangyg$ sh param.sh 
param.sh  
0
Lmg12580:learn wangyg$ sh param.sh p1
param.sh p1 
1
Lmg12580:learn wangyg$ sh param.sh p1 p2 p3
param.sh p1 p2
3
Lmg12580:learn wangyg$ sh param.sh p1 p2 p4
param.sh p1 p2
3
```

### 2.5 特殊变量：$*、$@

1. 基本语法

   $*   ( 功能描述：这个变量代表命令行中所有的参数，$*把所有的参数看成一个整体)

​	$@ ( 功能描述：这个变量也代表命令行中所有的参数，不过$@把每个参数区分对待)

2. 案例实操

```sh
Lmg12580:learn wangyg$ vi param.sh 
#!/bin/bash
echo "$0 $1 $2"
echo $#
echo $*
echo $@
Lmg12580:learn wangyg$ sh param.sh p1 p2
param.sh p1 p2
2
p1 p2
p1 p2
```

### 2.6 特殊变量：$?

1. 基本语法

`$?` ( 功能描述：最后一次执行的命令的返回状态。如果这个变量的值为0，证明上一个命令正确执行：如果这个变量的值为非0 (具体是哪个数，由命令自己来决定)，则证明上一个命令执行不正确)。

2. 案例实操

判断helloworld.sh脚本是否执行正确

```sh
Lmg12580:learn wangyg$ sh helloworld.sh 
hello world shell
Lmg12580:learn wangyg$ echo $?
0
```

## 3. 运算符

1. 基本语法

- "$((运算式))"或"$[运算式]"
- expr +，-，\\*，/，%  加减乘除，取余

==注意：expr运算符间要有空格==

2. 案例实操

- 计算3+2的值

```sh
Lmg12580:learn wangyg$ expr 3 + 2
5
```

- 计算（2+3）* 4的值

  - expr一步完成计算

  ```
  Lmg12580:learn wangyg$ expr `expr 2 + 3` \* 4
  20
  ```

  - 采用$[运算式]方式

  ```sh
  Lmg12580:learn wangyg$ s=$[(2+3)*4]
  Lmg12580:learn wangyg$ echo $s
  20
  ```

## 4. 条件判断

1. 基本语法

[ condition ] （==注意condition前后要有空格==）

注意：条件非空即为true， [ file ]返回true，[] 返回false。

2. 常用判断条件

- 两个整数之间比较

<img src="Shell%E8%84%9A%E6%9C%AC%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210302163154041.png" alt="image-20210302163154041" style="float:left" />

- 按照文件权限进行判断

<img src="Shell%E8%84%9A%E6%9C%AC%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210302163254602.png" alt="image-20210302163254602" style="float:left" />

- 按照文件类型进行判断

<img src="Shell%E8%84%9A%E6%9C%AC%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20210302163402839.png" alt="image-20210302163402839" style="float:left" />

3. 案例实操

23是否大于等于22

```sh
Lmg12580:learn wangyg$ [ 23 -ge 22 ]
Lmg12580:learn wangyg$ echo $?
0
```

## 5. 流程控制(重点)

### 5.1 if 判断

1. 基本语法

```shell
if [ 条件判断式 ];then
	程序
fi
或者
if [ 条件判断式 ]
	then
		程序
fi
```

注意事项：

- [ 条件判断式 ]中括号和条件判断式之间必须有空格
- <font color="red">if后要有空格</font>

2. 实际操作

1）输入一个数字，如果是1，则输出one，如果是2，则输出two，如果是其他，什么也不输出

```sh
Lmg12580:learn wangyg$ touch if.sh
Lmg12580:learn wangyg$ vi if.sh 
#!/bin/bash
if [ $1 -eq "1" ];then
	echo "one"
elif [ $1 -eq "2" ];then
	echo "two"
fi
Lmg12580:learn wangyg$ sh if.sh 1
one
Lmg12580:learn wangyg$ sh if.sh 2
two
Lmg12580:learn wangyg$ sh if.sh 3
```

### 5.2 case 语句

1. 基本语法

```sh
case $变量名 in
	"值1")
		如果变量的值等于值1，则执行程序1
		;;
	"值2")
		如果变量的值等于值2，则执行程序2
		;;
	...省略其他分支...
	*)
		如果变量的值都不是以上的值，则执行此程序
		;;
esac
```

注意事项：

- case 行尾必须为单词“in”，每一个模式匹配必须以右括号“)”结束
- 双分号 “;;”表示命令序列结束，相当于java中的break
- 最后的“*)”表示默认模式，相当于java中的default

2. 案例实操

1）输入一个数字，如果是1，则输出one，如果是2，则输出two，如果是其他，输出other

```sh
Lmg12580:learn wangyg$ touch case.sh
Lmg12580:learn wangyg$ vi case.sh
#!/bin/bash
case $1 in
 "1")
	echo "one"
  ;;
 "2")
	echo "two"
  ;;
  *)
	echo "other"
  ;;
esac
Lmg12580:learn wangyg$ sh case.sh 1
one
Lmg12580:learn wangyg$ sh case.sh 2
two
Lmg12580:learn wangyg$ sh case.sh 3
other
```

### 5.3 for循环

1. 基本语法1

```sh
for(( 初始值；循环控制条件；变量变化 ))
	do
		程序
	done
```

2. 案例实操

1）从1加到100

```sh
Lmg12580:learn wangyg$ touch for1.sh
Lmg12580:learn wangyg$ vi for1.sh
#!/bin/bash
s=0
for((i=0;i<=100;i++))
{
 s=$[$s+$i]
}
echo $s
Lmg12580:learn wangyg$ sh for1.sh 
5050
```

3. 基本语法2

```sh
for 变量 in 值 1 值 2 值 3...
 do
  程序
 done
```

4. 案例实操

打印所有输入参数

```sh
Lmg12580:learn wangyg$ touch for2.sh
Lmg12580:learn wangyg$ vi for2.sh
#!/bin/bash
for i in $*
do
 echo $i
done
Lmg12580:learn wangyg$ sh for2.sh p1
p1
Lmg12580:learn wangyg$ sh for2.sh p1 p2
p1
p2
```

```sh
Lmg12580:learn wangyg$ vi for2.sh 
#!/bin/bash
for i in "$*"
do
 echo $i
done

for i in "$@"
do
 echo $i
done
Lmg12580:learn wangyg$ sh for2.sh p1 p2
p1 p2
p1
p2
```

### 5.4 while 案例

1. 基本语法

```sh
while [ 条件判断式 ]
 do
 	程序
 done
```

2. 案例实操

1）从1加到100

```sh
Lmg12580:learn wangyg$ touch while.sh
Lmg12580:learn wangyg$ vi while.sh 
#!/bin/bash
s=0
i=1
while [ $i -le 100 ]
do
 s=$[$s+$i]
 i=$[$i+1]
done
echo $s
Lmg12580:learn wangyg$ sh while.sh 
5050
```

## 6. read读取控制台输入

1. 基本语法

read(选项)(参数)

选项：

​	-p：指定读取值时的提示符

​	-t：指定读取值时的等待时间（秒）

参数：

​	变量：指定读取值的变量名

2. 案例操作

1）提示7s内，读取控制台输入的名称

```sh
Lmg12580:learn wangyg$ touch read.sh
Lmg12580:learn wangyg$ vi read.sh 
#!/bin/bash
read -t 7 -p "Enter u name in 7s" NAME
echo $NAME
Lmg12580:learn wangyg$ sh read.sh 
Enter u name in 7s
Lmg12580:learn wangyg$ sh read.sh 
Enter u name in 7s zhangsan
zhangsan
Lmg12580:learn wangyg$ 
```

## 7. 函数

### 7.1 系统函数

1. basename基本语法

```sh
basename [string/pathname][suffix]
```

功能描述：basename 命令会删掉所有的前缀包括最后一个(“/”) 字符，然后将字符串显示出来。

选项：

​	suffix为后缀，如果suffx被指定了， basename会将pathname或string中的suffix去掉

2. 案例实操

1）截取/Users/wangyg/test.txt路径的文件名称

```sh
Lmg12580:~ wangyg$ basename /Users/wangyg/learn/test.txt 
test.txt
Lmg12580:~ wangyg$ basename /Users/wangyg/learn/test.txt .txt
test
```

3. dirname基本语法

```sh
dirname 文件绝对路径
```

功能描述：从给定的包含绝对路径的文件名中去除文件名。(非目录的部分)，然后返回剩下的路径(目录的部分) 

4. 案例实操

1）获取test.txt文件的路径

```sh
Lmg12580:learn wangyg$ dirname /Users/wangyg/learn/test.txt 
/Users/wangyg/learn
```

### 7.2 自定义函数

1. 基本语法

```sh
[ function ] funname[()]
{
	Action;
	[return int;]
}
```

2. 经验技巧

1）必须在调用函数地方之前，先声明函数，shell脚本是逐行运行。不会像其它语言一样先编译

2）函数返回值，只能通过$?系统变量获得，可以显示加: return 返回，如果不加，将以最后一条命令运行结果，作为返回值。return 后跟数值n(0-255)

3. 案例实操

1）计算两个输入参数的和

```sh
Lmg12580:learn wangyg$ touch sum.sh
Lmg12580:learn wangyg$ vi sum.sh
#!/bin/bash

function sum()
{
  s=0
  s=$[$1+$2]
  echo $s
}
read -p "input your param1:" P1
read -p "input your param2:" P2
sum $P1 $P2
Lmg12580:learn wangyg$ sh sum.sh 
input your param1:1
input your param2:2
3
```

## 8. Shell工具(重点)

### 8.1 cut

cut的工作就是“剪”，具体的说就是在文件中负责剪切数据用的。cut命令从文件的每一行剪切字节、字符和字段并将这些字节、字符和字段输出

1. 基本用法

```sh
cut [选项参数] filename
```

说明：默认分隔符是制表符

2. 选项参数说明

| 选项参数 | 功能                         |
| -------- | ---------------------------- |
| -f       | 列号，提取第几列             |
| -d       | 分隔符，按照指定分隔符分割列 |

3. 案例实操

0）数据准备

```sh
Lmg12580:learn wangyg$ touch cut.txt
Lmg12580:learn wangyg$ vi cut.txt 
bei shan
jing xi
wo  wo    #注意这三行是两个空格
lai  lai
le  le
```

1）切割cut.txt第一列

```sh
Lmg12580:learn wangyg$ cut -d " " -f 1 cut.txt 
bei
jing
wo
lai
le
```

2）切割cut.txt第二、三列

```sh
Lmg12580:learn wangyg$ cut -d " " -f 2,3 cut.txt 
shan
xi
 wo
 lai
 le
```

3）在cut.txt文件中切割出jing

```sh
Lmg12580:learn wangyg$ cat cut.txt | grep "jing" | cut -d " " -f 1
jing
```

4）选取系统PATH变量值，第2个“ : ”开始后的所有路径

```sh
Lmg12580:learn wangyg$ echo $PATH | cut -d : -f 3-
#内容太多，不展示了
```

5）切割ifconfig后打印的IP地址

```sh
Lmg12580:learn wangyg$ ifconfig en0 | grep "inet " | cut -d " " -f 2
10.53.2.131
```

### 8.2 sed

sed是一种流编辑器，它一次处理一行内容。处理时，把当前处理的行存储在临时缓冲区中，称为“模式空间”，接着用sed命令处理缓冲区中的内容，处理完成后，把缓冲区的内容送往屏幕。接着处理下一行，这样不断重复，直到文件末尾。文件内容并没有改变，除非你使用重定向存储输出。

1. 基本用法

```sh
sed [选项参数] 'command' filename
```

2. 选项参数说明

| 选项参数 | 功能                                |
| -------- | ----------------------------------- |
| -e       | 直接在指令列模式上进行sed的动作编辑 |

3. 命令功能描述（常用）

| 命令 | 功能描述                                |
| ---- | --------------------------------------- |
| a    | 新增，a的后面可以接字符串，在下一行出现 |
| d    | 删除                                    |
| s    | 查找并替换                              |

4. 案例实操

mac的sed命令有点老，和linux不一致，这里切换成linux

0）数据准备

```sh
[root@localhost ~]# touch sed.txt
[root@localhost ~]# vi sed.txt 
bei shan
jing xi
wo  wo
lai  lai

le  le
```

1）将“shang hai”这个字符串插入到sed.txt第二行下，打印

```sh
[root@localhost ~]# sed "2a shang hai" sed.txt 
bei shan
jing xi
shang hai
wo  wo
lai  lai

le  le
```

==注意：文件并没有改变==

2）删除sed.txt文件所有包含wo的行

```sh
[root@localhost ~]# sed '/wo/d' sed.txt 
bei shan
jing xi
lai  lai

le  le
```

3）将sed.txt文件中wo替换为ni

```sh
[root@localhost ~]# sed 's/wo/ni/g' sed.txt 
bei shan
jing xi
ni  ni
lai  lai

le  le
# /g：所有匹配内容都替换，globle
```

4）将sed.txt文件中的第二行删除并将wo替换为ni

```sh
[root@localhost ~]# sed -e '2d' -e 's/wo/ni/g' sed.txt 
bei shan
ni  ni
lai  lai

le  le
```

### 8.3 awk

一个强大的文本分析工具，把文件逐行的读入，以空格为默认分隔符将每行切片，切开的部分再进行分析处理。

1. 基本用法

```sh
awk [选项参数] 'pattern1{action1} pattern2{action2}...' filename
```

pattern：表示awk在数据中查找的内容，就是匹配模式

action：在找到匹配内容时所执行的一系列命令

2. 选项参数说明

| 选项参数 | 功能                 |
| -------- | -------------------- |
| -F       | 指定输入文件拆分符   |
| -v       | 赋值一个用户定义变量 |

3. 案例实操

0）数据准备

```sh
[root@localhost ~]# cp /etc/passwd ~/
```

1）搜索passwd文件以root关键字开头的所有行，并输出该行的第7列

```sh
[root@localhost ~]# awk -F: '/^root/{print $7}' passwd 
/bin/bash
```

2）搜索passwd文件以root关键字开头的所有行，并输出该行的第1列和第7列，中间以“，”分隔

```sh
[root@localhost ~]# awk -F: '/^root/{print $1","$7}' passwd 
root,/bin/bash
```

==注意：只有匹配了pattern的行才会执行action==

3）只显示passwd的第一列和第七列，以“，”分隔，且在所有行前面添加列名"user，shell"，在最后一行添加"abc,/bin/qwe"。

```sh
[root@localhost ~]# awk -F: 'BEGIN{print "user,shell"}{print $1","$7} END {print "abc,/bin/qwe"}' passwd
user,shell
root,/bin/bash
bin,/sbin/nologin
省略
.........
sshd,/sbin/nologin
postfix,/sbin/nologin
mysql,/bin/bash
rabbitmq,/sbin/nologin
abc,/bin/qwe
```

4）将passwd文件中的用户id增加数值1并输出

```sh
[root@localhost ~]# awk -F: -v i=1 '{print $3+i}' passwd
1
2
3
省略
.....
90
28
999
```

4. awk的内置变量

| 变量     | 说明                                   |
| -------- | -------------------------------------- |
| FILENAME | 文件名                                 |
| NR       | 已读的记录数                           |
| NF       | 浏览记录的域的个数（切割后，列的个数） |

5. 案例实操

1）统计passwd文件名，每行的行数，每行的列数

```sh
[root@localhost ~]# awk -F: '{print FILENAME","NR","NF}' passwd 
passwd,1,7
passwd,2,7
passwd,3,7
省略
..........
passwd,18,7
passwd,19,7
passwd,20,7
```

2）切割IP

```sh
[root@localhost ~]# ifconfig eth0 | grep "inet " | awk -F " " '{print $2}'
172.16.11.109
```

3）查询sed.txt中空行所在的行号

```sh
[root@localhost ~]# awk '/^$/{print NR}' sed.txt 
5
```

### 8.4 sort

sort命令在Linux里非常有用，它将文件进行排序，并将排序结果标准输出。

1. 基本语法

```sh
sort(选项)（参数）
```

| 选项 | 说明                     |
| ---- | ------------------------ |
| -n   | 依照数值的大小排序       |
| -r   | 以相反的顺序来排序       |
| -t   | 设置排序时所用的分隔字符 |
| -k   | 指定需要排序的列         |

参数：指定待排序的文件列表

2. 案例实操

0）数据准备

```sh
[root@localhost ~]# touch sort.sh
[root@localhost ~]# vi sort.sh 
bb:40:5.4
bd:20:4.2
xz:50:2.3
cls:10:3.5
ss:30:l.6
```

1）按照“：”分割后的第三列倒序排序

```sh
[root@localhost ~]# sort -t: -nrk 3 sort.sh 
bb:40:5.4
bd:20:4.2
cls:10:3.5
xz:50:2.3
ss:30:l.6
```

