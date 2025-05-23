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
docsify serve docs
```



### 手动初始化

 如果你的系统里安装了 Python 的话，也可以很容易地启动一个静态服务器去预览你的网站。 

```
cd docs && python -m http.server 3000
```



### 服务器部署

使用nginx部署：和部署所有静态网站一样，只需将服务器的访问根目录设定为 `index.html` 文件。 

```bash
server {
  listen 80;
  server_name  localhost;

  location / {
    alias /data/gitee/work/docs/;
    index index.html;
  }
}
```

### 地址

项目地址：https://github.com/docsifyjs

文档地址：https://docsify.js.org/#/zh-cn/