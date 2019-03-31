#!/bin/bash
set -e

if [ "$1" = '/usr/sbin/init' ]; then

: ${DNS:=9.9.9.9}
: ${PORT:=80}
: ${BOOT:=LOCAL}

if [ ! -f /etc/dhcp/dhcpd.conf ]; then
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	if [ -d /var/www/html/os/isolinux ]; then
		\cp /var/www/html/os/isolinux/{initrd.img,vmlinuz,vesamenu.c32} /var/lib/tftpboot/
	else
		echo -e "No installation media. \nUse: mount /media/CentOS-7-x86_64-Minimal-xxxx.iso /docker/os/ -o loop"
		exit 1
	fi

	if [ ! -f /key/dhcpd.conf -a ! -f /key/default -a ! -f /key/ks.cfg ]; then
		[ -z "$NIC" ] && NIC=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
		IPADDR=$(ifconfig $NIC |awk 'NR=="2"{print $2}')
		NETMASK=$(ifconfig $NIC |awk 'NR=="2"{print $4}')
		SUBNET=$(route -n |grep $NIC |grep $NETMASK |awk 'NR==1{print $1}') 
		GATEWAY=$(route -n |grep $NIC |grep UG |awk 'NR==1{print $2}')
		BROADCAST=$(ifconfig $NIC |awk 'NR=="2"{print $6}')
		[ -z "$GATEWAY" ] && GATEWAY=$IPADDR


		#dhcp
		cat >/etc/dhcp/dhcpd.conf <<-END
		option domain-name "example.com";
		option domain-name-servers $DNS;
		ddns-update-style none;
		authoritative;

		default-lease-time 600;
		max-lease-time 7200;
		log-facility local7;

		next-server $IPADDR;
		filename "pxelinux.0";

		subnet $SUBNET netmask $NETMASK {
		  option routers $GATEWAY;
		  option broadcast-address $BROADCAST;
		}
		
		#host host4 {
		#  next-server $IPADDR;
		#  filename "pxelinux.0";
		#  option host-name "host4.example.com";
		#  hardware ethernet 00:A0:78:8E:9E:AA;
		#  fixed-address 192.168.1.4;
		#}
		END


		[ -n "$RANGE" ] && sed -i "/subnet/a range $RANGE;" /etc/dhcp/dhcpd.conf

		if [ "$HOST" ]; then
			n=1
			for i in $(echo $HOST |sed 's/;/\n/g'); do
				MAC=$(echo $i |awk -F, '{print $1}')
				IP=$(echo $i |awk -F, '{print $2}')
				echo -e "\nhost pxe-$n {\n  hardware ethernet $MAC;\n  fixed-address $IP;\n  }" 
				let  n++
			done
		fi

		[ "$PORT" != "80" ] && sed -i 's/80/'$PORT'/g' /etc/httpd/conf/httpd.conf


		#default
		cat >/var/lib/tftpboot/pxelinux.cfg/default <<-END
		default vesamenu.c32
		prompt 1
		timeout 50

		menu title Welcome to CentOS!

		label linux
		  menu label ^Install system
		  kernel vmlinuz
		  append initrd=initrd.img ip=dhcp inst.repo=http://$IPADDR:$PORT/os/ inst.ks=http://$IPADDR:$PORT/ks/ks.cfg

		label rescue
		  menu label ^Rescue installed system
		  kernel vmlinuz
		  append initrd=initrd.img ip=dhcp inst.repo=http://$IPADDR:$PORT/os/ rescue quiet
		  
		label local
		  menu label Boot from ^local drive
		  
		  localboot 0xffff
		#ksdevice=eth0
		END


		if [ "$BOOT" == "INSTALL" ]; then
			sed -i '/label linux/a \  menu default' /var/lib/tftpboot/pxelinux.cfg/default
		elif [ "$BOOT" == "RESCUE" ]; then
			sed -i '/label rescue/a \  menu default' /var/lib/tftpboot/pxelinux.cfg/default
		else
			sed -i '/label local/a \  menu default' /var/lib/tftpboot/pxelinux.cfg/default
		fi


		#ks.cfg
		cat >/var/www/html/ks/ks.cfg <<-END
		#version=DEVEL
		# System authorization information
		auth --enableshadow --passalgo=sha512

		# Use network installation
		url --url="http://$IPADDR:$PORT/os/"

		# Run the Setup Agent on first boot
		firstboot --enable
		# 安装过程中被使用的磁盘
		ignoredisk --only-use=sda
		# Keyboard layouts, cn
		keyboard --vckeymap=us --xlayouts='us'
		# System language, zh_CN.UTF-8
		lang en_US.UTF-8

		# Network information
		network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate
		#network  --bootproto=dhcp --device=eth1 --onboot=off --ipv6=auto
		network  --hostname=localhost.localdomain
		# Reboot after installation
		reboot
		# Root password: redhat
		rootpw --iscrypted \$6\$6OLppYkr.hwcm2GW\$T/k1z5ttJOTfeYfy6hsaGVfW7ZRqO0QkVRBL77GrsCgVUS0dwbt3czb497DFRry5iWFkjWI7gX.69V6JW5Q2Q0
		# System services
		services --enabled="chronyd"
		# System timezone
		timezone Asia/Shanghai --isUtc
		# System bootloader configuration, 使用内核参数 net.ifnames=0 装完后网卡会是eth* ,系统引导安装到sda
		bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda

		# 初次安装或格式化重装(1)
		#clearpart --none --initlabel
		# 删除所有分区重装(2)
		#clearpart --all --initlabel --drives=sda

		# 使用GPT/GUID的磁盘必须有一个bios引导分区，用来安装引导程序。（磁盘空间大于2T）
		#part biosboot --fstype=biosboot --size=1
		
		# 初次安装或删除所有分区重装(1,2),标准分区, --grow --size=1 会使用剩余所有磁盘空间
		#part /boot --fstype="xfs" --ondisk=sda --size=1024
		#part swap --fstype="swap" --ondisk=sda --size=2048
		#part / --fstype="xfs" --ondisk=sda --size=10240
		##part / --fstype="xfs" --grow --ondisk=sda --size=1
		# 格式化重装(1),标准分区
		#part /boot --fstype="xfs" --onpart=sda1
		#part swap --fstype="swap" --onpart=sda3
		#part / --fstype="xfs" --onpart=sda2

		# 初次安装或删除所有分区重装(1,2),LVM
		#part /boot --fstype="xfs" --ondisk=sda --size=1024
		#part pv.272 --fstype="lvmpv" --ondisk=sda --size=12296
		#volgroup centos --pesize=4096 pv.272
		#logvol swap  --fstype="swap" --size=2048 --name=swap --vgname=centos
		#logvol /  --fstype="xfs" --size=10240 --name=root --vgname=centos
		# 格式化重装(1),LVM
		#part /boot --fstype="xfs" --onpart=sda1
		#part pv.14 --fstype="lvmpv" --noformat --onpart=sda2
		#volgroup centos --noformat --useexisting
		#logvol /  --fstype="xfs" --useexisting --name=root --vgname=centos
		#logvol swap  --fstype="swap" --useexisting --name=swap --vgname=centos


		%packages
		@core
		chrony
		kexec-tools
		%end
		
		%post
		sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
		%end
		END


		\cp /etc/dhcp/dhcpd.conf /key/
		\cp /var/lib/tftpboot/pxelinux.cfg/default /key/
		\cp /var/www/html/ks/ks.cfg /key/
	else
		\cp /key/dhcpd.conf /etc/dhcp/
		\cp /key/default /var/lib/tftpboot/pxelinux.cfg/
		\cp /key/ks.cfg /var/www/html/ks/
	fi
	echo -e "dhcpd -cf /etc/dhcp/dhcpd.conf\nxinetd -stayalive\nhttpd" >/start.sh
	echo "for i in \$(netstat -tupnl |awk '{print \$NF}' |egrep 'httpd|dhcpd|xinetd' |awk -F/ '{print \$1}' |sort |uniq -c |awk '{print \$2}');do kill \$i; done" >/stop.sh

	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $PORT -m comment --comment PXE -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport 67:69 -m comment --comment PXE -j ACCEPT
		END
	fi
fi

	echo "Start ****"
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep PXE`" ] && . /iptables.sh
	. /start.sh
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN \\
				-v /docker/ks:/key \\
				-v /docker/os:/var/www/html/os \\
				-e NIC=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
				-e DNS=[9.9.9.9] \\
				-e PORT=[80] \\
				-e BOOT=[LOCAL] \\
				-e RANGE=<"192.168.80.200 192.168.80.210"> \\
				-e IPTABLES=<Y> \\
				--name kickstart kickstart
	"
fi
