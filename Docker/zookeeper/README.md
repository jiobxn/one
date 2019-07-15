ZooKeeprt
===
## 简介
* **Apache ZooKeeper** 是Apache软件基金会的一个软件项目，他为大型分布式计算提供开源的分布式配置服务、同步服务和命名注册。ZooKeeper曾经是Hadoop的一个子项目，但现在是一个独立的顶级项目。
> * 管理员文档：https://zookeeper.apache.org/doc/trunk/zookeeperAdmin.html

## Example:

    #运行一个单机版ZK
    docker run -d --restart unless-stopped -p 2181:2181 -v /docker/zookeeper:/zookeeper/data --name zookeeper zookeeper

    #运行一个ZK集群
    docker run -d --restart unless-stopped --privileged --network=mynetwork --ip=10.0.0.71 -v /docker/zookeeper1:/zookeeper/data -e ZK_SERVER=10.0.0.71,10.0.0.72,10.0.0.73 -e VIP=10.0.0.70 --name zookeeper1 zookeeper
    docker run -d --restart unless-stopped --privileged --network=mynetwork --ip=10.0.0.72 -v /docker/zookeeper2:/zookeeper/data -e ZK_SERVER=10.0.0.71,10.0.0.72,10.0.0.73 -e VIP=10.0.0.70 --name zookeeper2 zookeeper
    docker run -d --restart unless-stopped --privileged --network=mynetwork --ip=10.0.0.73 -v /docker/zookeeper3:/zookeeper/data -e ZK_SERVER=10.0.0.71,10.0.0.72,10.0.0.73 -e VIP=10.0.0.70 --name zookeeper3 zookeeper

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped [--privileged] \\
				-v /docker/zookeeper:/zookeeper/data \\
				-p 2181:2181 \\
				-e ZK_MEM=[1G] \\                                     默认内存大小1G
				-e ZK_APORT=[8080] \\                                 zookeeper admin端口
				-e ZK_PORT=[2181] \\                                  zookeeper client端口(提供服务)
				-e ZK_SPORT=[2888] \\                                 zookeeper 集群端口(选举)
				-e ZK_SERVER=<"10.0.0.71,10.0.0.72,10.0.0.73"> \\     集群节点数建议大于或等于3
				-e VIP=<10.0.0.70> \\                                 leader IP Addr，需要 --privileged
				--name zookeeper zookeeper

## 补充
查看集群状态：

    bin/zkServer.sh status

Zookeeper中角色：

    领导者(Leader)：领导者负责进行投票的发起和决议，更新系统状态，处理写请求
    追随者(Follwer)：Follower用于接收客户端的读写请求并向客户端返回结果，在选主过程中参与投票
    观察者（Observer）：观察者可以接收客户端的读写请求，并将写请求转发给Leader，但Observer节点不参与投票过程，只同步leader状态，Observer的目的是为了，扩展系统，提高读取速度。
    客户端(Client)： 执行读写请求的发起方

**监控**

	~]# echo mntr |nc 127.0.0.1 2181
	zk_version	3.4.8--1, built on 02/06/2016 03:18 GMT     版本
	zk_avg_latency	0                                           平均延迟，大于10报警
	zk_max_latency	120                                     最大延迟
	zk_min_latency	0                                       最小延迟
	zk_packets_received	1095806                         收到的数据包
	zk_packets_sent	1095807                                 发送的数据包
	zk_num_alive_connections	2                       活动连接数，
	zk_outstanding_requests	0                               请求队列，大于10报警
	zk_server_state	leader                                  服务器角色
	zk_znode_count	172                                     znodes的数量
	zk_watch_count	22                                      watches的数量
	zk_ephemerals_count	2                               ephemerals的数量
	zk_approximate_data_size	12493                   approximate的数据大小
	zk_open_file_descriptor_count	31                      打开文件数，大于%85报警
	zk_max_file_descriptor_count	65536                   最大打开文件数
	zk_followers	2                                       追随者的数量
	zk_synced_followers	2                               同步的追随者
	zk_pending_syncs	0                               等待同步，大于10报警
