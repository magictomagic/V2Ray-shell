#!/bin/bash
# 添加对时（上海）
# 将nginx服务添加至systemctl
# 解决域名输入错误无法修改（以参数形式输入）
# curl -O https://raw.githubusercontent.com/atrandys/v2ray-ws-tls/master/v2ray_ws_tls.sh && chmod +x v2ray_ws_tls.sh && ./v2ray_ws_tls.sh
# https://github.com/v2ray/v2ray-core/releases/download/v4.22.1/v2ray-linux-64.zip
#判断系统
if [ ! -e '/etc/redhat-release' ]; then
echo "your OS version is not CentOS, please choose CentOS 7"
exit
fi
# 在指定目录下若centos的版本为6则报错
if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then	
echo "your Centos version is 6, but CentOS 7 requested"
exit
fi
# -v "#",显示不包含“#”的所有文本
# 显示含 SELINUX= 的文本
CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")	
if [ "$CHECK" == "SELINUX=enforcing" ]; then
# enforcing: Violations of SELinux rules are blocked and logged.
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
if [ "$CHECK" == "SELINUX=permissive" ]; then
# permissive: Violations of SELinux rules are logged only. Generally for debugging purposes.
# -i Modify the contents of the read file directly instead of printing to the terminal
	sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
# use [function name] [parameter] to set color
function blue(){
    echo -e "\033[34m\033[01m $1 \033[0m"
}
function green(){
    echo -e "\033[32m\033[01m $1 \033[0m"
}
function red(){
    echo -e "\033[31m\033[01m $1 \033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m $1 \033[0m"
}

