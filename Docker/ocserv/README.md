OCSERV
===
## 简介
* **OpenConnect server**（ocserv）是一个SSL VPN服务器。其目的是成为一个安全，小型，快速和可配置的VPN服务器。
> * 官方站点：https://ocserv.gitlab.io/www/index.html
> * 客户端项目：http://www.infradead.org/openconnect/


## Example:

    #使用证书连接
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --device /dev/net/tun -v /docker/ocserv:/key -p 443:443 --name ocserv jiobxn/ocserv


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart unless-stopped --cap-add NET_ADMIN --device /dev/net/tun \\
			-v /docker/ocserv:/key \\
			-p 443:443 \\
			-e VPN_PORT=[443] \\       VPN端口
			-e VPN_USER=<jiobxn> \\    VPN用户名
			-e VPN_PASS=[RANDOM] \\    VPN密码，默认随机
			-e P12_PASS=[jiobxn.com] \\  p12证书密码
			-e MAX_CONN=[3] \\           每个客户端的最大连接数
			-e MAX_CLIENT=[253] \\       最大客户端数
			-e SERVER_CN=[SERVER_IP] \\  默认是服务器公网IP，不能填错
			-e CLIENT_CN=["AnyConnect VPN"] \\   P12证书标识，便于在iphone上识别
			-e CA_CN=["OpenConnect CA"] \\       CA证书标识
			-e GATEWAY_VPN=[Y]         \\        默认VPN做网关
			-e IP_RANGE=[10.10.0] \\            分配的IP地址池
			-e PUSH_ROUTE=<1.1.1.1/255.255.255.255,192.168.2.0/255.255.255.0> \\
			-e NO_ROUTE=<5.5.5.5/255.255.255.255,192.168.3.0/255.255.255.0> \\
			-e DNS1:=[9.9.9.9] \\
			-e DNS2:=[8.8.8.8] \\
			-e RADIUS_PORT=[1812] \\             radius 端口
			-e RADIUS_SERVER:=<radius ip> \\     radius 服务器
			-e RADIUS_SECRET:=[testing123] \\    radius 共享密钥
			--name ocserv ocserv

### IOS Client:

    1.在 App Store 安装 AnyConnect
    2.可以通过浏览器安装导入 ca.crt 和 ocserv.p12

### Linux Client:

    1. yum -y install openconnect
    2. 使用证书登陆 echo yes | openconnect -c ocserv.p12 https://Server-IP-Address:Port --key-password=jiobxn.com -q
    3. 查看pin-sha256 openssl s_client -servername <Server-IP-Address> -connect <Server-IP-Address:Port> | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
    4. 用户名密码登陆 echo $VPN_PASS | openconnect https://Server-IP-Address:Port --servercert <pin-sha256> --user=$VPN_USER --passwd-on-stdin -q 

### Windows Client:

    1.浏览器打开 ftp://ftp.noao.edu/pub/grandi/ 下载 anyconnect-win-x.x.msi 并安装
    2.导入 ca.crt 和 ocserv.p12证书，打开证书管理器 运行certmgr.msc命令
    3.在连接时候要取消选中 Block connections to untusted server
