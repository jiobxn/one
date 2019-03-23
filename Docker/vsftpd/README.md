VSFTPD
===
## 简介
* **vsftpd** 是一个GPL许可的FTP服务器用于UNIX系统，包括Linux。三大特征:安全、速度快、稳定。
> * 下载站点：https://security.appspot.com/vsftpd.html
> * 客户端下载：https://filezilla-project.org/download.php?type=client

**FTP连接方式**  
控制连接：标准端口为21，命令通道  
数据连接：标准端口为20，数据通道  

    主动FTP：
         命令：client> 1023  - > server 21  
         data：client> 1023 < -  server 20  

     被动FTP：  
         命令：client> 1023  - > server 21  
         data：client> 1024  - > server> 1023  


## Example:

    docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN -v /docker/ftp:/key/ -v /docker:/home -e IPTABLES=Y --name vsftp jiobxn/vsftpd
    cat /docker/ftp/ftp.log


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN \\
				-v /docker:/home \\
				-v /docker/ftp:/key \\
				-p 21:21 \\
				-p 25000-25100:25000-25100 \\
				-e FTP_PORT=[21] \\       监听端口，被动模式下可修改
				-e PASV_PORT=[25000:25100]    被动模式数据端口范围
				-e FTP_USER=[vsftpd] \\   管理员用户
				-e FTP_PASS=[$(openssl rand -hex 10)] \\    随机密码
				-e ANON_ROOT=[public] \\  匿名用户目录
				-e ANON_CHMOD=[4] \\      匿名用户权限(只读)
				-e MAX_CLINT=[0] \\       最大客户端
				-e MAX_CONN=[0] \\        最大并发数(单IP)
				-e ANON_MB=[0] \\         匿名用户传输速度
				-e LOCAL_MB=[0] \\        本地用户传输速度
				-e HI_FTP=["Serv-U FTP Server v16.0 ready"] \\    欢迎标语
				-e PASV_DISABLE=<Y> \\    禁用被动模式，使用主动模式
				-e DATA_PORT=[20] \\      主动模式数据端口
				-e FTP_SSL=<Y>            启用ssl加密
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


**windows 使用ftp://x.x.x.x访问**  
200 Switching to ASCII mode.  
550 Permission denied  
解决办法：打开IE浏览器-->【Internet选项】-->【高级】-->【使用被动FTP(用于防火墙和DSL调制解调器的兼容)】使用被动模式需要勾选、使用主动模式需要取消勾选
