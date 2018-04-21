OpenVPN
===
## 简介
* **OpenVPN** 是一个基于 OpenSSL 库的应用层 VPN 实现。和传统 VPN 相比，它的优点是简单易用。
> * 官方站点：https://openvpn.net/index.php/open-source.html


## Example:

    #运行一个原生openvpn
    docker run -d --restart always --privileged -v /docker/openvpn:/key -p 1194:1194 --name openvpn jiobxn/openvpn

    #运行一个http代理的openvpn
    docker run -d --restart always --privileged -v /docker/openvpn:/key -p 8080:8080 -e PROXY_USER=jiobxn --name openvpn jiobxn/openvpn
    

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always --privileged \\
			-v /docker/openvpn:/key \\
			-p 1194:1194 \\
			-p <8080:8080> \\
			-e TCP_UDP=[tcp] \\    默认使用TCP
			-e TAP_TUN=[tun] \\    默认使用tun
			-e VPN_PORT=[1194] \\  默认端口
			-e VPN_USER=<jiobxn> \\  VPN用户名
			-e VPN_PASS=<123456> \\  VPN密码，默认随机，/docker/openvpn/openvpn.log
			-e MAX_STATICIP=<63> \\  最大固定IP客户端数，/docker/openvpn/client.txt
			-e C_TO_C=[Y] \\         允许客户端与客户端之间通信
			-e GATEWAY_VPN=[Y] \\    默认VPN做网关
			-e PUSH_ROUTE=<"192.168.0.0/255.255.0.0,172.16.0.0/255.240.0.0,10.0.0.0/255.255.255.0">    推送路由，适用于GATEWAY_VPN=N
			-e SERVER_IP=[SERVER_IP] \\  默认是服务器公网IP
			-e IP_RANGE=[10.8.0] \\      分配的IP地址池
			-e PROXY_USER=<jiobxn> \\    http代理用户名
			-e PROXY_PASS=<123456> \\    代理密码，默认随机
			-e PROXY_PORT=<8080> \\      代理端口
			-e DNS1=[8.8.4.4] \\         默认DNS
			-e DNS2=[8.8.8.8] \\
			--hostname openvpn \\
			--name openvpn openvpn

### IOS Client:

    1.到App Store 安装OpenVPN.
    2.用iTunes 导入ta.key、auth.txt和client.ovpn 到OpenVPN

### [MAC OS](https://tunnelblick.net/index.html)

### Linux Client:

    1.安装 yum -y install openvpn
    2.传输文件 scp OpenVPN-Server-IP:/etc/openvpn/easy-rsa/2.0/keys/keys/{client.conf,auth.txt} /etc/openvpn/
    3.启动 systemctl start openvpn@client.service
    前台启动：openvpn --writepid /var/run/openvpn-client/client.pid --cd /etc/openvpn/ --config /etc/openvpn/client.conf

### Windows Client:

    1.下载并安装 http://swupdate.openvpn.org/community/releases/openvpn-install-x.x.x-I601.exe
    2.将client.ovpn和auth.txt(如果有)拷贝到"C:\Program Files\OpenVPN\config\"
