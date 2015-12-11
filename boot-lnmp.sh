#!/bin/bash

osversion=`cat /etc/issue | awk -F"\n" '{printf("%s",$1)}'|awk '{printf("%s %s\n", $1, $3)}'`
ostype=CentOS
if [[ "$osversion" =~ ^CentOS.*$ ]]
then
    ostype=CentOS
fi

if [[ "$osversion" =~ ^Debian.*$ ]]
then
    ostype=Debian
fi


pid_phpfpm=`ps aux|grep php-fpm|grep -v "grep"|grep "master process"|awk '{print $2}'`
pid_nginx=`ps aux|grep nginx|grep -v "grep"|grep "master process"|awk '{print $2}'`
redis_pid_counts=`ps aux|grep "redis-server"|grep -v "grep"|wc -l`



if [ $ostype == "Debian" ] ; then
    mysql_name=mysql
    mysql_status=`service $mysql_name`
    if [[ ! ( "$mysql_status" =~ ^Usage\:.*$ ) ]]
    then
       service $mysql_name start
    else
       service $mysql_name restart
    fi
elif [ $ostype == "CentOS" ] ; then
    mysql_name=mysqld
    mysql_status=`service $mysql_name status`
    if [[ "$mysql_status" =~ ^mysqld.*?pid.*$ ]]
    then
       service $mysql_name restart
    else
       service $mysql_name start
    fi
else
    echo Error ostype "$osversion" not supported
    exit
fi



if [ "$pid_phpfpm" == "" ]
then
    /usr/local/php/sbin/php-fpm
else
   kill -USR2 $pid_phpfpm
fi

if [ "$pid_nginx" == "" ]
then
    /usr/local/nginx/sbin/nginx
else
    #kill $pid_nginx
    /usr/local/nginx/sbin/nginx -s reload
fi

if [ "$redis_pid_counts" == "" ]
then
    /usr/local/redis/startredis.sh
else
    /usr/local/redis/stopredis.sh
    /usr/local/redis/startredis.sh
fi

