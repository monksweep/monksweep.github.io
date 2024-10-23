## 框架常用命令

### 快速开始

推荐全局安装 `docsify-cli` 工具，可以方便地创建及在本地预览生成的文档。 

```bash
npm i docsify-cli -g
```

 如果想在项目的 `./docs` 目录里写文档，直接通过 `init` 初始化项目。 

```bash
docsify init ./docs
```



### 本地预览

 通过运行 `docsify serve` 启动一个本地服务器，可以方便地实时预览效果。默认访问地址 [http://localhost:3000](http://localhost:3000/) 

```bash
docsify serve docs [--port]
```

或者

```bash
docsify s docs [-p]
```



### 手动初始化

 如果你的系统里安装了 Python 的话，也可以很容易地启动一个静态服务器去预览你的网站。 

```
cd docs && python -m http.server 3000
```



### 服务器部署

在服务器后台启动

```bash
nohup docsify s -p 3000 /data/docs </dev/null &>nohup.log &
disown
```



### 地址

项目地址：https://github.com/docsifyjs

文档地址：https://docsify.js.org/#/zh-cn/