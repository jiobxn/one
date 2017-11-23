yum clean all; yum -y install epel-release; yum -y update
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
echo -e "\n-----> reboot"
