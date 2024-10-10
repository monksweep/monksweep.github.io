# ELK配置说明文档

## 一、安装filebeat

说明：在**项目的部署机器**上安装filebeat，用于收集日志

下载地址：https://www.elastic.co/cn/downloads/beats/filebeat

1. 将filebeat.tar.gz安装包上传到/opt/目录下

```sh
[root@momt_mbscost_ip023103 opt]# pwd
/opt
[root@momt_mbscost_ip023103 opt]# ls
filebeat.tar.gz
```

2. 解压缩

```sh
[root@momt_mbscost_ip023103 opt]# tar -zxvf filebeat.tar.gz
```

3. 进入解压后的filebeat目录，备份filebeat.yml

```sh
[root@momt_mbscost_ip023103 opt]# cd filebeat
[root@momt_mbscost_ip023103 filebeat]# cp filebeat.yml filebeat.yml.bak
```

4. 修改filebeat.yml配置为以下内容

```yaml
filebeat.prospectors:
- input_type: log
  paths:
		# 指定监控的日志
    - /application/springcloud/logs/*

  multiline.pattern: '^\s*(\d{4}|\d{2})\-(\d{2}|[a-zA-Z]{3})\-(\d{2}|\d{4})'
  multiline.negate: true
  multiline.match: after
  multiline.max_lines: 1000
  
  # 标识，可自定义
  fields:
    tag: mbs-cost
  encoding: utf-8

fields_under_root: true
# 收集到日志后输出到logstash
output.logstash:
  hosts: ["10.53.23.214:5044"]
```

> 1. 本文档仅针对部署在linux上的项目，windows环境略有不同
> 2. 配置修改完成后不要立即启动，配置完logstash并重启logstash后再启动filebeat

## 二、配置Logstash

1. 登陆堡垒机，找到主机名为`10.53.23.214_linux_elk_1`的机器
2. 进入logstash目录

```sh
[root@localhost ~]# cd /opt/logstash
```

3. 修改配置文件test.conf，找到filter并在里面追加以下内容

```json
filter {
  if [fields][tag] == "mbs-cost" {
        grok {
                remove_field => ["beat.hostname","_type","@version","_id"]
        }
        mutate{
          			# ip地址改为项目部署机器地址
                add_field => { "client-host" => "10.53.23.103"}
        }
    }
}
```

4. 找到output块，在下面追加以下内容

```json
output {
  if [fields][tag] == "mbs-cost" {
     elasticsearch {
         hosts => ["10.53.23.214:9200"]
         index => "mbs-cost-%{+YYYY.MM.dd}"
                }
        }
}
```

5. 找到logstash进程并杀掉

```sh
[root@localhost logstash]# ps -aux|grep logstash
[root@localhost logstash]# kill -9 11649
```

6. 重启logstash

```sh
[root@localhost logstash]# nohup bin/logstash -f test.conf >logs/logstash.log 2>&1 &
```

7. 启动filebeat

```sh
[root@momt_mbscost filebeat]# pwd
/opt/filebeat
[root@momt_mbscost filebeat]# nohup ./filebeat -e -c filebeat.yml > filebeat.log 2>&1 &
```

## 三、查看ElasticSearch

1. es地址：http://10.53.23.214:9100/
2. 根据关键词`mbs-cost`搜索索引库

![image-20210407161024918](ELK%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3.assets/image-20210407161024918.png)

3. 看到该索引库证明前面的配置成功了！

## 四、配置Kibana

1. 进入Kibana平台

地址：http://10.53.23.215:5601/app/kibana#/

2. 进入 管理 > 索引模式

<img src="ELK%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3.assets/image-20210407161437100.png" alt="image-20210407161437100" style="zoom:50%; float: left" />

3. 创建索引模式

![image-20210407162000280](ELK%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3.assets/image-20210407162000280.png)

4. 完成创建

![image-20210407162145605](ELK%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3.assets/image-20210407162145605.png)

## 五、使用Kibana查询日志

![image-20210407163158835](ELK%E9%85%8D%E7%BD%AE%E8%AF%B4%E6%98%8E%E6%96%87%E6%A1%A3.assets/image-20210407163158835.png)

