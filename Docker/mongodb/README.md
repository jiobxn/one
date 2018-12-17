MongoDB
===
## 简介
* **MongoDB** 是一个开源文档数据库，提供高性能，高可用性和自动扩展。
> * 官方站点：https://www.mongodb.com/


## Example:

    #运行一个单机版MongoDB
    docker run -d --restart always -p 27017:27017 -p 28017:28017 -v /docker/mongodb:/var/lib/mongo -e MONGO_ROOT_PASS=NewP@ss --hostname mongodb --name mongodb mongodb

    #运行一个MongoDB副本集
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.81 -v /docker/mongodb1:/var/lib/mongo -e VIP=10.0.0.80 -e IPTABLES="10.0.0.0/24,192.168.10.0/24" --hostname mongodb1 --name mongodb1 mongodb 
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.82 -v /docker/mongodb2:/var/lib/mongo -e VIP=10.0.0.80 -e IPTABLES="10.0.0.0/24,192.168.10.0/24" --hostname mongodb2 --name mongodb2 mongodb  
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.83 -v /docker/mongodb3:/var/lib/mongo -e VIP=10.0.0.80 -e MONGO_SERVER="10.0.0.81,10.0.0.82,10.0.0.83" -e IPTABLES="10.0.0.0/24,192.168.10.0/24" -e MONGO_BACK=Y --hostname mongodb3 --name mongodb3 mongodb
    #注意：顺序不能错，要先运行二级节点，再运行主节点。要添加新节点，先运行一个新的二级节点，再到主节点上 rs.add("newip")

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always [--privileged] \\
				-v /docker/mongodb:/var/lib/mongo \\
				-p 27017:27017 \\
				-p 28017:28017 \\
				-e MONGO_ROOT_PASS=<newpass> \\    创建 root用户 的密码
				-e MONGO_USER=<user1> \\           创建一个mongodb用户
				-e MONGO_PASS=<newpass> \\         mongodb用户的密码
				-e MONGO_DB=<test> \\              创建的数据库名称，为空则与用户同名
				-e MONGO_HTTP=<Y> \\               开启HTTP功能
				-e MONGO_BACK=<Y> \\               开启自动备份数据库，默认只保留3天的备份
				-e REPL_NAME=[rs0] \\              副本集名称
				-e VIP=<10.0.0.80>                 PRIMARY IP Addr，需要 --privileged
				-e MONGO_SERVER=<10.0.0.81,10.0.0.82,10.0.0.83>   集群节点数建议大于或等于3
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\    防火墙，需要 --privileged
				--hostname mongodb \\
				--name mongodb mongodb

    备份库：mongodump -h <hostname><:port> -d dbname -o <directory-path>
    还原库：mongorestore -h <hostname><:port> -d dbname <directory-path>
    备份表：mongoexport -h <hostname><:port> -d dbname -c tabname -o <filename>
    还原表：mongoimport -h <hostname><:port> -d dbname -c tabname <filename>
