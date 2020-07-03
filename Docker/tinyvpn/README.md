tinyFecVPN
===
## 简介
* **tinyFecVPN** 是一个工作在VPN方式的双边网络加速工具，可以加速全流量(TCP/UDP/ICMP)。
> * 项目地址：https://github.com/wangyu-/tinyFecVPN


## Example:

    #运行一个server实例
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --device /dev/net/tun -p 8000:8000/udp --name tinyvpn jiobxn/tinyvpn
    
    #运行一个client实例
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --device /dev/net/tun -e VPN_SERVER=<IPADDR> -e VPN_PASS=<PASS> --name tinyvpn jiobxn/tinyvpn

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped --cap-add NET_ADMIN --device /dev/net/tun \\
				-p 8000:8000/udp \\
				-e VPN_PORT=[8000] \\                #服务端口
				-e VPN_SERVER=<IPADDR> \\            #服务器IP
				-e IP_RANGE=[10.22.0] \\             #IP地址段
				-e VPN_PASS=[RANDOM] \\              #随机密码
				-e DNAT=<2222|22,53|1.1.1.1:53> \\   #端口转发 本地端口|目的[IP和]端口
				-e SNAT=<Y> \\                       #SNAT
				--name tinyvpn tinyvpn

****

客户端全局代理模式示例

    ip ro add <VPN SERVER> via 172.17.0.1 dev eth0
    ip ro del default via 172.17.0.1 dev eth0
    ip ro add 0.0.0.0/0 via 10.22.0.1
