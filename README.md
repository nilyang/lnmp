# LNMP 环境安装脚本

## 目前支持的操作系统

### debian 7.5 / 8.0

## LNMP构成

- PHP 5.6.14
- Nginx 1.9.5
- MySQL debian apt安装 mysql-server-5.5 mysql-client-5.5
- Redis 3.0.4

## 前提
  默认数据盘挂载到/data目录，若是没有额外数据盘，则需要先建立该目录
```
  #sudo mkdir /data
```

  注意： `挂载之前，确认/data目录下没有文件，如果有文件，则需要先备份，否则挂载磁盘之后，该目录下之前的文件都会丢失`
  
## 说明


### 目录结构
```
##########################################
$ git clone https://github.com/nilyang/lnmp.git 
$ cd lnmp
$ tree
.
├── README.md  
├── boot-lnmp.sh   : lnmp 启动及重启脚本
└── install-pakages
    ├── install.sh :一键安装脚本
    └── redis3conf :redis配置文件，安装脚本会用到
        ├── redis.conf
        ├── redis3conf.tar.gz
        ├── redis6380.conf
        ├── redis6381.conf
        ├── redis6382.conf
        ├── redis6383.conf
        ├── redis6384.conf
        ├── redis6385.conf
        ├── redis6386.conf
        ├── startredis.sh
        └── stopredis.sh

##########################################

```
