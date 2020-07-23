jsProxy
===
## 简介
* **jsProxy** 一个基于浏览器端 JS 实现的在线代理。
> * 项目地址：https://github.com/EtherDream/jsproxy


## Example:

    #运行一个默认实例
    docker run -d --restart unless-stopped -p 8080:8080 --name jsproxy jiobxn/jsproxy
    # 三种使用方式：前端套nginx+ssl证书、前端套cloudflare、直接使用ssl证书/docker/key:/key


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

                                docker run -d --restart unless-stopped --cap-add NET_ADMIN \\
                                -v /docker/key:/key \\           ssl证书 server.crt,server.kry
                                -e HTTP_PORT=[8080] \\
                                -e HTTPS_PORT=[8443] \\
                                -e DROP_LAN=<Y> \\               拒绝代理访问内网
                                --name jsproxy jiobxn/jsproxy
