MongoDB
===
## 简介
* **MongoDB** 是一个开源文档数据库，提供高性能，高可用性和自动扩展。
> * 官方站点：https://www.mongodb.com/
> * 官方文档：https://docs.mongodb.com/manual/
> * 中文教程：https://www.runoob.com/mongodb/mongodb-tutorial.html

## Example:

**运行一个单机版MongoDB**

    docker run -d --restart unless-stopped -p 27017:27017 -v /docker/mongodb:/mongo/data -e MONGO_ROOT_PASS=NewP@ss -e MONGO_BACK=Y --name mongodb mongodb
    docker logs mongodb

**运行一个MongoDB副本集**

    docker run -d --restart unless-stopped --network mynetwork --ip=10.0.0.81 -v /docker/mongodb1:/mongo/data -e REPL_NAME=rs0 --name mongodb1 mongodb 
    docker run -d --restart unless-stopped --cap-add net_admin --network mynetwork --ip=10.0.0.82 -v /docker/mongodb2:/mongo/data -e VIP=10.0.0.80 -e REPL_NAME=rs0 --name mongodb2 mongodb  
    docker run -d --restart unless-stopped --cap-add net_admin --network mynetwork --ip=10.0.0.83 -v /docker/mongodb3:/mongo/data -e VIP=10.0.0.80 -e REPL_NAME=rs0 --name mongodb3 -e MONGO_SERVER="10.0.0.82:27017,10.0.0.83:27017" -e ARB_SERVER="10.0.0.81:27017" mongodb
    #注意：顺序不能错，要先运行SECONDARY节点，最后运行PRIMARY节点。

**运行一个MongoDB分片集群**

    #配置节点
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.81 -e REPL_NAME=config0 -e CLUSTER=CONFIG --name mongodb1 mongodb
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.82 -e REPL_NAME=config0 -e CLUSTER=CONFIG --name mongodb2 mongodb
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.83 -e REPL_NAME=config0 -e CLUSTER=CONFIG --name mongodb3 -e MONGO_SERVER="10.0.0.81:27017,10.0.0.82:27017,10.0.0.83:27017" mongodb

    #分片节点
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.84 -e REPL_NAME=shard0 -e CLUSTER=SHARD --name mongodb4 mongodb
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.85 -e REPL_NAME=shard0 -e CLUSTER=SHARD --name mongodb5 mongodb
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.86 -e REPL_NAME=shard0 -e CLUSTER=SHARD --name mongodb6 -e MONGO_SERVER="10.0.0.85:27017,10.0.0.86:27017" -e ARB_SERVER="10.0.0.84:27017" mongodb

    #路由节点
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.87 -e CLUSTER=ROUTER --name mongodb7 -e CONFIG_SERVER="config0/10.0.0.82:27017,10.0.0.83:27017" -e SHARD_SERVER="shard0/10.0.0.85:27017,10.0.0.86:27017" mongodb
    docker run -d --restart unless-stopped --network=mynetwork --ip=10.0.0.88 -e CLUSTER=ROUTER --name mongodb8 -e CONFIG_SERVER="config0/10.0.0.82:27017,10.0.0.83:27017" -e SHARD_SERVER="shard0/10.0.0.85:27017,10.0.0.86:27017" mongodb


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped [--cap-add net_admin] \\
				-v /docker/mongodb:/mongo/data \\
				-p 27017:27017 \\
				-e MONGO_PORT=[27017] \\           mongodb端口
				-e MONGO_ROOT_PASS=<youpasswd> \\  创建 root用户 的密码
				-e MONGO_USER=<user1> \\           创建一个mongodb用户
				-e MONGO_PASS=<newpass> \\         mongodb用户的密码
				-e MONGO_DB=<user1> \\             创建的数据库名称，为空则与用户同名
				-e MONGO_BACK=<Y> \\               开启自动备份数据库，默认只保留3天的备份
				-e REPL_NAME=<rs0> \\              副本集名称
				-e VIP=<10.0.0.80> \\              PRIMARY IP Addr，需要 --cap-add net_admin
				-e MONGO_SERVER=<10.0.0.82:27017,10.0.0.83:27017>  \\ 集群节点数建议大于或等于3,小于等于7
				-e ARB_SERVER=<10.0.0.81:27017>  \\        仲裁节点
				-e CLUSTER=<CONFIG | SHARD | ROUTER> \\    分片集群角色
				-e CONFIG_SERVER=<rsc0/10.0.0.81:27017,10.0.0.82:27017,10.0.0.83:27017> \\    配置服务器
				-e SHARD_SERVER=<rss0/10.0.0.84:27017,10.0.0.85:27017,10.0.0.86:27017> \\     分片服务器，多组用";"隔开
				--name mongodb mongodb


****

## 复制

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

	复制集状态查询：rs.status()
	查看oplog状态： rs.printReplicationInfo()
	查看复制延迟：  rs.printSlaveReplicationInfo()
	查看服务状态详情:   db.serverStatus()

准备一个新成员

	mongod --port 27017 --dbpath /data/arb --replSet rs0 --bind_ip 0.0.0.0

