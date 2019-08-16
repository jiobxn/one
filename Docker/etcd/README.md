ETCD
===
## 简介
* **etcd** 是一个分布式，可靠的键值存储，用于存储分布式系统的最关键数据。
> * 快速入门：https://github.com/etcd-io/etcd/blob/master/Documentation/demo.md

****

## Example:

运行一个单机版etcd

    docker run -d --restart unless-stopped --network host --name etcd jiobxn/etcd

运行一个etcd集群

    docker run -d --restart unless-stopped --network mynetwork --ip 10.0.0.11 -e CLUSTER="10.0.0.21:2380,10.0.0.22:2380,10.0.0.23:2380" --name etcd-1 jiobxn/etcd
    docker run -d --restart unless-stopped --network mynetwork --ip 10.0.0.12 -e CLUSTER="10.0.0.21:2380,10.0.0.22:2380,10.0.0.23:2380" --name etcd-2 jiobxn/etcd
    docker run -d --restart unless-stopped --network mynetwork --ip 10.0.0.13 -e CLUSTER="10.0.0.21:2380,10.0.0.22:2380,10.0.0.23:2380" --name etcd-3 jiobxn/etcd

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart unless-stopped \\
					-v /etc/kubernetes/pki/etcd:/key
					-v /docker/etcd:/etcd/data \\
					--network host \\
					-e ETCD_PORT=[2379] \\          #默认端口
					-e ETCD_TOKEN=[token-01] \\     #集群密码
					-e CLUSTER_STATE=[new] \\       #集群状态，<new | existing>
					-e ETCD_COUNT=[10000]\\         #快照事物数
					-e CLUSTER=<10.0.0.11:2380,10.0.0.12:2380,10.0.0.13:2380> \\    #集群节点IP和端口，可以指定一个或多个，逗号分隔
					-e AUTO_TLS=<Y> \\    #启用TLS，默认会去/key/目录下找证书文件，<Y | server.crt,server.key | ca.crt,server.crt,server.key | ca.crt,server.crt,server.key,peer.crt,peer.key >
					--name etcd etcd

## 测试

    export ETCDCTL_API=3
    HOST_1=10.0.0.11
    HOST_2=10.0.0.12
    HOST_3=10.0.0.13
    ENDPOINTS=$HOST_1:2379,$HOST_2:2379,$HOST_3:2379

    etcdctl --endpoints=$ENDPOINTS member list  #列出节点
    etcdctl --endpoints=$ENDPOINTS put foo 'Hello World!'  #写入
    etcdctl --endpoints=$ENDPOINTS get foo  #读取
