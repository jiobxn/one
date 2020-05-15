HTTPD
===
## 简介
* **Apache HTTP Server**（简称Apache）是Apache软件基金会的一个开放源码的网页服务器，可以在大多数计算机操作系统中运行，由于其多平台和安全性被广泛使用，是最流行的Web服务器端软件之一。
> * 官方站点：http://httpd.apache.org/
* **PHP** 是一种流行的通用脚本语言，特别适合于Web开发。
> * 官方站点：http://www.php.net/
> * REPO：https://rpms.remirepo.net/enterprise/remi-release-7.rpm

## Build Parameter

    docker build --build-arg php_v=56 -t apache:56 .

## Example:

    docker run -d --restart unless-stopped -p 80:80 -p 443:443 -v /docker/www:/var/www/html -e TZ=Asia/Shanghai -e REDIS_SERVER=172.17.0.2 -e REDIS_PASS=bigpass --name httpd apache:5.6

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart unless-stopped \\
			-v /docker/www:/var/www/html \\  http目录
			-v /docker/www:/var/www \\       php目录
			-v /docker/mp4:/boy \\           alias目录，在集群环境中通常挂载到分布式存储用于存储图片
			-v /docker/key:/key \\           ssl证书{server.crt,server.kry}
			-p 10080:80 \\   
			-p 10443:443 \\
			-p 9000:9000 \\
			-e PHP_PORT=[9000] \\             PHP服务器端口
			-e post_max_size=[4G] \\          POST提交最大数据大小
			-e upload_max_filesize=[4G] \\    最大上传文件大小
			-e max_file_uploads=[50] \\       最大并发上传文件个数
			-e memory_limit=<2048M> \\        最大使用内存大小，默认自动分配
			-e HTTP_PORT=[80] \\              HTTP端口
			-e HTTPS_PORT=[443] \\            HTTPS端口
			-e APC_CHARSET=[UTF-8] \\         字符集
			-e ROOT=<public>                  网站根目录
			-e ALIAS=</boy,/mp4> \\           alisa，第一个/boy是别名，第二个/mp4是目录路径
			-e APC_USER=<apache> \\           用于查看/basic_status的用户
			-e APC_PASS=[jiobxn.com] \\       默认密码
			-e REDIS_SERVER=<redhat.xyz> \\   redis服务器地址
			-e REDIS_PORT=[6379] \\           redis服务端口
			-e REDIS_PASS=<bigpass> \\        redis密码
			-e REDIS_DB=[0] \\                redis数据库
			--name apache apache

**关于日志记录客户端真实IP(nginx proxy)**

    log_format 参数：$http_x_forwarded_for

**最大连接数设置**

	~]# httpd -V |grep 'Server MPM'
	~]# tail /etc/httpd/conf.modules.d/00-mpm.conf
	<IfModule mpm_prefork_module>
	StartServers          50
	MinSpareServers      10
	MaxSpareServers      10
	ServerLimit         1000
	MaxClients          1000
	MaxRequestsPerChild  0
	</IfModule>
