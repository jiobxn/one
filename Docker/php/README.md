PHP
===
## 简介
* **PHP** 是一种流行的通用脚本语言，特别适合于Web开发。
> * 官方站点：http://www.php.net/


## Example:

    docker run -d --restart always -p 9000:9000 -v /docker/www:/var/www --hostname php --name php php7

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart always --privileged \\
					-v /docker/www:/var/www \\
					-p 9000:9000 \\
					-e REDIS_SERVER=<redhat.xyz> \\   redis服务器地址
					-e REDIS_PORT=[16379] \\          redis服务端口
					-e REDIS_PASS=<bigpass> \\        redis密码
					-e REDIS_DB=[0] \\                redis数据库
					-e post_max_size=[4G] \\          POST提交最大数据大小
					-e upload_max_filesize=[4G] \\    最大上传文件大小
					-e max_file_uploads=[50] \\       最大并发上传文件个数
					-e memory_limit=<2048M> \\        最大使用内存大小，默认自动分配
					--hostname php \\
					--name php php
