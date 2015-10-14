#!/bin/bash


pid_phpfpm=`ps aux|grep php-fpm|grep -v "grep"|grep "master process"|awk '{print $2}'`
pid_nginx=`ps aux|grep nginx|grep -v "grep"|grep "master process"|awk '{print $2}'`
redis_pid_counts=`ps aux|grep "redis-server"|grep -v "grep"|wc -l`

mysqlcmd=`service mysql`
if [[ ! ( "$mysqlcmd" =~ ^Usage\:.*$ ) ]]
then
   service mysql start
else
   service mysql restart
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

