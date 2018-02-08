MySQL
===
## 简介
* **MySQL Community Server** 是世界上最流行的开源数据库。
> * 下载站点：https://dev.mysql.com/downloads/mysql/


## Example:

    #为zabbix运行一个mysql实例
    docker run -d --restart always -p 3306:3306 -v /docker/mysql-mini:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=newpass -e MYSQL_DATABASE=zabbix -e MYSQL_USER=zabbix -e MYSQL_PASSWORD=newpass -e MYSQL_BACK=Y --hostname mysql --name mysql mysql-mini

    #运行一个master实例
    docker run -d --restart always --network=mynetwork --ip=10.0.0.50 -v /docker/mysql-master:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=newpass -e SERVER_ID=1 -e REPL_IPR=10.0.0.% -e REPL_USER=repl -e REPL_PASSWORD=123456 --hostname mysql-master --name mysql-msater mysql-mini

    #运行一个slave实例，MYSQL_ROOT_PASSWORD要和Master一致
    docker run -d --restart always --network=mynetwork --ip=10.0.0.51 -v /docker/mysql-slave:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=newpass -e SERVER_ID=2 -e MASTER_HOST=10.0.0.50 -e MASTER_PORT=3306 -e REPL_USER=repl -e REPL_PASSWORD=123456 --hostname mysql-slave --name mysql-slave mysql-mini


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always [--privileged] \\
				-v /docker/mysql-mini:/var/lib/mysql \\
				-v /docker/sql:/docker-entrypoint-initdb.d \\  要导入的数据库放这里
				-p 3306:3306 \\
				-e MYSQL_ROOT_PASSWORD=<newpass> \\  root密码，默认随机密码
				-e MYSQL_DATABASE=<zabbix> \\        创建一个数据库
				-e MYSQL_USER=<zabbix> \\            创建一个mysql用户
				-e MYSQL_PASSWORD=<zbxpass> \\       mysql用户的密码
				-e MYSQL_BACK=<Y> \\                 开启自动备份数据库，默认只保留3天的备份
				-e MYSQL_PORT=[3306] \\              mysql服务端口
				-e MYSQL_MAX_CONN=[800] \\           mysql最大连接数
				-e SERVER_ID=<1> \\                  启用mysql主从模式，在主从模式下备份的数据库要想导入，必须设置SERVER ID
				-e REPL_IPR=<10.0.0.%> \\        允许repl用户从哪些IP地址来连接mysql，如果没有指定REPL_USER用户会自动创建一个repl用户和随机密码
				-e REPL_USER=<repl> \\               创建repl用户
				-e REPL_PASSWORD=<newpass> \\        repl用户的密码
				-e MASTER_HOST=<192.168.10.130> \\   master主机地址
				-e MASTER_PORT=[3306] \\             master主机端口
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\        防火墙，需要 --privileged
				--hostname mysql-mini \\
				--name mysql-mini mysql-mini
