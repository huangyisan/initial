#!/bin/bash

# install php nginx consul supervisrod node_exporter
# centos 6.9
# nginx-1.12.1
# php-7.1.12

set -x

# 检查是否为root用户，脚本必须在root权限下运行
if [[ "$(whoami)" != "root" ]]; then
    echo "please run this script as root !" >&2
    exit 1
fi
echo -e "\033[31m the script only Support CentOS_6 x86_64 \033[0m"


# 检查是否为64位系统，这个脚本只支持64位脚本
platform=`uname -i`
if [ $platform != "x86_64" ];then
    echo "this script is only for 64bit Operating System !"
    exit 1
fi

#########check ldconfig########
echo 'check ldconfig'
ldconfig

sleep 1

#########ENV##########
export download_base_dir=/ops/package/app
export script_dir=/ops/initial
export app_base_dir=/app/local
export log_base_dir=/app/log
export install_log_dir=/tmp/install_log
export initd_dir=/app/init.d

mkdir -p $download_base_dir
mkdir -p $app_base_dir
mkdir -p $log_base_dir
mkdir -p $install_log_dir

download_packages() {
############download packages#############
cd $download_base_dir
wget https://nginx.org/download/nginx-1.12.1.tar.gz

wget https://pecl.php.net/get/redis-4.1.0.tgz
wget https://pecl.php.net/get/imagick-3.4.3.tgz
wget https://pecl.php.net/get/memcached-3.0.0.tgz
wget http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2

# tar 
tar zxf nginx-1.12.1.tar.gz

tar zxf php-7.1.12.tar.gz
tar zxf memcached-3.0.4.tar.gz
tar zxf redis-4.1.0.tgz
tar zxf swoole-src-4.0.0.tar.gz
tar zxf imagick-3.4.3.tgz
tar jxf scws-1.2.3.tar.bz2
unzip ImageMagick-7.0.7-25.zip
tar zxf libmemcached-1.0.16.tar.gz
}


#########yum install##########
yum_install() {
yum -y install unzip libacl-devel openssl-devel libxml2-devel bzip2-devel curl-devel unixODBC-devel libsqlite3x-devel readline-devel autoconf hiredis-devel libmemcached-devel libmemcached-devel telnet git bind-utils lrzsz pcre-devel openssl openssl-devel libxml2-devel libxslt-devel gd-devel perl-devel perl-ExtUtils-Embed GeoIP GeoIP-devel GeoIP-data gperftools-devel python-setuptools python-setuptools-devel libevent-devel perl-ExtUtils-Embed sqlite-devel glibc-headers gcc-c++
}

#########judge func###########
judge_func() {
if [ $? != 0 ];then
    echo -e "\033[1;31mexec $1 error......\033[0m"
    exit 1
else
    echo -e "\033[1;32m exec $1 success......\033[0m"
fi
}

########install nginx########
install_nginx() {
echo -e "\033[1;32mStart install nginx......\033[0m"
sleep 3
mkdir -p $install_log_dir/nginx
cd $download_base_dir
useradd -r nginx
chown -R nginx.nginx /home/nginx $app_base_dir/nginx-conf


cd $download_base_dir/nginx-1.12.1

mkdir -p $log_base_dir/nginx/
mkdir -p $app_base_dir/nginx/

./configure --prefix=$app_base_dir/nginx --with-debug  --error-log-path=$log_base_dir/nginx/error.log --http-log-path=$log_base_dir/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=nginx --group=nginx --with-file-aio  --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-pcre --with-pcre-jit --with-stream --with-stream_ssl_module --with-google_perftools_module --with-http_gunzip_module |tee $install_log_dir/nginx/nginx_install.log

make 1>&2 >> $install_log_dir/nginx/nginx_install.log && make install 1>&2 >> $install_log_dir/nginx/nginx_install.log

judge_func "install_nginx"

/bin/bash -c "envsubst '\$app_base_dir' < ${script_dir}/nginx_manage.template > ${initd_dir}/nginx"
chkconfig nginx on

chown nginx $app_base_dir/nginx

echo "export PATH=\$PATH:$app_base_dir/nginx/sbin" >> /etc/profile.d/nginx.sh
source /etc/profile


/bin/cp -a $app_base_dir/nginx/conf $app_base_dir/nginx/conf.bak

}

#########install php##########

install_php() {
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

judge_func "install_php"


/bin/bash -c "envsubst '\$app_base_dir' < ${script_dir}/php-fpm_manage.template > ${initd_dir}/php-fpm"
chkconfig php-fpm on

#config php.ini
}

install_redis_ext() {
# install redis-4.1.0
cd $download_base_dir/redis-4.1.0
/app/local/php/bin/phpize
make clean &>/dev/null
./configure
make && make install

judge_func "install_redis_ext"
}

install_swoole_ext() {
# install swoole-src-4.1.0
cd $download_base_dir/swoole-src-4.0.0
/app/local/php/bin/phpize
make clean &>/dev/null
./configure
make && make install

judge_func "install_swoole_ext"
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

judge_func "install_memcached_ext"
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

judge_func "install_imagic_ext"
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

judge_func "install_scws_ext"
}

#config php.ini
#/bin/cp -r /$download_base_dir/php.ini /etc/php.ini



if [ `php -m | grep Warning | wc -l` != 0 ];then
    echo -e "\033[1;31mSome php components may not run in expectation, you can manual fix these prolbem after finish installation......\033[0m"

    sleep 5
fi

main() {
download_packages
yum_install
install_nginx
install_php
install_redis_ext
install_swoole_ext
install_memcached_ext
install_scws_ext
install_imagic_ext
}

main
