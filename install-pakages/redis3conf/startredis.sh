#!/usr/bin/env bash

function findredis()
{
    local find
    count=`netstat -ntla|awk '{printf("%s\n", $4);}'|awk -F':' '{print $2}'|grep $2|wc -l`
    servname=`lsof -i:$2|grep 'LISTEN'|grep IPv4|awk '{printf("%s", $1);}'`

    find=0
    if [ $count -gt 0 ] && [[ ! ( "servname" =~ ^$1.*$ ) ]] ; then
        find=1
    fi
    #echo $servname:$2 $count
    echo $find
}

#master
port=6379
retval=$(findredis "redis-ser" $port)
if [ "$retval" != 1 ] ;then
    /usr/local/redis/src/redis-server /usr/local/redis/redis.conf
    echo "redis-server:$port started .."
else
    echo "redis-server:$port alredy stared."
fi

#slaves
port=6380
while [ $port -lt 6387 ]
do
    sleep 1
    retval=$(findredis "redis-ser" $port)
    if  [ "$retval" != 1 ] ; then
        /usr/local/redis/src/redis-server /usr/local/redis/redis${port}.conf
        echo "redis-server:$port started .."
    else
        echo "redis-server:$port alredy stared."
    fi

    port=$[$port + 1]

done

