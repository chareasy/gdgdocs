#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
if [ $(id -u) != "0" ]; then
    echo "Error: 错误，必须是Root用户才能执行此脚本，GCE中切换Root：sudo -s"
    exit 1
fi

clear

echo "========================================================================="
echo "无障碍使用Google Docs - Form服务：GDGDocs.org 开源了"
echo "========================================================================="
echo "更多信息请访问：http://gdgny.org/ 南阳谷歌开发者社区"
echo "========================================================================="
echo "该脚本很大一部分外围配置均参考自 lnmp一键安装包 感谢 lnmp.org "
echo "========================================================================="

read -p "输入要部署GDocs反向代理的域名： " domain

if [ ! -f "/usr/local/nginx/conf/vhost/$domain.conf" ]; then
echo "==========================="
echo "domain=$domain"
echo "===========================" 
else
echo "==========================="
echo "$domain 已经存在咯!"
echo "==========================="
fi

# Set timezone from lnmp.org
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
yum install -y ntp
ntpdate -u pool.ntp.org
date

# 安装 Git
git --version

if [ $? -eq 0 ];then

echo "Git 已安装，进行下一步"
else

echo "检测到该系统尚未安装git，这一步我们要安装git"
#安装 git
yum -y install gcc
yum -y install curl
yum -y install curl-devel
yum -y install zlib-devel
yum -y install openssl-devel
yum -y install perl
yum -y install cpio
yum -y install expat-devel
yum -y install gettext-devel
yum -y install perl-CPAN
wget https://git-core.googlecode.com/files/git-1.9.0.tar.gz
tar xzvf git-1.9.0.tar.gz
cd git-1.9.0
autoconf
./configure
make
make install
cd ..
fi

# 安装 Nginx Stable 版
yum -y install openssl openssl-devel
yum -y install pcre-devel
wget http://nginx.org/download/nginx-1.4.7.tar.gz

git clone https://github.com/agentzh/headers-more-nginx-module.git $HOME/more_module/headers-more-nginx-module/
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git $HOME/more_module/ngx_http_substitutions_filter_module/
tar zxvf nginx-1.4.7.tar.gz
cd nginx-1.4.7
./configure  --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-ipv6 --with-http_sub_module --add-module=$HOME/more_module/headers-more-nginx-module/  --add-module=$HOME/more_module/ngx_http_substitutions_filter_module/

make && make install

# 替换 config 文件、添加 vhosts 文件夹

ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

mkdir -p /home/wwwroot/default
chmod +w /home/wwwroot/default
mkdir -p /home/wwwlogs
chmod 777 /home/wwwlogs

cd ..
rm -f /usr/local/nginx/conf/nginx.conf
cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf
mkdir /usr/local/nginx/conf/vhost/

cat >/usr/local/nginx/conf/vhost/$domain.conf<<eof
# 注意，这里提供的 dn-ggpt.qbox.me 等，是七牛为公益开发者社区的提供的赞助，请商业公司自行搭建，谢谢。
server
     {
          listen       80;
          server_name $domain;
          # conf ssl if you need 
          # SSL 配置请参见 gdgny.org/project/gdgdocs
          location / {
            proxy_set_header Accept-Encoding '';
            subs_filter_types text/css text/js;
            proxy_pass https://docs.google.com;
            subs_filter docs.google.com  $domain
            subs_filter lh1.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh2.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh3.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh4.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh5.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh6.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh7.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh8.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh9.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter lh10.googleusercontent.com dn-ggpt.qbox.me;
            subs_filter ssl.gstatic.com dn-gstatic.qbox.me;
            subs_filter www.gstatic.com dn-gstatic.qbox.me;

            proxy_redirect          off;
            proxy_set_header        X-Real-IP       \$remote_addr;
            proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header        Cookie "";
            proxy_hide_header Set-Cookie;
            more_clear_headers "P3P";

            proxy_hide_header Location;
          }
     }
eof

echo "Test Nginx configure file......"
/usr/local/nginx/sbin/nginx -t
echo "Restart Nginx...…"
killall nginx
/usr/local/nginx/sbin/nginx
echo "搞定"