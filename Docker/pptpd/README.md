PPTPD
===
## 简介
* 点对点隧道协议（Point to Point Tunneling Protocol，缩写为PPTP）是实现虚拟专用网（VPN）的方式之一。
> * 项目地址：http://poptop.sourceforge.net/dox/

## Example:

    docker run -d --restart unless-stopped --privileged --network host -e VPN_PASS=123456 --name pptpd jiobxn/pptpd

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart unless-stopped --privileged \\
			-v /docker/pptpd:/key \\
			--network host \\         使用宿主机网络
			-e VPN_USER=[jiobxn] \\   VPN用户名
			-e VPN_PASS=<123456> \\   VPN密码，默认随机
			-e IP_RANGE:=[10.9.0] \\  分配的IP地址池
			-e DNS1:=[9.9.9.9] \\
			-e DNS2:=[8.8.8.8] \\
			-e RADIUS_SERVER:=<radius ip> \\    radius 服务器
			-e RADIUS_SECRET:=[testing123] \\   radius 共享密钥
			--name pptpd pptpd
