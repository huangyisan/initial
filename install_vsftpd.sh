#/bin/bash

# base db4, virtual user

# install db4 vsftpd
install_db4_vsftpd() {
yum -y install db4-utils db4 vsftpd -y

# backup config
/bin/cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf_bak

cat << EOF > /etc/vsftpd/vsftpd.conf
anonymous_enable=NO
guest_enable=YES
virtual_use_local_privs=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
listen=YES
pam_service_name=vsftpd_virtual
user_sub_token=\$USER
local_root=/ftp/virtual/\$USER
userlist_enable=YES
tcp_wrappers=YES
hide_ids=YES
EOF

}

# create virtual user db file and record virtual username password
create_virtual_user() {
touch /home/virtual_users.txt
chmod 600 /home/virtual_users.txt
cat << EOF >> /home/virtual_users.txt
default
default
EOF

# create db4 file
db_load -T -t hash -f /home/virtual_users.txt /etc/vsftpd/virtual_users.db

# create pam file
touch /etc/pam.d/vsftpd_virtual
cat << EOF > /etc/pam.d/vsftpd_virtual
#%PAM-1.0
auth    required        pam_userdb.so   db=/etc/vsftpd/virtual_users
account required        pam_userdb.so   db=/etc/vsftpd/virtual_users
session required        pam_loginuid.so
EOF

# create home dir for virtual user
install -g ftp -o ftp -d /ftp/virtual/default
}

start_vsftpd() {
# start vsftpd
service vsftpd start
}

