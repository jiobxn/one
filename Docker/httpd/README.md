HTTPD
===
## 简介
* **Apache HTTP Server**（简称Apache）是Apache软件基金会的一个开放源码的网页服务器，可以在大多数计算机操作系统中运行，由于其多平台和安全性被广泛使用，是最流行的Web服务器端软件之一。
> * 官方站点：http://httpd.apache.org/

## Build Parameter

    docker build --build-arg ZEND=1 -t httpd .

## Example:

    docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/www:/usr/local/apache/htdocs -e PHP_SERVER=redhat.xyz --hostname httpd --name httpd httpd

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always \\
				-v /docker/www:/usr/local/apache/htdocs \\
				-v /docker/upload:/upload \\  alias目录，在集群环境中通常挂载到分布式存储用于存储图片
				-v /docker/key:/key \\        ssl证书{server.crt,server.kry}
				-p 10080:80 \\   
				-p 10443:443 \\
				-e HTTP_PORT=[80] \\      HTTP端口
				-e HTTPS_PORT=[443] \\    HTTPS端口
				-e PHP_SERVER=<redhat.xyz> \\    PHP服务器地址
				-e PHP_PORT=[9000] \\            PHP服务器端口
				-e PHP_PATH=[/var/www] \\        PHP工作路径
				-e SERVER_NAME=<www.redhat.xyz,redhat.xyz> \\  绑定主机名
				-e WWW_ALIAS=<"/upload,/upload"> \\   alisa，第一个upload是别名，第二个upload是目录路径
				-e APC_USER=<jiobxn> \\   用于查看/basic_status的用户
				-e APC_PASS=<123456> \\     默认随机密码
				--hostname httpd \\
				--name httpd httpd

**关于日志记录客户端真实IP(nginx proxy)**

    log_format 参数：$http_x_forwarded_for
