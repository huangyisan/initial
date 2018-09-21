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
sleep 10

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
wget https://nginx.org/download/nginx-1.12.1.tar.gz
wget http://101.96.10.63/cn2.php.net/distributions/php-7.1.12.tar.gz



#########install nginx##########
yum_install(){
yum -y install unzip libacl-devel openssl-devel libxml2-devel bzip2-devel curl-devel unixODBC-devel libsqlite3x-devel readline-devel autoconf hiredis-devel libmemcached-devel libmemcached-devel telnet git bind-utils lrzsz pcre-devel openssl openssl-devel libxml2-devel libxslt-devel gd-devel perl-devel perl-ExtUtils-Embed GeoIP GeoIP-devel GeoIP-data gperftools-devel python-setuptools python-setuptools-devel libevent-devel
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

# nginx control
#cat >/etc/systemd/system/nginx.service<<EOF
#[Unit]
#Description=The nginx HTTP and reverse proxy server
#After=network.target remote-fs.target nss-lookup.target
#
#[Service]
#Type=forking
#PIDFile=/run/nginx.pid
#ExecStartPre=$app_base_dir/nginx/sbin/nginx -t
#ExecStart=$app_base_dir/nginx/sbin/nginx
#ExecReload=$app_base_dir/nginx/sbin/nginx -s reload -c $app_base_dir/nginx/conf/nginx.conf
#KillMode=process
#KillSignal=SIGQUIT
#TimeoutStopSec=5
#PrivateTmp=true
#
#[Install]
#WantedBy=multi-user.target
#EOF

#logrotate
# cat > /etc/logrotate.d/nginx <<EOF
# $log_base_dir/nginx/*.log {
#     daily
#     rotate 5
#     missingok
#     notifempty
#     compress
#     sharedscripts
#     postrotate
#         /bin/kill -USR1 \$(cat /var/run/nginx.pid 2>/dev/null) 2>/dev/null || :
#     endscript
# }
# EOF


#systemctl daemon-reload
## enable
#systemctl enable nginx.service
#echo 'start nginx.......'
#sleep 1
#systemctl start nginx.service
#
#if [ $? != 0 ];then
#    echo -e "\033[1;31mStart nginx failed......\033[0m"
#    exit 1
#fi
#echo -e "\033[1;32mNginx install complate......\033[0m"

mv $app_base_dir/nginx/conf $app_base_dir/nginx/conf.bak

#sudo
#cat > /etc/sudoers.d/runusers <<EOF
#User_Alias RUNUSERS = gouser,nginx
#Defaults:RUNUSERS !requiretty
#RUNUSERS ALL = (root) NOPASSWD: /usr/bin/systemctl
#EOF
#}

#########install php##########
install_php(){
echo -e "\033[1;32mStart install php......\033[0m"
sleep 3
mkdir -p $install_log_dir/php
useradd -r php
cd $download_base_dir
# download php_packages

# tar
tar zxf server_packages.tar.gz
mv server_packages/* ./
tar zxf curl-7.57.0.tar.gz
tar zxf memcached-3.0.4.tar.gz
tar zxf php-7.1.12.tar.gz
tar zxf redis-3.1.5.tar.gz
tar zxf apcu.tar.gz
tar zxf mongodb-1.3.4.tgz
tar zxf phpiredis.tar.gz
tar zxf swoole-src.tar.gz
# install curl
cd $download_base_dir/curl-7.57.0

mkdir -p /app/local/curl
./configure --prefix=/app/local/curl
make && make install

/bin/cp -r /app/local/curl/bin/curl /usr/bin/curl
/bin/cp -r /app/local/curl/bin/curl /usr/local/bin/curl
/bin/cp -r /app/local/curl/lib/libcurl.so.4.5.0 /usr/lib64/libcurl.so.4.5.0
ln -sf /usr/lib64/libcurl.so.4.5.0 /usr/lib64/libcurl.so.4
ln -sf /usr/lib64/libcurl.so.4.5.0 /usr/lib64/libcurl.so

# install php
mkdir -p $app_base_dir/php
cd $download_base_dir/php-7.1.12

./configure  --prefix=$app_base_dir/php --localstatedir=/var --sysconfdir=/etc --enable-fpm --with-fpm-user=php --with-fpm-group=php --with-fpm-acl --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d/ --with-bz2=shared --enable-calendar=shared --enable-ctype=shared --with-curl=shared --enable-exif=shared --enable-fileinfo=shared --enable-filter=shared --enable-ftp=shared --with-gettext=shared --enable-hash=shared --with-iconv=shared --enable-json=shared --enable-libxml=shared --with-openssl=shared --enable-pcntl=shared --with-pcre-jit --enable-phar=shared --with-readline=shared  --enable-session=shared --enable-sockets=shared  --enable-tokenizer=shared --with-zlib=shared --with-zlib=shared --with-mysqli=shared,mysqlnd --with-pdo-mysql=shared,mysqlnd  --enable-mysqlnd=shared --enable-pdo=shared --with-pdo-sqlite=shared,/usr --with-pdo-odbc=shared,unixODBC,/usr --with-sqlite3=shared,/usr --enable-mbstring=shared |tee $install_log_dir/php/php_install.log

sed -i "s/^EXTRA_LIBS.*/& -lreadline/g" Makefile

make -j8 1>&2 >> $install_log_dir/php/php_install.log && make install 1>&2 >> $install_log_dir/php/php_install.log

# .....wocao...
make -j8 1>&2 >> $install_log_dir/php/php_install.log && make install 1>&2 >> $install_log_dir/php/php_install.log


if [ $? != 0 ];then
    echo -e "\033[1;31m install php failed......\033[0m"
    exit 1
fi

# add profile
echo "export PATH=\$PATH:$app_base_dir/php/bin:$app_base_dir/php/sbin" >/etc/profile.d/php.sh
source /etc/profile

# install phpiredis
cd $download_base_dir/phpiredis
/app/local/php/bin/phpize
make clean
./configure
make && make install

# install redis-3.1.5
cd $download_base_dir/redis-3.1.5
/app/local/php/bin/phpize
make clean
./configure
make && make install

# install swoole-src
cd $download_base_dir/swoole-src
/app/local/php/bin/phpize
make clean
./configure
make && make install

# install memcached-3.0.4  php
cd $download_base_dir/memcached-3.0.4
/app/local/php/bin/phpize
make clean
./configure
make && make install

# install apcu
cd $download_base_dir/apcu
/app/local/php/bin/phpize
make clean
./configure
make && make install

# install mongodb
cd /$download_base_dir/mongodb-1.3.4
/app/local/php/bin/phpize
./configure
make && make install

# upgrade curl
cd $download_base_dir/php-7.2.0/ext/curl
/app/local/php/bin/phpize
make clean
./configure --with-curl=$download_base_dir/curl-7.57.0/lib/.libs
make && make install

#config php.ini
/bin/cp -r /$download_base_dir/php.ini /etc/php.ini


# add profile
echo "export PATH=\$PATH:$app_base_dir/php/bin:$app_base_dir/php/sbin" >/etc/profile.d/php.sh
source /etc/profile

# raise php-fpm.conf  *.conf env conf
cp /etc/php-fpm.conf.default /etc/php-fpm.conf
cp /etc/php-fpm.d/www.conf.default /etc/php-fpm.d/www.conf
touch /etc/php-fpm.d/php-fpm

# php-fpm control
cat >/etc/systemd/system/php-fpm.service<<EOF
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
#Type=notify
PIDFile=/run/php-fpm.pid
EnvironmentFile=/etc/php-fpm.d/php-fpm
ExecStart=$app_base_dir/php/sbin/php-fpm --fpm-config /etc/php-fpm.conf --nodaemonize
ExecReload=/bin/kill -USR2 $MAINPID
Type=simple

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

if [ `php -m | grep Warning | wc -l` != 0 ];then
    echo -e "\033[1;31mSome php components may not run in expectation, you can manual fix these prolbem after finish installation......\033[0m"

    sleep 5
fi


# php-fpm start enable
#systemctl enable php-fpm
#echo start php-fpm
#sleep 1
#systemctl start php-fpm
echo -e "\033[1;32m install php complate......\033[0m"
}

##########install consul##########
#install_consul(){
#echo -e "\033[1;32mStart install consul......\033[0m"
#sleep 3
#
#cd $download_base_dir
#
#unzip consul_1.0.2_linux_amd64.zip
#cp consul /usr/local/sbin/
#
## consul configration dir
#mkdir /etc/consul.d/
#chown gouser.gouser /etc/consul.d/
## consul tmp dir
#mkdir /app/data/services/consul
#chown gouser.gouser /app/data/services/consul
#
## consul template only in master
#mkdir $app_base_dir/consul-template
#cd $download_base_dir/
#
#unzip consul-template_0.19.4_linux_amd64.zip
#cp consul-template $app_base_dir/consul-template
#cp consul-template /usr/local/bin/consul-template
#
## consul-template hcl ctpl dir
#mkdir /app/config/consul-template
#chown gouser.gouser /app/config/consul-template
#
#
#cat >/app/script/consul_initial.sh<<EOF
##!/bin/bash
#/usr/bin/find /app/data/services/ -type d  -name 'consul' -exec rm -rf {} \; &>/dev/null
#
#Ip=\`ifconfig | grep -A 2 'eth0' | grep inet |awk '{print \$2}'\`
#
#cat >/etc/consul.d/consul_client.json<<COF
#{
#    "server": false,
#    "node_name": "\$Ip",
#    "bind_addr": "\$Ip",
#    "client_addr": "127.0.0.1",
#    "enable_script_checks": true,
#    "data_dir": "/app/data/services/consul",
#    "log_level": "INFO",
#    "start_join": ["10.106.0.1", "10.106.0.2", "10.106.0.3"],
#    "ui": false
#}
#COF
#
#cat >/app/config/supervisor.d/consul.ini<<BOF
#[program:consul]
#command=consul agent -config-dir=/etc/consul.d
#autostart=true                ; start at supervisord start (default: true)
#autorestart=true        ; whether/when to restart (default: unexpected)
#startsecs=3                   ; number of secs prog must stay running (def. 1)
#user=root
#stdout_logfile=/app/log/supervisor.d/consul.log
#stderr_logfile=/app/log/supervisor.d/consul.log
#stdout_events_enabled=true
#stderr_events_enabled=true
#stdout_logfile_maxbytes=200MB
#stderr_logfile_maxbytes=200MB
#priority=-1
#BOF
#
#EOF
#echo -e "\033[1;32mInstall consul complate......\033[0m"
#
#}
#
##########install promethues_node_exporter##########
#install_node_exporter(){
#echo -e "\033[1;32mStart install node_exporter......\033[0m"
#sleep 3
#
#cd $download_base_dir/
#
#tar zxf node_exporter-0.15.2.linux-amd64.tar.gz
#mkdir $app_base_dir/node_exporter
#cp node_exporter-0.15.2.linux-amd64/node_exporter $app_base_dir/node_exporter/
#echo -e "\033[1;32mInstall node_exporter complate......\033[0m"
#}
#
##########install supervisrod##########
#install_supervisord(){
#mkdir -p /app/log/supervisor
#echo -e "\033[1;32mStart install supervisord......\033[0m"
#sleep 3
#
#easy_install supervisor
#
#
## supervisord configration dir
#echo_supervisord_conf > /etc/supervisord.conf
#
## supervisord config multi-path
#mkdir -p /app/config/supervisor.d/php/
#mkdir -p /app/config/supervisor.d/go/
#mkdir -p /app/config/supervisor.d/
#
#sed -i 's/^;\[include\]/\[include\]/g' /etc/supervisord.conf
#sed -i 's/^;files.*/files = \/app\/config\/supervisor.d\/php\/*.ini \/app\/config\/supervisor.d\/go\/*.ini \/app\/config\/supervisor.d\/*.ini /g' /etc/supervisord.conf
#sed -i 's/^;chmod=0700/chmod=0760/g' /etc/supervisord.conf
#sed -i 's/^;chown=nobody:nogroup/chown=root:gouser/g' /etc/supervisord.conf
#sed -i '/^logfile=/ s#/tmp/supervisord.log#/app/log/supervisor.d/supervisord.log#' /etc/supervisord.conf
#sed -i '/^pidfile=/ s#/tmp/supervisord.pid#/run/supervisord.pid#' /etc/supervisord.conf
#sed -i '/\/tmp\/supervisor.sock/ s#/tmp/supervisor.sock#/run/supervisor.sock#' /etc/supervisord.conf
#
## supervisord control
#cat >/etc/systemd/system/supervisord.service <<EOF
#[Unit]
#Description=supervisord - Supervisor process control system for UNIX
#Documentation=http://supervisord.org
#After=network.target
#
#[Service]
#Type=forking
#ExecStartPre=/bin/bash /app/script/consul_initial.sh
#ExecStart=/usr/bin/supervisord -c /etc/supervisord.conf
#ExecReload=/usr/bin/supervisorctl reload
#ExecStop=/usr/bin/supervisorctl shutdown
#User=root
#
#
#[Install]
#WantedBy=multi-user.target
#EOF
#systemctl daemon-reload
## supervisord enable start
#systemctl enable supervisord
#echo start supervisord
#sleep 1
#systemctl start supervisord
#
#if [ $? != 0 ];then
#    echo -e "\033[1;31mInstall supervisord failed......\033[0m"
#    exit 1
#fi
#echo -e "\033[1;32mInstall supervisord complate......\033[0m"
#}

install_memcached(){
echo -e "\033[1;32mStart install memcached......\033[0m"
cd $download_base_dir
tar zxf memcached-1.5.4.tar.gz
cd memcached-1.5.4
mkdir -p mkdir /app/local/memcache/
./configure --prefix=/app/local/memcache/
make && make install

echo 'export PATH=$PATH:/app/local/memcache/bin' > /etc/profile.d/memcached.sh
source /etc/profile.d/memcached.sh

cat > /etc/systemd/system/memcached.service <<EOF
[Unit]
Description=Memcached
After=network.target

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/memcached
ExecStart=/app/local/memcache/bin/memcached -u \$USER -p \$PORT -m \$CACHESIZE -c \$MAXCONN \$OPTIONS

[Install]
WantedBy=multi-user.target

EOF

cat > /etc/sysconfig/memcached <<EOF
PORT="11211"
USER="nobody"
MAXCONN="102400"
CACHESIZE="64"
OPTIONS=""
EOF

memcached -m 128 -p 11211 -u nobody -d

if [ $? != 0 ];then
    echo -e "\033[1;31mInstall memcached failed......\033[0m"
    exit 1
fi
echo -e "\033[1;32mInstall memcached complate......\033[0m"
}

generate_pid_dir() {
echo 'd /run/php 755 gouser gouser' >/etc/tmpfiles.d/php.conf
echo 'd /run/go 755 gouser gouser' >/etc/tmpfiles.d/go.conf
}

main(){
yum_install
install_nginx
install_php
install_consul
install_node_exporter
install_memcached
install_supervisord
generate_pid_dir

echo -e "\033[1;32mComplate all server packages......\033[0m"

ps -ef | egrep '[s]uper|[m]emcache|[n]ginx'
}
main
