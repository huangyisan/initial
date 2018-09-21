#!/bin/bash

# install php nginx consul supervisrod node_exporter
# centos 7.4 curl-7.57
# nginx-1.12.1
# php-7.1.12


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

#########ENV##########
download_base_dir=/ops/package/app
app_base_dir=/app/local
log_base_dir=/app/log
install_log_dir=/tmp/install_log

mkdir -p $download_base_dir
mkdir -p $app_base_dir
mkdir -p $log_base_dir
mkdir -p $install_log_dir



########download packages######
cd $download_base_dir
#wget https://nginx.org/download/nginx-1.12.1.tar.gz
#wget http://101.96.10.63/cn2.php.net/distributions/php-7.1.12.tar.gz
########install nginx##########
yum_install(){
yum -y install unzip libacl-devel openssl-devel libxml2-devel bzip2-devel curl-devel unixODBC-devel libsqlite3x-devel readline-devel autoconf hiredis-devel libmemcached-devel libmemcached-devel telnet git bind-utils lrzsz pcre-devel openssl openssl-devel libxml2-devel libxslt-devel gd-devel perl-devel perl-ExtUtils-Embed GeoIP GeoIP-devel GeoIP-data gperftools-devel python-setuptools python-setuptools-devel libevent-devel perl-ExtUtils-Embed sqlite-devel glibc-headers gcc-c++
}

install_nginx(){
echo -e "\033[1;32mStart install nginx......\033[0m"
sleep 3
mkdir -p $install_log_dir/nginx
cd $download_base_dir
useradd -r nginx
chown -R nginx.nginx /home/nginx $app_base_dir/nginx-conf
# install nginx

tar zxf nginx-1.12.1.tar.gz

cd nginx-1.12.1

mkdir -p $log_base_dir/nginx/
mkdir -p $app_base_dir/nginx/


./configure --prefix=$app_base_dir/nginx --with-debug  --error-log-path=$log_base_dir/nginx/error.log --http-log-path=$log_base_dir/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=nginx --group=nginx --with-file-aio  --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-pcre --with-pcre-jit --with-stream --with-stream_ssl_module --with-google_perftools_module --with-http_gunzip_module |tee $install_log_dir/nginx/nginx_install.log


make 1>&2 >> $install_log_dir/nginx/nginx_install.log && make install 1>&2 >> $install_log_dir/nginx/nginx_install.log

if [ $? != 0 ];then
    echo -e "\033[1;31mInstall nginx error......\033[0m"
    echo -e "\033[1;31mSee install log in $install_log_dir/nginx/nginx_install.log\033[0m"
    exit 1
fi

chown nginx $app_base_dir/nginx

# PAHT nginx
echo "export PATH=\$PATH:$app_base_dir/nginx/sbin" >> /etc/profile.d/nginx.sh
source /etc/profile


/bin/cp -a $app_base_dir/nginx/conf $app_base_dir/nginx/conf.bak
}

main(){
yum_install
install_nginx
}
main
