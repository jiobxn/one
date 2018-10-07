VSFTPD
===
## 简介
* **vsftpd** 是一个GPL许可的FTP服务器用于UNIX系统，包括Linux。三大特征:安全、速度快、稳定。
> * 下载站点：https://security.appspot.com/vsftpd.html


## Example:

    docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN -v /docker/ftp:/key/ -v /docker/vsftpd:/home -e IPTABLES=Y --name vsftp vsftpd


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN \\
				-v /docker/vsftpd:/home \\
				-v /docker/ftp:/key \\
				-v FTP_PORT=[21] \\       监听端口
				-v MIN_PORT=[25000] \\    数据端口(起始)
				-v MAX_PORT=[25100] \\    数据端口(结束)
				-v FTP_USER=[vsftpd] \\   管理员用户
				-v FTP_PASS=[$(openssl rand -hex 10)] \\    随机密码
				-v ANON_ROOT=[public] \\  匿名用户目录
				-v ANON_CHMOD=[4] \\      匿名用户权限(只读)
				-v MAX_CLINT=[0] \\       最大客户端
				-v MAX_CONN=[0] \\        最大并发数(单IP)
				-v ANON_MB=[0] \\         匿名用户传输速度
				-v LOCAL_MB=[0] \\        本地用户传输速度
				-v HI_FTP=["Serv-U FTP Server v16.0 ready"] \\    欢迎标语
				-e IPTABLES=<Y> \\
				--name vsftpd vsftpd
	

### 用户权限掩码(chmod)
  
	1 upload
	2 create
	4 download
	8 delete
	3 upload, create
	5 upload, download
	6 create, download
	7 upload, create, download
	9 upload, delete
	10 create, delete
	11 upload, create, delete
	12 download, delete
	13 upload, download, delete
	14 download, delete
	15 upload, create, download, delete


	echo -e '# -- user  -- passwd  -- chmod  -- root -- # \nadmin:123456:15:admin\npublic:123456:7:admin/public\nboss:123456:4:' |tee /docker/ftp/user.txt
