trojan
===
## 简介
* **trojan** 机制帮助你绕过GFW。
> * 项目地址：https://github.com/trojan-gfw/trojan


## Example:

    #运行一个server实例
    docker run -d --restart unless-stopped -p 80:80 jiobxn/nginx
    docker run -d --restart unless-stopped -p 443:443 -e REMOT_ADDR=172.17.0.1 -e REMOT_PORT=80 --name trojan jiobxn/trojan

    #运行一个client实例
    docker run -d --restart unless-stopped -e REMOT_ADDR=<ip addr> -e REMOT_PORT=443 -e PASS=<passwd> -e CLIENT=Y --name trojan jiobxn/trojan


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-v /docker/key:/key \\
				-p 443:443 \\
				-e LOCAL_ADDR=[0.0.0.0] \\                         #默认监听地址，server | client
				-e LOCAL_PORT=[443 | 1080] \\                      #默认监听端口，server | client
				-e REMOT_ADDR=[127.0.0.1 | trojan.example.com] \\  #远端地址，server | client
				-e REMOT_PORT=[80 | 443] \\                        #远端端口，server | client
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
