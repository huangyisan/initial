#!/bin/bash

# install php nginx consul supervisrod node_exporter
# centos 7.4 
# nginx-1.12.1
# php-7.1.12

set -x

# 检查是否为root用户，脚本必须在root权限下运行
if [[ "$(whoami)" != "root" ]]; then
    echo "please run this script as root !" >&2
    exit 1
fi
echo -e "\033[31m the script only Support CentOS_7 x86_64 \033[0m"


# 检查是否为64位系统，这个脚本只支持64位脚本
platform=`uname -i`
if [ $platform != "x86_64" ];then
    echo "this script is only for 64bit Operating System !"
    exit 1
fi

#########check ldconfig########
echo 'check ldconfig'
ldconfig

#########ENV##########
download_base_dir=/ops/package/app
app_base_dir=/app/local
log_base_dir=/app/log
install_log_dir=/tmp/install_log

mkdir -p $download_base_dir
mkdir -p $app_base_dir
mkdir -p $log_base_dir
mkdir -p $install_log_dir

download_packages() {
############download packages#############
wget https://pecl.php.net/get/redis-4.1.0.tgz
wget https://pecl.php.net/get/imagick-3.4.3.tgz
wget https://pecl.php.net/get/memcached-3.0.0.tgz
wget http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2

# tar
tar zxf php-7.1.12.tar.gz
tar zxf memcached-3.0.4.tar.gz
tar zxf redis-4.1.0.tgz
tar zxf swoole-src-4.0.0.tar.gz
tar zxf imagick-3.4.3.tgz
tar jxf scws-1.2.3.tar.bz2
unzip ImageMagick-7.0.7-25.zip
tar zxf libmemcached-1.0.16.tar.gz
}

#########install php##########

install_php(){
echo -e "\033[1;32mStart install php......\033[0m"
sleep 3
mkdir -p $install_log_dir/php
useradd -r php
cd $download_base_dir

# install php
mkdir -p $app_base_dir/php
cd $download_base_dir/php-7.1.12

./configure  --prefix=$app_base_dir/php --localstatedir=/var --sysconfdir=/etc --enable-fpm --with-fpm-user=php --with-fpm-group=php --with-fpm-acl --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d/ --with-bz2=shared --enable-calendar=shared --enable-ctype=shared --with-curl=shared --enable-exif=shared --enable-fileinfo=shared --enable-filter=shared --enable-ftp=shared --with-gettext=shared --enable-hash=shared --with-iconv=shared --enable-json=shared --enable-libxml=shared --with-openssl=shared --enable-pcntl=shared --with-pcre-jit --enable-phar=shared --with-readline=shared  --enable-session=shared --enable-sockets=shared  --enable-tokenizer=shared --with-zlib=shared --with-zlib=shared --with-mysqli=shared,mysqlnd --with-pdo-mysql=shared,mysqlnd  --enable-mysqlnd=shared --enable-pdo=shared --with-pdo-sqlite=shared,/usr --with-pdo-odbc=shared,unixODBC,/usr --with-sqlite3=shared,/usr --enable-mbstring=shared |tee $install_log_dir/php/php_install.log

sed -i "s/^EXTRA_LIBS.*/& -lreadline/g" Makefile

make -j2 1>&2 >> $install_log_dir/php/php_install.log && make install 1>&2 >> $install_log_dir/php/php_install.log

# .....wocao...
#make -j8 1>&2 >> $install_log_dir/php/php_install.log && make install 1>&2 >> $install_log_dir/php/php_install.log


if [ $? != 0 ];then
    echo -e "\033[1;31m install php failed......\033[0m"
    exit 1
fi

# add profile
echo "export PATH=\$PATH:$app_base_dir/php/bin:$app_base_dir/php/sbin" >/etc/profile.d/php.sh
source /etc/profile

# add profile
echo "export PATH=\$PATH:$app_base_dir/php/bin:$app_base_dir/php/sbin" >/etc/profile.d/php.sh
source /etc/profile

# raise php-fpm.conf  *.conf env conf
cp /etc/php-fpm.conf.default /etc/php-fpm.conf
cp /etc/php-fpm.d/www.conf.default /etc/php-fpm.d/www.conf
touch /etc/php-fpm.d/php-fpm

echo -e "\033[1;32m install php complate......\033[0m"
}

install_redis_ext() {
# install redis-4.1.0
cd $download_base_dir/redis-4.1.0
/app/local/php/bin/phpize
make clean &>/dev/null
./configure
make && make install
}

install_swoole_ext() {
# install swoole-src-4.1.0
cd $download_base_dir/swoole-src-4.0.0
/app/local/php/bin/phpize
make clean &>/dev/null
./configure
make && make install
}

install_memcached_ext() {
# install memcached-3.0.4  php
cd $download_base_dir/libmemcached-1.0.16
mkdir $app_base_dir/libmemcached
./configure --prefix=$app_base_dir/libmemcached
make && make install

cd $download_base_dir/memcached-3.0.4
/app/local/php/bin/phpize
make clean &>/dev/null
 ./configure --with-libmemcached-dir=$app_base_dir/libmemcached/
make && make install
}

install_imagic_ext() {
# install imagick
cd $download_base_dir/ImageMagick-7.0.7-25/ImageMagick/
mkdir $app_base_dir/ImageMagick
chmod +x ./configure
./configure --prefix=$app_base_dir/ImageMagick
make && make install
cd $download_base_dir/imagick-3.4.3
/app/local/php/bin/phpize
make clean &>/dev/null
./configure --with-imagick=$app_base_dir/ImageMagick
make && make install
}

install_scws_ext() {
# install scws
cd $download_base_dir/scws-1.2.3
mkdir $app_base_dir/scws/
./configure --prefix=$app_base_dir/scws
make && make install

cd $download_base_dir/scws-1.2.3/phpext
/app/local/php/bin/phpize
make clean &>/dev/null
./configure --with-scws=$app_base_dir/scws
make && make install
}

#config php.ini
#/bin/cp -r /$download_base_dir/php.ini /etc/php.ini



## php-fpm control
#cat >/etc/systemd/system/php-fpm.service<<EOF
#[Unit]
#Description=The PHP FastCGI Process Manager
#After=syslog.target network.target
#
#[Service]
##Type=notify
#PIDFile=/run/php-fpm.pid
#EnvironmentFile=/etc/php-fpm.d/php-fpm
#ExecStart=$app_base_dir/php/sbin/php-fpm --fpm-config /etc/php-fpm.conf --nodaemonize
#ExecReload=/bin/kill -USR2 $MAINPID
#Type=simple
#
#[Install]
#WantedBy=multi-user.target
#EOF
#systemctl daemon-reload

if [ `php -m | grep Warning | wc -l` != 0 ];then
    echo -e "\033[1;31mSome php components may not run in expectation, you can manual fix these prolbem after finish installation......\033[0m"

    sleep 5
fi


# php-fpm start enable
#systemctl enable php-fpm
#echo start php-fpm
#sleep 1
#systemctl start php-fpm



install_php
install_redis_ext
install_swoole_ext
install_memcached_ext
install_scws_ext
install_imagic_ext
