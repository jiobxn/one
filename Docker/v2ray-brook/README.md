v2ray-brook
===
## 简介
* **V2Ray** 是一个模块化的代理软件包，它的目标是提供常用的代理软件模块，简化网络代理软件的开发。
* **Brook** 是一个跨平台(Linux/MacOS/Windows/Android/iOS)的代理软件。
> * 官方站点：https://www.v2fly.org/
> * 项目地址：https://github.com/txthinking/brook


## Example:

    #运行一个brook实例
    docker run -d --restart unless-stopped -p 19443:19443 --name brook jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=client -e SERVER=<ip:19443> -e PASS=<passwd> --name brook jiobxn/v2ray-brook

    #运行一个brook ws实例
    docker run -d --restart unless-stopped -p 19443:19443 -e MODE=wsserver --name brook-ws jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=wsclient -e SERVER=<ip:19443> -e PASS=<passwd> --name brook jiobxn/v2ray-brook

    #运行一个brook wss实例
    docker run -d --restart unless-stopped -p 80:80 -p 443:443 -e MODE=wssserver -e DOMAIN=<brook.example.com> --name brook-wss jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=wssclient -e SERVER=<brook.example.com:443> -e DOMAIN=Y -e PASS=<passwd> --name brook jiobxn/v2ray-brook

    #运行一个brook socks5实例
    docker run -d --restart unless-stopped -p 19443:19443 -e MODE=socks5 -e USER=admin --name brook-socks5 jiobxn/v2ray-brook

    #运行一个brook socks5tohttp实例
    docker run -d --restart unless-stopped --network container:brook -e MODE=socks5tohttp -e SERVER=127.0.0.1:1080 --name brook-http jiobxn/v2ray-brook

    #运行一个brook relayoverbrook实例(udp有问题)
    docker run -d --restart unless-stopped -e MODE=relayoverbrook -e SERVER=<ip:19443> -e PASS=<passwd> -e TO=172.17.0.7:3128 --name brook-squid jiobxn/v2ray-brook

    #运行一个brook dns实例(有问题)
    docker run -d --restart unless-stopped -p 53:53/udp -e MODE=dns -e SERVER=<ip:19443> -e PASS=<passwd> --name brook-dns jiobxn/v2ray-brook


    #运行一个v2ray实例
    docker run -d --restart unless-stopped -p 19443:19443 -e MODE=v2server --name v2ray jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=v2client -e SERVER=<ip> -e PORT=19443 -e UUID=<uuid> --name v2ray jiobxn/v2ray-brook

    #运行一个v2ray ws实例，可以套cloudflare
    docker run -d --restart unless-stopped --network host -e PORT=19445 -e MODE=v2ray -e WSPATH=/mp3 --name v2ray-ws jiobxn/v2ray-brook
    docker run -d --restart unless-stopped -p 80:80 -p 443:443 -v /docker/key:/key -e PROXY_SERVER="v2ray.example.com|www.google.co.id^backend_https=y,ws=/mp3|172.17.0.1:19445" --name google jiobxn/nginx
    #docker run -d --restart unless-stopped -e MODE=v2client -e SERVER=v2ray.example.com -e PORT=19443 -e UUID=<uuid> -e WSPATH=/mp3 --name v2ray jiobxn/v2ray-brook

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-p 19443:19443 \
				-e PASS=[Random] \\    #随机密码
				-e PORT=[19443] \\     #监听端口
				-e LPORT=[1080] \\     #本地端口
				-e MODE=[server] \\ <v2server | v2client | [server|wsserver|wssserver] | [client|wsclient|wssclient] | [socks5|socks5tohttp|relayoverbrook|dns]>    #运行模式：v2ray服务器、v2ray客户端、brook服务器(默认)、brook客户端、brook其他
				-e UUID=[Random] \\    #随机UUID，v2ray
				-e WSPATH=</mp4> \\    #WS路径，v2ray  。path应当选择较长的字符串
				-e DOMAIN=<jiobxn.com> \\    #wssserver模式填写你的域名，wssclient模式值不为空
				-e LOG=[none] \\ <debug|info|warning|error|none>    #记录日志，v2ray
				-e SERVER=<server_address:port> \\    #brook服务器地址和端口
				-e TO=<1.1.1.1:3128> \\               #用于relayoverbrook模式，后端服务
				-e USER=<jiobxn> \\                   #用于socks5模式
				--name v2ray-brook v2ray-brook

****

### V2Ray客户端

**Windown**  
https://github.com/Cenmrev/V2RayW/releases  
https://github.com/2dust/v2rayN/releases

**MacOS**  
https://github.com/Cenmrev/V2RayX/releases  
https://github.com/yanue/V2rayU/releases

**Android**  
https://apkpure.com/v2rayng/com.v2ray.ang  
https://apkpure.com/bifrostv/com.github.dawndiy.bifrostv

**IOS**  
Shadowrocket、Quantumult、i2Ray 。v2ray类型选择Vmess

****

test

    npm install -g wscat
    wscat -c wss://v2ray.exanole.com/mp3
