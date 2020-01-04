v2ray-brook
===
## 简介
* **V2Ray** 是一个模块化的代理软件包，它的目标是提供常用的代理软件模块，简化网络代理软件的开发。
* **Brook** 是一个跨平台(Linux/MacOS/Windows/Android/iOS)的代理软件。
> * 官方站点：https://www.v2ray.com/
> * 项目地址：https://github.com/txthinking/brook


## Example:

    #运行一个默认实例
    docker run -d --restart unless-stopped -p 19443:19443 --name v2ray-brook v2ray-brook


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always \\
				-p 19443:19443 \
				-e PASS=[Random] \\    #随机密码
				-e PORT=[19443] \\     #监听端口
				-e MODE=[server] \\ <v2ray| [server|ssserver|wsserver] | [client|ssclient|wsclient]>    #运行模式：v2ray服务器、brook服务器(默认)、brook客户端
				-e UUID=[Random] \\    #随机UUID，v2ray
				-e WSPATH=</mp4> \\    #WS路径，v2ray
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
Shadowrocket、Quantumult、i2Ray，类型选择Vmess
