#!/usr/bin/env bash

osversion=`cat /etc/issue|awk '{printf("%s%s" ,$1,$3);}'`

currdir=`pwd`
function make_php_links()
{
	phpcmds="pear peardev pecl phar phar.phar php php-cgi php-config phpize"
	
	for item in $phpcmds
	do
		src_cmd=/usr/local/php/bin/$item
		dst_cmd=/usr/local/bin/$item
		if [ -f "$src_cmd" ] ; then
			ln -s -f $src_cmd $dst_cmd
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

   apt-get install gcc build-essential autoconf pkg-config \
                curl webp libxml2 libxml2-dev \
                libzip-dev mcrypt libmcrypt-dev libpng12-dev zlibc \
                libfreetype6 libfreetype6-dev openssl libssl-dev \
                libcurl4-openssl-dev libpcre3 libpcre3-dev

   case $osversion in
     Debian8 )
         apt-get install libjpeg-dev
         ;;
     Debian7 )
         apt-get install libjpeg62-dev
	 ;;
   esac

fi

#mysql

askYesNo "If reinstall MySQL"
   
if [  "$?" == 1 ] ; then
   mysqlcmd=`service mysql`
   mysqlver=5.5
   if [[ ! ( "$mysqlcmd" =~ ^Usage\:.*$ ) ]]
   then
       apt-get install mysql-server-${mysqlver} mysql-client-${mysqlver}
       service mysql stop
       askYesNo "If reinstall data?"
       if [ "$?" == 1 ] ; then
           cp -R -p /var/lib/mysql/ /data/mysql
           mv /var/lib/mysql/ /var/lib/mysql-bak
           ln -s /data/mysql/ /var/lib/mysql
       fi
       service mysql start
   fi

fi
#


askYesNo "If recompile php"

if [ "$?" == 1 ] # || [ ! -f "/usr/local/php/bin/php" ]
then
    echo $currdir
    cd $currdir
    phpver=php-5.6.16
    if [ ! -f "$phpver.tar.bz2" ] ; then
      wget http://cn2.php.net/distributions/$phpver.tar.bz2
    fi

    rm -rf $phpver

    tar xjvf $phpver.tar.bz2

    cd $phpver

    ./configure --prefix=/usr/local/$phpver \
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
                         --enable-opcache \
                         --enable-fpm \
                         --with-fpm-user=www-data \
                         --with-fpm-group=www-data

    make clean
    make
    if [ -f "/usr/local/$phpver/bin/php" ] ; then
        mv /usr/local/$phpver /usr/local/$phpver.bak
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
    echo "zend_extension=opcache.so" >> $php_ini

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
	pecl install pnctl
	pecl install xdebug


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
    echo "zend_extension=xdebug.so" >> $php_ini
    echo "xdebug.remote_enable = on" >> $php_ini
    echo "xdebug.remote_connect_back = on" >> $php_ini
    echo 'xdebug.remote_host = "10.0.2.15"' >> $php_ini
    echo "xdebug.remote_port = 9000" >> $php_ini
    echo 'xdebug.remote_handler = "dbgp"' >> $php_ini
    echo 'xdebug.idekey = "vagrant-xx"' >> $php_ini
    echo 'xdebug.remote_log = "/tmp/xdebug.log"' >> $php_ini

    sed -i '/extension=libevent.so/d' $php_ini
    echo "extension=libevent.so" >> $php_ini

    sed -i '/extension=pcntl.so/d' $php_ini
    echo "extension=pcntl.so" >> $php_ini

fi

askYesNo "If recompile nginx"

if [ "$?" == 1 ] # || [ ! -f "/usr/local/nginx/sbin/nginx" ]
then
    cd $currdir
    nginxver=nginx-1.9.5
    if [ ! -f "$nginxver.tar.gz" ]
    then
      wget http://nginx.org/download/$nginxver.tar.gz
    fi
    rm -rf  $nginxver
    tar xzvf $nginxver.tar.gz

    cd $nginxver
    make clean

    ./configure --prefix=/usr/local/nginx-1.9.5 \
                --user=www-data --group=www-data \
                --http-log-path=/var/log/nginx \
                --with-http_ssl_module \
                --with-pcre \
                --with-stream \
                --with-stream_ssl_module \
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

    redisver=redis-3.0.4
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