install_vwt(){
    systemctl stop firewalld
    systemctl disable firewalld
	# Install the build environment and necessary libraries
	# -y do it without bothering asking to confirm the installation
    # add epel-release to enable nginx
    yum install -y libtool perl-core zlib-devel gcc wget epel-release pcre* unzip
	
	# Creation of X.509 certificates, CSRs and CRLs
    wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz
    tar xzvf openssl-1.1.1a.tar.gz
    
    mkdir /etc/nginx
    mkdir /etc/nginx/ssl
    mkdir /etc/nginx/conf.d
	
#? how to get newest version	
    wget https://nginx.org/download/nginx-1.15.8.tar.gz
	
# -rf remove without confirm
    tar xf nginx-1.15.8.tar.gz && rm -rf nginx-1.15.8.tar.gz
    cd nginx-1.15.8
# compile nginx support ssl, detailed parameter and installation get at https://blog.csdn.net/bjnihao/article/details/52370089
    ./configure --prefix=/etc/nginx --with-openssl=../openssl-1.1.1a --with-openssl-opt='enable-tls1_3' --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_sub_module --with-stream --with-stream_ssl_module
    make && make install
    
    domain=$OPTARG

# 以覆盖的形式将下面的内容送至指定路径的文件中，若路径终端的文件不存在，则创建，若路径前的文件夹不存在，则报错
cat > /etc/nginx/conf/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /etc/nginx/logs/error.log warn;
pid        /etc/nginx/logs/nginx.pid;
events {
   worker_connections  1024;
}
http {
   include       /etc/nginx/conf/mime.types;
   default_type  application/octet-stream;
   log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                     '\$status \$body_bytes_sent "\$http_referer" '
                     '"\$http_user_agent" "\$http_x_forwarded_for"';
   access_log  /etc/nginx/logs/access.log  main;
   sendfile        on;
   #tcp_nopush     on;
   keepalive_timeout  120;
   client_max_body_size 20m;
   #gzip  on;
   include /etc/nginx/conf.d/*.conf;
}
EOF

cat > /etc/nginx/conf.d/default.conf<<-EOF
server {
    listen       80;
    server_name  $domain;
    root /etc/nginx/html;
    index index.php index.html index.htm;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /etc/nginx/html;
    }
}
EOF
# Start nginx
    /etc/nginx/sbin/nginx

    curl https://get.acme.sh | sh
    ~/.acme.sh/acme.sh  --issue  -d $domain  --webroot /etc/nginx/html/
    ~/.acme.sh/acme.sh  --installcert  -d  $domain   \
        --key-file   /etc/nginx/ssl/$domain.key \
        --fullchain-file /etc/nginx/ssl/fullchain.cer \
        --reloadcmd  "/etc/nginx/sbin/nginx -s reload"
	
cat > /etc/nginx/conf.d/default.conf<<-EOF
server { 
    listen       80;
    server_name  $domain;
    rewrite ^(.*)$  https://\$host\$1 permanent; 
}
server {
    listen 443 ssl http2;
    server_name $domain;
    root /etc/nginx/html;
    index index.php index.html;
    ssl_certificate /etc/nginx/ssl/fullchain.cer; 
    ssl_certificate_key /etc/nginx/ssl/$domain.key;
    #TLS 版本控制
    ssl_protocols   TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers     'TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5';
    ssl_prefer_server_ciphers   on;
    # 开启 1.3 0-RTT
    ssl_early_data  on;
    ssl_stapling on;
    ssl_stapling_verify on;
    #add_header Strict-Transport-Security "max-age=31536000";
    #access_log /var/log/nginx/access.log combined;
    location /mypath {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:11234; 
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    location / {
       try_files \$uri \$uri/ /index.php?\$args;
    }
}
EOF


#安装v2ray
    
    yum install -y wget
    bash <(curl -L -s https://install.direct/go.sh)  
    cd /etc/v2ray/
    rm -f config.json

    wget https://raw.githubusercontent.com/atrandys/v2ray-ws-tls/master/config.json

    v2uuid=$(cat /proc/sys/kernel/random/uuid)
    sed -i "s/aaaa/$v2uuid/;" config.json
    newpath=$(cat /dev/urandom | head -1 | md5sum | head -c 4)
    sed -i "s/mypath/$newpath/;" config.json
    sed -i "s/mypath/$newpath/;" /etc/nginx/conf.d/default.conf
    cd /etc/nginx/html
    rm -f /etc/nginx/html/*
    wget https://github.com/atrandys/v2ray-ws-tls/raw/master/web.zip
    unzip web.zip
    /etc/nginx/sbin/nginx -s stop
    /etc/nginx/sbin/nginx
    systemctl restart v2ray.service
    
    #增加自启动脚本
cat > /etc/rc.d/init.d/autov2ray<<-EOF
#!/bin/sh
#chkconfig: 2345 80 90
#description:autov2ray
/etc/nginx/sbin/nginx
EOF

    #设置脚本权限
    chmod +x /etc/rc.d/init.d/autov2ray
    chkconfig --add autov2ray
    chkconfig autov2ray on

cat > /etc/v2ray/myconfig.json<<-EOF
{
===========配置参数=============
地址：${domain}
端口：443
uuid：${v2uuid}
额外id：64
加密方式：aes-128-gcm
传输协议：ws
别名：myws
路径：${newpath}
底层传输：tls
}
EOF
# systemctl daemon-reload
# systemctl start nginx
# systemctl status nginx
# systemctl status v2ray
# clear
green
green "安装已经完成"
green 
green "===========配置参数============"
green "地址：${domain}"
green "端口：443"
green "uuid：${v2uuid}"
green "额外id：64"
green "加密方式：aes-128-gcm"
green "传输协议：ws"
green "别名：myws"
green "路径：${newpath}"
green "底层传输：tls"
green 
}
check_time(){
    yum -y install chrony
    systemctl enable chronyd
    timedatectl set-local-rtc 1
    timedatectl set-timezone Asia/Shanghai
    timedatectl set-ntp yes

}

add_to_systemctl(){
# 将nginx服务添加至systemctl
/etc/nginx/sbin/nginx -s stop
cat > /usr/lib/systemd/system/nginx.service<<-EOF
[Unit]

Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target

[Service]

Type=forking
WorkingDirectory=/etc/nginx
ExecStart=/etc/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]

WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl start nginx
systemctl status nginx
}
remove_v2ray(){

    /etc/nginx/sbin/nginx -s stop
    systemctl stop v2ray.service
    systemctl disable v2ray.service
    
    rm -rf /usr/bin/v2ray /etc/v2ray
    rm -rf /etc/v2ray
    # rm -rf /etc/nginx
    
    green "v2ray已删除"
    
}
remove_nginx(){
    service nginx stop
    chkconfig nginx off
    rm -rf /usr/sbin/nginx 
    rm -rf /etc/nginx 
    rm -rf /etc/init.d/nginx
    yum remove nginx
    green "nginx已删除"
}
while getopts ":d:rasunh" opt;do  # add ":" in the front to get invalid opts
    case $opt in
        h)
            echo " -d [domain]            install v2ray+ws+tls
 -a                     add nginx to systemctls
 -s                     check the status of nginx and v2ray
 -u                     upgrade v2ray
 -r                     remove v2ray
 -n                     remove nginx
 -h                     help"
             ;;
        d)
            install_vwt
            check_time
            ;;
        r)
            remove_v2ray
            ;;
        n)
            remove_nginx
            ;;
        a)
            add_to_systemctl
            ;;
        u)
            upgrade v2ray
            ;;
        s)
            ps -ef | grep nginx
            systemctl status nginx
            systemctl status v2ray
            ;;
        :)
            echo "$varname, the option -$OPTARG require an arguement, run \"bash $0 -h\" for help" 
            exit 1
            ;;
        ?) 
            echo "Invalid option: -$OPTARG, run \"bash $0 -h\" for help "
            ;;

  esac
done
if [ $# -lt 1 ]; then
echo "$0: option(s) missing, choose option(s) below:
 -d [domain]            install v2ray+ws+tls
 -a                     add nginx to systemctls
 -s                     check the status of nginx and v2ray
 -u                     upgrade v2ray
 -r                     remove v2ray
 -n                     remove nginx
 -h                     help"
exit 1;
fi




