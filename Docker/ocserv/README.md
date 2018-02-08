OCSERV
===
## 简介
* **OpenConnect server**（ocserv）是一个SSL VPN服务器。其目的是成为一个安全，小型，快速和可配置的VPN服务器。
> * 官方站点：https://ocserv.gitlab.io/www/index.html


## Example:

    #推荐使用证书连接
    docker run -d --restart always --privileged -v /docker/ocserv:/key -p 443:443 --hostname ocserv --name ocserv jiobxn/ocserv


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always --privileged \\
			-v /docker/ocserv:/key \\
			-p 443:443 \\
			-e VPN_PORT=[443] \\       VPN端口
			-e VPN_USER=<jiobxn> \\    VPN用户名
			-e VPN_PASS=<123456> \\    VPN密码，默认随机
			-e P12_PASS=[jiobxn.com] \\  p12证书密码
			-e MAX_CONN=[3] \\           每个客户端的最大连接数
			-e MAX_CLIENT=[3] \\         最大客户端数
			-e SERVER_CN=[SERVER_IP] \\  默认是服务器公网IP，不能填错
			-e CLIENT_CN=["AnyConnect VPN"] \\   P12证书标识，便于在iphone上识别
			-e CA_CN=["OpenConnect CA"] \\       CA证书标识
			-e GATEWAY_VPN=[Y] \\                默认VPN做网关
			-e IP_RANGE=[10.10.0] \\             分配的IP地址池
			--hostname ocserv \\
			--name ocserv ocserv

### IOS Client:

    1.在 App Store 安装 AnyConnect
    2.可以通过浏览器安装导入 ca.crt 和 ocserv.p12

### Linux Client:

    1. yum -y install openconnect
    2. 使用证书登陆 openconnect -c ocserv.p12 https://Server-IP-Address:Port --no-cert-check --key-password=$P12_PASS -q &
    3.用户名密码登陆 echo "$VPN_PASS" | openconnect https://Server-IP-Address:Port --no-cert-check --user=$VPN_USER --passwd-on-stdin -q &

### Windows Client:

    1.浏览器打开 ftp://ftp.noao.edu/pub/grandi/ 下载 anyconnect-win-x.x.msi 并安装
    2.导入 ca.crt 和 ocserv.p12证书，打开证书管理器 运行certmgr.msc命令
    3.在连接时候要取消选中 Block connections to untusted server
