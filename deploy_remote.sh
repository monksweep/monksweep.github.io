#!/bin/bash

# 定义变量
REMOTE_USER="root"
REMOTE_HOST="10.20.20.183"
REMOTE_COMMAND="cd /data/gitee/typora && git pull"

# 使用ssh执行远程命令
ssh ${REMOTE_USER}@${REMOTE_HOST} "${REMOTE_COMMAND}"