将新成员添加到副本集

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

将新成员添加为仲裁者

	rs.addArb("<hostname><:port>")

配置延迟副本集成员

	cfg = rs.conf()
	cfg.members[0].priority = 0
	cfg.members[0].hidden = true
	cfg.members[0].slaveDelay = 3600
	rs.reconfig(cfg)

调整副本集成员的优先级

	cfg = rs.conf()
	cfg.members[0].priority = 0.5
	cfg.members[1].priority = 2
	cfg.members[2].priority = 2
	rs.reconfig(cfg)

备份还原

    备份库：mongodump -h <hostname><:port> -d dbname -o <directory-path>
    还原库：mongorestore -h <hostname><:port> -d dbname <directory-path>
    备份表：mongoexport -h <hostname><:port> -d dbname -c tabname -o <filename>
    还原表：mongoimport -h <hostname><:port> -d dbname -c tabname --upsert <filename>


****

## 分片

**分片群集组件**

    shard：每个分片包含分片数据的子集。
    mongos：充当查询路由器，提供客户端应用程序和分片集群之间的接口。
    config servers：配置服务器存储群集的元数据和配置设置。


### 创建配置服务器副本集(元数据)

1、启动配置服务器复制集的每个成员

	mongod --configsvr --replSet <replica set name> --dbpath <path> --bind_ip localhost,<hostname(s)|ip address(es)>

2、连接到其中一个配置服务器

	mongo --host <hostname> --port <port>

3、启动副本集

	rs.initiate(
	  {
		_id: "<replSetName>",
		configsvr: true,
		members: [
		  { _id : 0, host : "cfg1.example.net:27019" },
		  { _id : 1, host : "cfg2.example.net:27019" },
		  { _id : 2, host : "cfg3.example.net:27019" }
		]
	  }
	)


### 创建分片副本集(分片)

1、启动分片副本集的每个成员

	mongod --shardsvr --replSet <replSetname>  --dbpath <path> --bind_ip localhost,<hostname(s)|ip address(es)>

2、连接到分片副本集的一个成员

	mongo --host <hostname> --port <port>

3、启动副本集

	rs.initiate(
	  {
		_id : <replicaSetName>,
		members: [
		  { _id : 0, host : "s1-mongo1.example.net:27018" },
		  { _id : 1, host : "s1-mongo2.example.net:27018" },
		  { _id : 2, host : "s1-mongo3.example.net:27018" }
		]
	  }
	)


### 将mongos连接到分片群集(路由)

1、启动mongos连接到群集

	mongos --configdb <configReplSetName>/cfg1.example.net:27019,cfg2.example.net:27019 --bind_ip localhost,<hostname(s)|ip address(es)>

2、连接到mongos

	mongo --host <hostname> --port <port>

3、将单个分片副本集添加到群集

	sh.addShard( "<replSetName>/s1-mongo1.example.net:27017")

3、将独立mongod分片添加到群集

	sh.addShard( "s1-mongo1.example.net:27017")


**为数据库启用分片(1)**

	sh.enableSharding("<database>")

**使用散列分片对集合进行分片(2)**

	sh.shardCollection("<database>.<collection>", { <shard key> : "hashed" } )

**使用远程分片对集合进行分片(3)**

	sh.shardCollection("<database>.<collection>", { <shard key> : <direction> } )


### 替换配置服务器

1、启动替换配置服务器

	mongod --configsvr --replSet <replicaSetName> --bind_ip localhost,<hostname(s)|ip address(es)>

2、将新配置服务器添加到副本集

	rs.add( { host: "<hostnameNew>:<portNew>", priority: 0, votes: 0 } )

3、更新新添加的配置服务器的投票和优先级设置

	rs.status()

	var cfg = rs.conf();

	cfg.members[n].priority = 1;  // Substitute the correct array index for the new member
	cfg.members[n].votes = 1;     // Substitute the correct array index for the new member

	rs.reconfig(cfg)

4、关闭要更换的成员

5、从配置服务器副本集中删除要替换的成员

	rs.remove("<hostnameOld>:<portOld>")

6、如有必要，请更新mongos配置或DNS条目


### 查看群集配置

列表启用了分片的数据库

	use config
	db.databases.find( { "partitioned": true } )

列出分片

	db.adminCommand( { listShards : 1 } )

查看群集细节

	sh.status()


### 从现有的分片群集中删除分片

1、确保平衡器已启用

	sh.getBalancerState()  #启用平衡器时返回true， 如果禁用平衡器则返回false。

2、确定要删除的分片的名称

	db.adminCommand( { listShards: 1 } )
	#运行 db.printShardingStatus() 或 db.printShardingStatus() 方法

4、迁移fizz从数据库 mongodb0到mongodb1

	db.adminCommand( { movePrimary: "fizz", to: "mongodb1" })

5、删除分片

	db.adminCommand( { removeShard: "mongodb0" } )
	#这些迁移发生得很慢

6、检查迁移状态

	db.adminCommand( { removeShard: "mongodb0" } )
	#直到剩余的块数为止0
