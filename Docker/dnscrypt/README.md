DNSCrypt
===
## 简介
* **DNSCrypt** 是一种用于保护客户端和DNS解析器之间的通信的协议，使用高速高安全性的椭圆曲线加密技术。
> * 项目地址：https://github.com/jedisct1/dnscrypt-proxy
> * BIND ebook：http://www.zytrax.com/books/dns/


## Example:

    #运行一个bind服务器
    docker run -d --restart unless-stopped -p 53:53/udp --name dns jiobxn/dnscrypt

    #运行一个dnscrypt服务器
    docker run -d --restart unless-stopped -p 53:53/udp -e DNSCRYPT=Y --name dns jiobxn/dnscrypt

    #在Windows上运行一个dnscrypt客户端，连接到公共DNS服务器(将本地DNS改为127.0.0.1)
    ./dnscrypt-proxy.exe

    #测试
    docker exec -it dns dig @27.0.0.1 -p 53 g.cn


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-p 53:53/udp \\
				-e VERSION=["windows 2003 DNS"] \\
				-e LISTEN=["any;"] \\                监听地址，注意有";"
				-e ALLOW_QUERY=["any;"] \\           允许所有客户端地址查询，注意有";"
				-e FORWARD=<9.9.9.9;> \\             转发DNS，不能有端口号，注意有";"
				-e CACHE_SIZE=[100m] \\              dns缓存大小
				-e QUERY_LOG=<Y> \\                  记录解析日记
				-e LOG_SIZE=[100m] \\                日志文件大小
				-e DNSCRYPT=<Y> \\                   使用dnscrypt公共DNS
				--name dns dnscrypt
