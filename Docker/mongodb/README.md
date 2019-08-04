MongoDB
===
## 简介
* **MongoDB** 是一个开源文档数据库，提供高性能，高可用性和自动扩展。
> * 官方站点：https://www.mongodb.com/


## Example:

    #运行一个单机版MongoDB
    docker run -d --restart unless-stopped -p 27017:27017 -v /docker/mongodb:/mongo/data -e MONGO_ROOT_PASS=NewP@ss -e MONGO_BACK=Y --name mongodb mongodb
    docker logs mongodb

    #运行一个MongoDB副本集
    docker run -d --restart unless-stopped --privileged --network=mynetwork --ip=10.0.0.81 -v /docker/mongodb1:/mongo/data -e VIP=10.0.0.80 --name mongodb1 mongodb 
    docker run -d --restart unless-stopped --privileged --network=mynetwork --ip=10.0.0.82 -v /docker/mongodb2:/mongo/data -e VIP=10.0.0.80 --name mongodb2 mongodb  
    docker run -d --restart unless-stopped --privileged --network=mynetwork --ip=10.0.0.83 -v /docker/mongodb3:/mongo/data -e VIP=10.0.0.80 -e MONGO_SERVER="10.0.0.81:27017,10.0.0.82:27017,10.0.0.83:27017" --name mongodb3 mongodb
    #注意：顺序不能错，要先运行SECONDARY节点，再运行PRIMARY节点。

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped [--privileged] \\
				-v /docker/mongodb:/mongo/data \\
				-p 27017:27017 \\
				-e MONGO_PORT=[27017] \\           mongodb端口
				-e MONGO_ROOT_PASS=[random] \\     创建 root用户 的密码
				-e MONGO_USER=<user1> \\           创建一个mongodb用户
				-e MONGO_PASS=<newpass> \\         mongodb用户的密码
				-e MONGO_DB=<user1> \\             创建的数据库名称，为空则与用户同名
				-e MONGO_BACK=<Y> \\               开启自动备份数据库，默认只保留3天的备份
				-e REPL_NAME=<rs0> \\              副本集名称
				-e VIP=<10.0.0.80> \\              PRIMARY IP Addr，需要 --privileged
				-e MONGO_SERVER=<10.0.0.81:27017,10.0.0.82:27017,10.0.0.83:27017>  \\ 集群节点数建议大于或等于3,小于等于7
				--name mongodb mongodb

    备份库：mongodump -h <hostname><:port> -d dbname -o <directory-path>
    还原库：mongorestore -h <hostname><:port> -d dbname <directory-path>
    备份表：mongoexport -h <hostname><:port> -d dbname -c tabname -o <filename>
    还原表：mongoimport -h <hostname><:port> -d dbname -c tabname --upsert <filename>

****


1、使用适当的选项启动副本集的每个成员

    mongod --replSet "rs0" --bind_ip 0.0.0.0


2、将mongo shell连接到其中一个mongod实例

	mongo

3、初始化副本集

	rs.initiate( {
	   _id : "rs0",
	   members: [
		  { _id: 0, host: "10.0.0.81:27017" },
		  { _id: 1, host: "10.0.0.82:27017" },
		  { _id: 2, host: "10.0.0.83:27017" }
	   ]
	})

4、查看副本集配置

	rs.conf()

5、检查副本集的状态

	rs.status()

将成员添加到副本集

	rs.add( { host: "mongodb3.example.net:27017", priority: 1, votes: 0 } )


从副本集中删除成员

	db.shutdownServer()
	rs.remove("mongod3.example.net:27017")


替换副本集成员

	cfg = rs.conf()
	cfg.members[0].host = "mongo2.example.net"
	rs.reconfig(cfg)

副本之间使用ssl连接

	openssl rand -base64 756 > <path-to-keyfile>
	chmod 400 <path-to-keyfile>

	security:
	  keyFile: <path-to-keyfile>
	replication:
	  replSetName: <replicaSetName>
	net:
	   bindIp: localhost,<hostname(s)|ip address(es)>

延迟节点

	cfg = rs.conf()
	cfg.members[0].priority = 0
	cfg.members[0].hidden = true
	cfg.members[0].slaveDelay = 3600
	rs.reconfig(cfg)

节点优先级

	cfg = rs.conf()
	cfg.members[0].priority = 0.5
	cfg.members[1].priority = 2
	cfg.members[2].priority = 2
	rs.reconfig(cfg)
