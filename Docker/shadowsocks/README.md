Shadowsocks
===
## 简介
* **shadowsocks** 是一种基于Socks5代理方式的网络数据加密传输包，并采用Apache许可证、GPL、MIT许可证等多种自由软件许可协议开放源代码。
> * 项目地址：https://github.com/shadowsocks


## Example:

    #运行一个SS服务器
    docker run -d --restart always -p 8443:8443 -e SS_K=MyPassw01d --name ss jiobxn/shadowsocks

    #运行一个SSR服务器
    docker run -d --restart always -p 8444:8443 -e SS_K=MyPassw01d -e SSR=Y --name ssr jiobxn/shadowsocks

    #运行一个SS客户端
    docker run -d --restart always --network=host -e SS_S=<server ip> -e SS_P=8443 -e SS_K=MyPassw01d -e SS_B=0.0.0.0 --name ss jiobxn/shadowsocks

    #运行一个SSR客户端
    docker run -d --restart always --network=host -e SS_S=<server ip> -e SS_P=8444 -e SS_K=MyPassw01d -e SSR=Y -e SS_B=0.0.0.0 --name ssr jiobxn/shadowsocks

    # update build
    docker build --build-arg LATEST=1 -t shadowsocks .

****

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always \\
				-p 8443:8443 \
				-e SS_K=[pwmake 64] \\      随机密码
				-e SS_M=[aes-256-cfb] \\    加密方式
				-e SS_P=[8443] \\           服务器端口
				-e SS_o=[tls1.2_ticket_auth_compatible] \\    混淆插件
				-e SS_O=[auth_aes128_sha1] \\                 协议插件
				-e SSR=<Y> \\                启用SSR
				-e SS_S=<SS_SERVER> \\       服务器地址
				-e SS_B=[127.0.0.1] \\       本地监听地址
				-e SS_L=[1080] \\            本地监听端口
				--hostname shadowsocks --name shadowsocks shadowsocks

****

## 在终端中使用代理

使用代理(当前终端)

    export https_proxy=socks5://127.0.0.1:1080
    export http_proxy=socks5://127.0.0.1:1080

禁用代理

    unset http_proxy
    unset https_proxy

添加到环境变量(当前用户)

    echo -e "export https_proxy=socks5://127.0.0.1:1080\nexport http_proxy=socks5://127.0.0.1:1080" >>~/.bashrc
    source ~/.bashrc

为所有用户设置代理是在"/etc/bashrc"

验证

    curl -s https://showip.net/ ;echo

示例

    为http网站设置代理；export http_proxy=socks4://192.168.1.1:1080
    为https网站设置代理；export https_proxy=socks5://192.168.1.1:1080
    为ftp协议设置代理：export ftp_proxy=socks5://192.168.1.1:1080
    使用http代理+用户名密码认证：export http_proxy=user:pass@192.168.1.100:3128     #待验证
    使用https代理+用户名密码认证：export https_proxy=user:pass@192.168.1.100:3128   #待验证
    白名单：export no_proxy="*.aiezu.com,10.*.*.*,192.168.*.*,*.local,localhost,127.0.0.1"
    默认是sock4：export http_proxy=socks://192.168.1.1:1080

****

## 客户端下载
https://github.com/shadowsocks/shadowsocks/wiki/Ports-and-Clients  
https://github.com/breakwa11/shadowsocks-rss

### 协议插件文档
https://github.com/breakwa11/shadowsocks-rss/wiki/obfs  
https://github.com/breakwa11/shadowsocks-rss/blob/master/ssr.md  
https://github.com/breakwa11/shadowsocks-rss/wiki/config.json

****


Shadowsocks-libev
===

https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo  
yum install shadowsocks-libev


## Example:

    #运行一个SS服务器(USA)
    docker run -d --restart always -p 8443:8443 -e SS_K=MyPassw01d --name ss jiobxn/shadowsocks:libev

    #运行一个DNS服务器(china)
    docker run -d -e CLIENT_UPSTREAM=CISCO -e CHINADNS=Y -e BIND_QUERY_LOG=Y --name 11dns jiobxn/dnscrypt
    #运行一个SS服务器(china)
    docker run -d --restart always --privileged --link 11dns:mydns -p 10083:8443 -e SS_K=newpass --name 22ss jiobxn/shadowsocks:libev
    #运行一个SS客户端(china)
    docker run -d --restart always --privileged --network container:22ss -e SS_S=<server ip> -e SS_P=8443 -e SS_K=MyPassw01d -e REDIR=Y -e DNS=mydns --name 33ss jiobxn/shadowsocks:libev


****

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always --privileged \\
				-p 8443:8443 \
				-e SS_K=[pwmake 64] \\      随机密码
				-e SS_M=[aes-256-cfb] \\    加密方式
				-e SS_P=[8443] \\           服务器端口
				-e LOCAL=<Y> \\             ss-local模式
				-e REDIR=<Y> \\             ss-redir模式
				-e DNS=<mydns | dns_address> \\    指定DNS
				-e SS_S=<SS_SERVER> \\       服务器地址
				-e SS_B=[127.0.0.1] \\       本地监听地址
				-e SS_L=[1080] \\            本地监听端口
				--hostname shadowsocks --name shadowsocks shadowsocks
