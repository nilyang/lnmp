#!/usr/bin/env bash

user=nobody
group=nobody
#osversion=`cat /etc/issue|awk '{printf("%s%s" ,$1,$3);}'`
osversion=`cat /etc/issue | awk -F"\n" '{printf("%s",$1)}'|awk '{printf("%s %s\n", $1, $3)}'`

currdir=`pwd`
function make_php_links()
{
	phpcmds="pear peardev pecl phar phar.phar php php-cgi php-config phpize"
	for cmd in $phpcmds
	do
		src_cmd=/usr/local/php/bin/$cmd
		dst_cmd=/usr/local/bin/$cmd
		if [ -f "$src_cmd" ] ; then
		    if [ -L "$dst_cmd" ]; then
			    ln -s -f $src_cmd $dst_cmd
		    elif [ -f "$dst_cmd" ] ; then
		        rm $dst_cmd
                ln -s $src_cmd $dst_cmd
            fi
		fi
	done
}

function askYesNo ()
{
    local answer
    read  -p  "$1 [Y/N]?" answer

    case $answer in
    Y|y )
        answer=1
        ;;
    *)
        answer=0
        ;;
    esac
    return $answer
}

askYesNo "If reinstall env"

if [ "$?" == 1 ] ; then

# [ autoconf pkgconfig ] was included in "Development Tools"
# libjpeg-turbo is not turbojpeg

yum groupinstall "Development Tools"
yum install autoconf pkgconfig \
    curl libcurl-devel libwebp-tools libwebp libwebp-devel \
    libxml2 libxml2-devel \
    libzip libzip-devel zlib zlib-devel \
    mcrypt libmcrypt libmcrypt-devel \
    libpng libpng-devel  \
    libjpeg-turbo libjpeg-turbo-devel \
    freetype freetype-devel \
    openssl openssl-devel \
    pcre pcre-devel \
    libevent libevent-devel
fi


askYesNo "If recompile php"

