GFW.Press
===
## 简介
* **GFW.Press** 新一代军用级高强度加密抗干扰网络数据高速传输软件
> * 项目地址：https://github.com/chinashiyu/gfw.press


## Example:

    docker run -d --restart always --privileged --network=host -v /docker/gfw.press:/key --hostname gfw.press --name gfw.press jiobxn/gfw.press
    docker logs gfw.press

    # update build
    docker build --build-arg LATEST=1 -t gfw.press .

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always --privileged \\
				--network=host \\
				-v /docker/gfw.press:/key \\
				-p 8080:10005 \\                       如果你不需要自动添加iptables规则(--privileged --network=host)，那就用用端口映射
				-e GFW_PORT=[10001..10005] \\          默认开启5个端口，例如想要100个端口: GFW_PORT=10001..10100
				-e GFW_PASS=[newpass|N] \\             默认是使用相同的随机密码，可自定义密码，不要太简单，如果想每个端口的密码不一样: GFW_PASS=N
				-e GFW_EMOD=[squid|sockd] \\           默认使用squid，如果想使用socks5: GFW_EMOD=sockd
				-e SQUID_USER=<jiobxn> \\              squid用户名
				-e SQUID_PASS=<123456> \\              squid密码
				--hostname gfw.press \\
				--name gfw.press gfw.press

## 客户端下载 https://github.com/chinashiyu/gfw.press
