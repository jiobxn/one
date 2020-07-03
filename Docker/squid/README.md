Squid
===
## 简介
* **Squid** 是HTTP代理服务器软件。Squid用途广泛的，可以作为缓存服务器，可以过滤流量帮助网络安全，也可以作为代理服务器链中的一环，向上级代理转发数据或直接连接互联网。
> * 官方站点：http://www.squid-cache.org/


## Example:

    #运行一个正向代理
    docker run -d --restart unless-stopped -p 8081:3128 -p 8082:43128 -e SQUID_USER=jiobxn --name squid jiobxn/squid

    #运行一个反向代理
    docker run -d --restart unless-stopped -p 8081:3128 -p 8082:43128 -e PROXY_SERVER=10.0.0.2,10.0.0.3 --name squid jiobxn/squid

    #运行一个vhost
    docker run -d --restart unless-stopped -p 8081:3128 -p 8082:43128 -e PROXY_SERVER=www.example.com|10.0.0.4 --name squid jiobxn/squid

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart unless-stopped \\
			-p 8080:3128 \\
			-p 8443:43128 \\
			-e HTTP_PORT=[3128] \\
			-e HTTPS_PORT=[43128] \\
			-e SQUID_USER=<jiobxn> \\    用户验证访问
			-e SQUID_PASS=[RANDOM] \\    默认随机密码
			-e MAX_AUTH=[5] \\           最大验证用户数
			-e PROXY_SERVER=<"10.0.0.2,10.0.0.3" | "www.example.com|10.0.0.4;test.example.com|10.0.0.5"> \\  反向代理，以";"分割为一组
			-e PROXY_HTTPS=<Y> \\      后端是否启用了HTTPS
			--name squid squid