if [ "$?" == 1 ] # || [ ! -f "/usr/local/php/bin/php" ]
then
    main_ver=5
    sub_ver=4
    trd_ver=45
    try_times="1 2 3"
    for try in $try_times
    do
        echo $currdir
        cd $currdir
        read -n20 -p "Please input PHP version(e.g: 5.4.45):" vernum
        declare -a verarr=(`echo $vernum | tr "." "\n"`)
        main_ver=${verarr[@]:0:1}
        sub_ver=${verarr[@]:1:1}
        trd_ver=${verarr[@]:2:1}

        phpver=php-$vernum

        if [ $main_ver < 5 ]; then
            echo "main version < 5": $phpver please retry
            try_times="1 2 3"
            continue
        fi

        if [ $sub_ver < 4 ]; then
            echo "sub version < 4": $phpver please retry
            try_times="1 2 3"
            continue
        fi

        if [ ! -f "$phpver.tar.bz2" ] ; then
          echo wget http://cn2.php.net/distributions/$phpver.tar.bz2
          wget http://cn2.php.net/distributions/$phpver.tar.bz2
        fi
        if [ ! -f "$phpver.tar.bz2" ];then
            echo "get $phpver.tar.bz2 Fail. Please check version"
            exit 1
        else
            break
        fi
    done

    rm -rf $phpver

    tar xjvf $phpver.tar.bz2

    cd $phpver

    configure_params= --prefix=/usr/local/$phpver \
                         --with-libxml-dir \
                         --enable-zip \
                         --with-zlib \
                         --enable-bcmath \
                         --with-curl \
                         --with-jpeg-dir \
                         --with-png-dir \
                         --with-gd \
                         --with-zlib-dir \
                         --with-gettext \
                         --with-freetype-dir \
                         --enable-mbstring \
                         --enable-mysqlnd \
                         --with-mysql \
                         --with-mysqli \
                         --with-pdo-mysql \
                         --with-mcrypt \
                         --enable-sockets \
                         --enable-zip \
                         --with-pcre-dir \
                         --with-pear=/usr/local/pear \
                         --with-openssl \
                         --enable-fpm \
                         --enable-pcntl \
                         --with-fpm-user=$user \
                         --with-fpm-group=$group
    if [ "$sub_ver" > 4 ] ; then
        configure_params=$configure_params --enable-opcache
    fi

    ./configure $configure_params
    make
    if [ -f "/usr/local/$phpver/bin/php" ] ; then
        mv /usr/local/$phpver /usr/local/$phpver.bak.`date +%y-%m-%d`
    fi

    make install

    php_ini=/usr/local/$phpver/lib/php.ini

    cp php.ini-production $php_ini
    echo "" >> $php_ini

    #php5.6 默认 default_charset = "UTF-8"
    sed -i.bak 's/\s*;*date.timezone\s*=.*/date.timezone = Asia\/Shanghai/g' $php_ini
    sed -i.bak 's/\s*;*upload_max_filesize\s*=.*/upload_max_filesize = 50M/g' $php_ini
    sed -i.bak 's/\s*;*mbstring.func_overload\s*=.*/mbstring.func_overload = 2/g' $php_ini

    #php5.5+,opcahce is in kernnel ,just compile with --enable-opcache
    sed -i '/zend_extension=opcache.so/d' $php_ini
    #echo "zend_extension=opcache.so" >> $php_ini

    if [ -f "/usr/local/php" ] ; then
       rm /usr/local/php
	fi

    ln -s /usr/local/$phpver/ /usr/local/php

	if [ -f "/usr/local/php/bin/php" ] ; then
		echo php linked Successfully!
	fi

	gopear_file=/usr/local/$phpver/go-pear.phar
	wget http://pear.php.net/go-pear.phar -O  $gopear_file
	make_php_links
	php $gopear_file
	make_php_links

	pecl install redis
	pecl install mongo
	#pecl install xdebug


    sed -i '/extension=redis.so/d' $php_ini
    echo "extension=redis.so" >> $php_ini

    sed -i '/extension=mongo.so/d' $php_ini
    echo "extension=mongo.so" >> $php_ini


    #php-fpm
    cp /usr/local/$phpver/etc/php-fpm.conf.default /usr/local/$phpver/etc/php-fpm.conf
    fpm_conf=/usr/local/$phpver/etc/php-fpm.conf
    sed -i.bak 's/\s*;*rlimit_files\s*=.*/rlimit_files = 65535/g' $fpm_conf
    sed -i.bak 's/\s*;*pm.max_children\s*=.*/pm.max_children = 200/g' $fpm_conf
    sed -i.bak 's/\s*;*pm\s*=.*/pm = static/g' $fpm_conf
    sed -i.bak 's/\s*;*listen.allowed_clients\s*=.*/listen.allowed_clients = 127.0.0.1/g' $fpm_conf

    #cpu_counts=`cat /proc/cpuinfo |grep "cpu cores"|wc -l`
    #echo "zend_extension=xdebug.so" >> $php_ini
    #echo "xdebug.remote_enable = on" >> $php_ini
    #echo "xdebug.remote_connect_back = on" >> $php_ini
    #echo 'xdebug.remote_host = "10.0.2.15"' >> $php_ini
    #echo "xdebug.remote_port = 9000" >> $php_ini
    #echo 'xdebug.remote_handler = "dbgp"' >> $php_ini
    #echo 'xdebug.idekey = "vagrant-xx"' >> $php_ini
    #echo 'xdebug.remote_log = "/tmp/xdebug.log"' >> $php_ini

    #add libevent for workerman
    pecl install channel://pecl.php.net/libevent-0.1.0
    sed -i '/extension=libevent.so/d' $php_ini
    echo "extension=libevent.so" >> $php_ini

	#pecl install pcntl
    #sed -i '/extension=pcntl.so/d' $php_ini
    #echo "extension=pcntl.so" >> $php_ini

fi

askYesNo "If recompile nginx"

if [ "$?" == 1 ] # || [ ! -f "/usr/local/nginx/sbin/nginx" ]
then
    cd $currdir
    nginxver=nginx-1.8.0
    if [ ! -f "$nginxver.tar.gz" ]
    then
      wget http://nginx.org/download/$nginxver.tar.gz
    fi
    rm -rf  $nginxver
    tar xzvf $nginxver.tar.gz

    cd $nginxver

    ./configure --prefix=/usr/local/$nginxver \
                --user=$group --group=$group \
                --http-log-path=/var/log/nginx \
                --with-http_ssl_module \
                --with-pcre \
            #   --with-stream \
            #   --with-stream_ssl_module \
                --with-http_auth_request_module
    make
    make install

    ln -s /usr/local/$nginxver/ /usr/local/nginx

    /usr/local/nginx/sbin/nginx -t

fi


askYesNo "If recompile redis"

if [ "$?" == 1 ] # || [ ! -f "/usr/local/redis/src/redis-server" ]
then
    cd $currdir

    redisver=redis-3.0.5
    if [ ! -f "$redisver.tar.gz" ]
    then
      wget http://download.redis.io/releases/$redisver.tar.gz
    fi
    if [ ! -d "$redisver" ] ; then
          tar xzvf $redisver.tar.gz
    fi

    cd $redisver
    make
    cd $currdir
    cp redis3conf/* $redisver/

    cp -r $redisver /usr/local/$redisver
    ln -s /usr/local/$redisver/ /usr/local/redis
fi

