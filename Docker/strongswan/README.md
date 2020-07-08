Strongswan
===
## 简介
* **strongSwan** 一个基于IPsec的开放源代码VPN解决方案。
> * 官方站点：https://www.strongswan.org/


## Example:

    docker run -d --restart unless-stopped --cap-add NET_ADMIN --device /dev/net/tun -p 500:500/udp -p 4500:4500/udp -v /docker/strongswan:/key --name strongswan jiobxn/strongswan

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart unless-stopped --cap-add NET_ADMIN --device /dev/net/tun \\
			-v /docker/strongswan:/key \\
			-p 500:500/udp \\
			-p 4500:4500/udp \\
			-e VPN_USER=[jiobxn] \\        默认VPN用户名
			-e VPN_PASS=[RANDOM] \\        默认随机密码
			-e VPN_PSK=[jiobxn.com] \\     PSK密码
			-e P12_PASS=[jiobxn.com] \\    P12密码
			-e SERVER_CN=<SERVER_IP> \\    默认是服务器公网IP
			-e CLIENT_CN=["strongSwan VPN"] \\    P12证书标识，便于在iphone上识别
			-e CA_CN=["strongSwan CA"] \\         CA证书标识
			-e IP_RANGE=[10.11.0] \\              分配的IP地址池
			--name strongswan strongswan

### IOS Client:

    IPSec: user+pass+psk or ca.crt+strongswan.p12+user+pass
