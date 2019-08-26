WireGuard
===
## 简介
**WireGuard**是一种极其简单又快速且现代的VPN，它采用了最先进的加密技术。 它的目标是比IPsec更快，比OpenVPN更高效，更简单，更精简，更有用。
> * 官方站点：https://www.wireguard.com/
> * 简明教程：https://wiki.archlinux.org/index.php/WireGuard_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)

****

## 宿主机升级内核

    rpm -ivh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
    sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/elrepo.repo
    yum -y install kernel-lt-devel kernel-lt      #kernel-lt(长期支持版本)、kernel-ml(主线最新版本)
    grub2-mkconfig |grep "menuentry 'CentOS Linux"    #查看新内核
    grub2-editenv - set saved_entry='CentOS Linux (4.4.186-1.el7.elrepo.x86_64) 7 (Core)'  #指定默认内核
    grub2-editenv list
    reboot

****

## Example:

运行一个P2P WG

    # host1
    docker run -itd --cap-add net_admin -p 2000:20000/udp -e ETCD=http://10.10.0.246:2379 --name wg jiobxn/wireguard
    # host2
    docker run -itd --cap-add net_admin -p 2000:20000/udp -e ETCD=http://10.10.0.246:2379 --name wg jiobxn/wireguard

运行一个VPN WG

    # server
    docker run -itd --privileged -p 2000:20000/udp -e ETCD=http://10.10.0.246:2379 -e WG_VPN=SERVER --name wg-server jiobxn/wireguard
    # client
    docker run -itd --cap-add net_admin -e ETCD=http://10.10.0.246:2379 -e WG_VPN=CLIENT --name wg-client jiobxn/wireguard

****

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart unless-stopped --cap-add net_admin \\
					-p 20000:20000/udp \\
					-e ETCD=[http://etcd.redhat.xyz:12379] \\    etcd服务器
					-e WG_TOKEN=[TEST] \\                        定义token前缀的key，相同的token才能连接
					-e LOCAL_ID=[openssl rand -hex 5] \\         id
					-e WGVETH_IP=[10.0.0] \\                     ip前缀
					-e MAX_CLIENT=[10] \\                        最大vpn客户端
					-e PUBLIC_IP=[curl -s ip.sb] \\              公网IP
					-e PUBLIC_PORT=[20000] \\                    公网端口，默认递增
					-e LOCAL_IP=[ip address] \\                  容器或主机IP
					-e LOCAL_PORT=[PUBLIC_PORT] \\               默认和公网端口一致
					-e PRIVATE_KEY=[wg pubkey] \\                私钥
					-e PEER_ID=[ETCD] \\                         对端id，来自etcd
					-e PEER_IP_PORT=[ETCD] \\                    对端IP端口，来自etcd
					-e PEER_PUBLIC_KEY=[ETCD] \\                 对端公钥，来自etcd
					-e WG_VPN=<SERVER | CLIENT> \\               vpn模式，server或client
					--name etcd etcd
