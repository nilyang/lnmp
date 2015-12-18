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

port=6387

while [ $port -gt 6379 ]
do
    port=$[$port - 1]
    retval=$(findredis "redis-ser" $port)
    if [ "$retval" == 1 ] ; then
        /usr/local/redis/src/redis-cli -p $port shutdown
        echo "redis-server:$port stop .."
    else
        echo "redis-server:$port not run."
    fi
    sleep 1
done

