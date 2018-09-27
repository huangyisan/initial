#/bin/bash

# base db4, virtual user
#set -x 

export userlist_path="/home/"
export userlist_file="virtual_users.txt"
export virtual_user_path="/ftp/virtual/"

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
local_root=${virtual_user_path}\$USER
userlist_enable=YES
tcp_wrappers=YES
hide_ids=YES
EOF
}

# create virtual user db file and record virtual username password
add_virtual_user() {

exist=`awk 'NR%2==1' /home/virtual_users.txt  | egrep "\<$username\>" | wc -l`

if [ $exist !=0 ]; then
    echo "the user $username is exists"
else
cat << EOF >> ${userlist_path}${userlist_file}
$username
$password
EOF
echo "add $username success"
}

create_virtual_user() {
touch ${userlist_path}${userlist_file}
chmod 600 ${userlist_path}${userlist_file}

# create db4 file
db_load -T -t hash -f ${userlist_path}${userlist_file} /etc/vsftpd/virtual_users.db

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
service vsftpd restart
}

install_vsftpd() {
install_db4_vsftpd
create_virtual_user
start_vsftpd
}


echo_string() {
echo -e "Usage:  ./vsftpd_manager [-I] \n\t./vsftpd_manager [-u] username [-p] password \n\nInput options:\n\t -I install vsftpd \n\t -u Set username \n\t -p Set password"
}

if [ x$1 != x ]
then
    while getopts "ip:u:" arg
    do
      case $arg in
        i|I)
            # install vsftpd;;
            flag=ture
            echo "i" ;;
        u)
            username="$OPTARG"
            ;;
        p)
            password="$OPTARG"
            ;;
        \?|h)
            echo_string
            exit 1
      esac
    done
        if [ -z "$flag" ] && [ -z "$username" ] && [ -z "$password" ]; then
            echo_string 
        elif [ -n "$flag" ] && [ -z "$username" ] && [ -z "$password" ]; then
            install_vsftpd

        elif [ -z "$flag" ] && [ -n "$username" ] && [ -n "$password" ]; then
            add_virtual_user $username $password
            db_load -T -t hash -f ${userlist_path}${userlist_file} /etc/vsftpd/virtual_users.db
            install -g ftp -o ftp -d /ftp/virtual/$username
        else
            echo_string
            exit 1
        fi
	   
else
    echo_string
fi
