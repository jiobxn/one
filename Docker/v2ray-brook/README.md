v2ray-brook
===
## 简介
* **V2Ray** 是一个模块化的代理软件包，它的目标是提供常用的代理软件模块，简化网络代理软件的开发。
* **Brook** 是一个跨平台(Linux/MacOS/Windows/Android/iOS)的代理软件。
> * 官方站点：https://www.v2ray.com/
> * 项目地址：https://github.com/txthinking/brook


## Example:

    #运行一个brook实例
    docker run -d --restart unless-stopped -p 19443:19443 --name brook jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=client -e SERVER=<ip:19443> -e PASS=<passwd> --name brook jiobxn/v2ray-brook

    #运行一个brook ss实例
    docker run -d --restart unless-stopped -p 19443:19443 -e MODE=ssserver --name brook-ss jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=ssclient -e SERVER=<ip:19443> -e PASS=<passwd> --name brook jiobxn/v2ray-brook

    #运行一个brook ws实例
    docker run -d --restart unless-stopped -p 19443:19443 -e MODE=wsserver --name brook-ws jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=wsclient -e SERVER=<ip:19443> -e PASS=<passwd> --name brook jiobxn/v2ray-brook

    #运行一个brook ws tls实例
    docker run -d --restart unless-stopped -p 80:80 -p 443:443 -e MODE=wsserver -e DOMAIN=<brook.example.com> --name brook-wss jiobxn/v2ray-brook
    #docker run -d --restart unless-stopped -e MODE=wsclient -e SERVER=<brook.example.com:443> -e DOMAIN=Y -e PASS=<passwd> --name brook jiobxn/v2ray-brook


    #运行一个v2ray实例
    docker run -d --restart unless-stopped -p 19443:19443 -e MODE=v2ray --name v2ray jiobxn/v2ray-brook

    #运行一个v2ray ws实例，可以套cloudflare
    docker run -d --restart unless-stopped --network host -e PORT=19445 -e MODE=v2ray -e WSPATH=/mp3 --name v2ray-ws jiobxn/v2ray-brook
    docker run -d --restart unless-stopped -p 80:80 -p 443:443 -v /docker/key:/key -e PROXY_SERVER="v2ray.example.com|www.google.co.id^backend_https=y,ws=/mp3|172.17.0.1:19445" --name google jiobxn/nginx


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-p 19443:19443 \
				-e PASS=[Random] \\    #随机密码
				-e PORT=[19443] \\     #监听端口
				-e MODE=[server] \\ <v2ray| [server|ssserver|wsserver] | [client|ssclient|wsclient]>    #运行模式：v2ray服务器、brook服务器(默认)、brook客户端
				-e UUID=[Random] \\    #随机UUID，v2ray
				-e WSPATH=</mp4> \\    #WS路径，v2ray  。path应当选择较长的字符串
				-e DOMAIN=<jiobxn.com> \\    #wsserver模式填写你的域名，wsclient模式值不为空
				-e LOG=[none] \\ <debug|info|warning|error|none>    #记录日志，v2ray
				-e HTTP=<Y> \\         #客户端启动http代理，brook。 默认socks5
				-e SERVER=<server_address:port> \\    #brook服务器地址和端口
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
