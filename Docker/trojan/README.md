trojan
===
## 简介
* **trojan** An unidentifiable mechanism that helps you bypass GFW.
> * 项目地址：https://github.com/trojan-gfw/trojan


## Example:

    #运行一个默认实例
    docker run -d --restart unless-stopped --network host --name trojan trojan


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
				-e PASS:=[Random] \\                               #随机密码
				--name trojan trojan

****

### trojan客户端

**Windown/MacOS**  
https://github.com/trojan-gfw/trojan/releases

**Android**  
https://github.com/trojan-gfw/igniter/releases  

**IOS**  
Shadowrocket
