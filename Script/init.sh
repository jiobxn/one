yum clean all; yum -y install epel-release; yum -y update

if [ "$(grep -o -w "Red Hat" /etc/redhat-release)" ]; then
    rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/$(curl -s http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/ |grep epel-release |awk -F\" '{print $6}')
    yum-config-manager --enable rhui-REGION-rhel-server-extras
fi

yum -y install bash-completion vim aria2 axel wget openssl-devel bind-utils iptables-services iftop nethogs net-tools ntp mtr nmap tcpdump pciutils setroubleshoot setools make gcc-c++ autoconf automake unzip bzip2 zip mailx bc at expect telnet git lrzsz lsof bridge-utils dos2unix

systemctl disable NetworkManager firewalld
\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
systemctl enable iptables ntpd

sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

wget https://github.com/jiobxn/one/raw/master/Script/scan.sh -O /usr/local/sbin/scan.sh
chmod u+x /usr/local/sbin/scan.sh

cat >/var/spool/cron/root <<-EOF
MAILTO=' '
58 23 * * * yum update -y
* * * * * bash /usr/local/sbin/scan.sh
* * * * * echo 3 > /proc/sys/vm/drop_caches
EOF

yum -y install python34-setuptools
easy_install-3.4 pip
pip install --upgrade youtube-dl you-get

curl -s https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
yum -y install docker-ce
systemctl enable docker

if [ $(free |awk '$1=="Swap:"{print $2}') -eq 0 ]; then
    swap=`echo "$(free -m |awk '$1=="Mem:"{print $2}')/490" |bc`
    dd if=/dev/zero of=/swapfile bs="$swap"M count=1024
    uuid=$(mkswap /swapfile |awk 'END{print $3}')
    chmod 0600 /swapfile
    swapon /swapfile
    echo "$uuid    swap    defaults        0 0" >>/etc/fstab
fi

audit2allow -a -M mycertwatch
semodule -i mycertwatch.pp
\rm mycertwatch*

echo -e "\n-----> reboot"
