Shadowsocks
===
## 简介
* **shadowsocks** 是一种基于Socks5代理方式的网络数据加密传输包，并采用Apache许可证、GPL、MIT许可证等多种自由软件许可协议开放源代码。
> * 项目地址：https://github.com/shadowsocks
> * 项目地址：https://github.com/shadowsocksr-backup/shadowsocksr
> * 项目地址：https://github.com/shadowsocks/shadowsocks-libev


## Example:

    #运行一个SS服务器
    docker run -d --restart unless-stopped -p 8443:8443 --name ss jiobxn/shadowsocks

    #运行一个SSR服务器
    docker run -d --restart unless-stopped -p 8443:8443 -e SSR=Y --name ssr jiobxn/shadowsocks

    #运行一个SS客户端
    docker run -d --restart unless-stopped --network host -e SS_S=<server ip> -e SS_K=<passwd> --name ss jiobxn/shadowsocks

    #运行一个SSR客户端
    docker run -d --restart unless-stopped --network host -e SS_S=<server ip> -e SSR=Y -e SS_K=<passwd> --name ssr jiobxn/shadowsocks

    # update build
    docker build --build-arg LATEST=1 -t shadowsocks .

****

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart unless-stopped \\
				-p 8443:8443 \
				-e SS_K=[RANDOM] \\         随机密码
				-e SS_M=[aes-256-cfb] \\    加密方式
				-e SS_P=[8443] \\           服务器端口
				-e SS_o=[tls1.2_ticket_auth_compatible] \\    混淆插件,ssr
				-e SS_O=[auth_aes128_sha1] \\                 协议插件,ssr
				-e SSR=<Y> \\                启用SSR
				-e SS_S=<SS_SERVER> \\       服务器地址
				-e SS_B=[127.0.0.1] \\       本地监听地址
				-e SS_L=[1080] \\            本地监听端口
				--name shadowsocks shadowsocks

****

## 在终端中使用代理

使用代理(当前终端)

    export https_proxy=socks5://127.0.0.1:1080
    export http_proxy=socks5://127.0.0.1:1080
    export all_proxy=socks5://127.0.0.1:1080

禁用代理

    unset http_proxy
    unset https_proxy
    unset all_proxy

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
https://github.com/JadaGates/ShadowsocksBio#Shadowsocks%E5%AE%A2%E6%88%B7%E7%AB%AF

****


Shadowsocks-libev
===

    #运行一个SS服务器(USA)
    docker run -d --restart unless-stopped -p 8443:8443 --name ss jiobxn/shadowsocks:libev

    #运行一个DNS服务器(china)
    docker run -d --restart unless-stopped -p 53:53/udp -e DNSCRYPT=Y --name dns jiobxn/dnscrypt
    #运行一个SS客户端(china)
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --network container:dns -e SS_S=<server ip> -e SS_P=8443 -e SS_K=<passwd> -e REDIR=Y -e DNS=127.0.0.1 --name ss-c jiobxn/shadowsocks:libev
    #运行一个SS服务器(china)
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --network container:dns -p 10443:8443 --name ss-s jiobxn/shadowsocks:libev

    #运行一个SS客户端
    docker run -d --restart unless-stopped --network host -e SS_S=<server ip> -e SS_P=10443 -e SS_K=<passwd> --name ss jiobxn/shadowsocks:libev


****

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart unless-stopped --cap-add NET_ADMIN \\
				-p 8443:8443 \
				-e SS_K=[RANDOM] \\         随机密码
				-e SS_M=[aes-256-cfb] \\    加密方式
				-e SS_P=[8443] \\           服务器端口
				-e REDIR=<Y> \\             ss-redir模式，透明代理
				-e DNS=<127.0.0.1> \\       指定DNS
				-e SS_S=<SS_SERVER> \\       服务器地址
				-e SS_B=[127.0.0.1] \\       本地监听地址
				-e SS_L=[1080] \\            本地监听端口
				--name shadowsocks shadowsocks
