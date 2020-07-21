trojan
===
## 简介
* **trojan** 机制帮助你绕过GFW。
> * 项目地址：https://github.com/trojan-gfw/trojan


## Example:
    
    #运行一个默认实例
    docker run -d --restart unless-stopped -p 80:80 --name mask jiobxn/nginx
    docker run -d --restart unless-stopped -p 443:443 -e REMOT_ADDR=172.17.0.1 -e REMOT_PORT=80 --name trojan jiobxn/trojan
    #docker run -d --restart unless-stopped -e REMOT_ADDR=<ip addr> -e REMOT_PORT=443 -e PASS=<passwd> -e CLIENT=Y --name trojan jiobxn/trojan

    #运行一个WS实例
    docker run -d --restart unless-stopped -p 443:443 -e WSPATH=/mp3 -e SNICN=<trojan.example.com> -e REMOT_ADDR=jiobxn.com --name trojan jiobxn/trojan
    #docker run -d --restart unless-stopped -e REMOT_ADDR=<trojan.example.com> -e REMOT_PORT=443 -e WSPATH=/mp3 -e PASS=<passwd> -e CLIENT=Y --name trojan jiobxn/trojan

    #运行一个nginx WS实例
    docker run -d --restart unless-stopped --network host -e LOCAL_PORT=20717 -e WSPATH=/mp3 -e SNICN=172.17.0.1 -e REMOT_ADDR=jiobxn.com --name trojan jiobxn/trojan
    docker run -d --restart unless-stopped -p 80:80 -p 443:443 -v /docker/key:/key -e PROXY_SERVER="trojan.example.com|www.google.co.id^backend_https=y,ws=/mp3|172.17.0.1:20717" --name google jiobxn/nginx


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-v /docker/key:/key \\
				-p 443:443 \\
				-e LOCAL_ADDR=[0.0.0.0] \\                         #默认监听地址，server | client
				-e LOCAL_PORT=[443 | 1080] \\                      #默认监听端口，server | client
				-e REMOT_ADDR=[127.0.0.1 | trojan.example.com] \\  #远端地址，server | client
				-e REMOT_PORT=[80 | 443] \\                        #远端端口，server | client
				-e SNICN=[local ip] \\                             #域名或公网IP，直接暴露公网需要设置正确
				-e WSPATH=</mp3> \\                                #WS路径，path应当选择较长的字符串。Trojan协议不加密，避免被不可信的CDN识别和审查
				-e CLIENT=<Y> \\                                   #客户端模式
				-e PASS:=[RANDOM] \\                               #随机密码
				--name trojan trojan

****

### trojan客户端

**Windown/MacOS**  
https://github.com/trojan-gfw/trojan/releases

**Android**  
https://github.com/trojan-gfw/igniter/releases  

**IOS**  
Shadowrocket
