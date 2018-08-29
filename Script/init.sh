yum clean all; yum -y install epel-release; yum -y update

if [ "$(grep -o -w "Red Hat" /etc/redhat-release)" ]; then
    rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/$(curl -s http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/ |grep epel-release |awk -F\" '{print $6}')
    yum-config-manager --enable rhui-REGION-rhel-server-extras
fi

if [ "`hostname`" == "vultr.guest" ]; then
    yum -y install bash-completion vim aria2 wget bind-utils iptables-services iftop nethogs net-tools ntp mtr nmap tcpdump unzip bzip2 zip mailx bc at expect telnet git lrzsz lsof bridge-utils dos2unix certbot setroubleshoot setools
else
    yum -y install bash-completion vim aria2 wget bind-utils iptables-services iftop nethogs net-tools ntp mtr nmap tcpdump unzip bzip2 zip mailx bc at expect telnet git lrzsz lsof bridge-utils dos2unix certbot axel openssl-devel pciutils setroubleshoot setools make gcc-c++ autoconf automake nfs-utils 
fi

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

curl -sL https://github.com/docker/compose/releases/download/$(curl -s https://github.com/docker/compose/tags |grep 'compose/releases/tag' |grep -v rc |awk -F/ 'NR==1{print $NF}' |awk -F\" '{print $1}')/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

if [ $(free |awk '$1=="Swap:"{print $2}') -eq 0 ]; then
    swap=`echo "$(free -m |awk '$1=="Mem:"{print $2}')/485" |bc`
    dd if=/dev/zero of=/swapfile bs="$swap"M count=1024
    uuid=$(mkswap /swapfile |awk 'END{print $3}')
    chmod 0600 /swapfile
    swapon /swapfile
    echo "$uuid    swap    defaults        0 0" >>/etc/fstab
fi

if [ `ulimit -n` -eq 1024 ]; then
    echo -e "*          soft    nproc     512000\nroot       soft    nproc     unlimited" >/etc/security/limits.d/20-nproc.conf
    echo -e "*      -   nofile   1048576\n*      -   nproc    524288" >>/etc/security/limits.conf
    echo "kernel.pid_max=512000" >> /etc/sysctl.conf 
    echo "fs.file-max=512000" >>/etc/sysctl.conf
    ulimit -n 1048576
    sysctl -p
fi

audit2allow -a -M mycertwatch
semodule -i mycertwatch.pp
\rm mycertwatch*

echo -e "\n-----> reboot"
