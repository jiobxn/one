ETCD
===
## 简介
* **etcd** 是一个分布式，可靠的键值存储，用于存储分布式系统的最关键数据。
> * 快速入门：https://github.com/etcd-io/etcd/blob/master/Documentation/demo.md
> * API使用：https://github.com/etcd-io/etcd/blob/master/Documentation/dev-guide/api_grpc_gateway.md

****

## Example:

运行一个单机版etcd

    docker run -d --restart unless-stopped --network host --name etcd jiobxn/etcd

运行一个etcd集群

    docker run -d --restart unless-stopped --network mynetwork --ip 10.0.0.21 -e CLUSTER="10.0.0.21:2380,10.0.0.22:2380,10.0.0.23:2380" --name etcd-1 jiobxn/etcd
    docker run -d --restart unless-stopped --network mynetwork --ip 10.0.0.22 -e CLUSTER="10.0.0.21:2380,10.0.0.22:2380,10.0.0.23:2380" --name etcd-2 jiobxn/etcd
    docker run -d --restart unless-stopped --network mynetwork --ip 10.0.0.23 -e CLUSTER="10.0.0.21:2380,10.0.0.22:2380,10.0.0.23:2380" --name etcd-3 jiobxn/etcd

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart unless-stopped \\
					-v /etc/kubernetes/pki/etcd:/key \\
					-v /docker/etcd:/etcd/data \\
					--network host \\
					-e ETCD_PORT=[2379] \\          #默认端口
					-e ETCD_TOKEN=[token-01] \\     #集群令牌
					-e CLUSTER_STATE=[new] \\       #集群状态，<new | existing>
					-e ETCD_COUNT=[10000]\\         #快照事物数
					-e CLUSTER=<10.0.0.11:2380,10.0.0.12:2380,10.0.0.13:2380> \\    #集群节点IP和端口，可以指定一个或多个，逗号分隔
					-e AUTO_TLS=<Y> \\              #启用集群间TLS连接。
					--name etcd etcd

* 默认会去/key/目录下找证书文件，根据证书文件数量自动启用不同方式的TLS  

    客户端HTTPS：server.crt,server.key  
    客户端证书认证：ca.crt,server.crt,server.key  
    集群证书认证：ca.crt,,peer.crt,peer.key  
    K8S证书认证：ca.crt,server.crt,server.key,peer.crt,peer.key

## 测试

    export ETCDCTL_API=3
    HOST_1=10.0.0.11
    HOST_2=10.0.0.12
    HOST_3=10.0.0.13
    ENDPOINTS=$HOST_1:2379,$HOST_2:2379,$HOST_3:2379

    etcdctl --endpoints=$ENDPOINTS member list  #列出节点
    etcdctl --endpoints=$ENDPOINTS put foo 'Hello World!'  #写入
    etcdctl --endpoints=$ENDPOINTS get foo  #读取

## API

ETCD API 只支持Base64格式编码

    # 编码
    echo hello |base64
    echo world |openssl enc -base64
    
    # 解码
    echo d29ybGQK |base64 -d
    echo Zm9vCg== |openssl enc -base64 -d

版本

    etcd v3.2或之前只使用 v3alpha
    etcd v3.3使用 v3beta 同时保留 v3alpha
    etcd v3.4使用 v3 同时保留 v3beta
    etcd v3.5或更高版本仅使用 v3
    
    v3=v3beta

交易

    #写入
    curl -sL http://localhost:2379/$v3/kv/put -X POST -d '{"key": "aGVsbG8K", "value": "aGVsbG8gd29ybGQhCg=="}'
    curl -sL http://localhost:2379/$v3/kv/put -X POST -d '{"key": "aGVsbG8uCg==", "value": "aGVsbG8gd29ybGQhCg=="}'

    # 读取
    curl -sL http://localhost:2379/$v3/kv/range -X POST -d '{"key": "aGVsbG8K"}'

    # 得到所有以“hello”为前缀的键
    curl -sL http://localhost:2379/$v3/kv/range -X POST -d '{"key": "aGVsbG8K", "range_end": "aGVsbG8/"}' |jq

认证

    # 创建root用户
    curl -sL http://localhost:2379/$v3/auth/user/add -X POST -d '{"name": "root", "password": "123"}'
    
    # 创建root角色
    curl -sL http://localhost:2379/$v3/auth/role/add -X POST -d '{"name": "root"}'
    
    # 授予root角色
    curl -sL http://localhost:2379/$v3/auth/user/grant -X POST -d '{"user": "root", "role": "root"}'
    
    # 启用身份验证
    curl -sL http://localhost:2379/$v3/auth/enable -X POST -d '{}'
    
    # 获取root用户的身份验证令牌
    curl -sL http://localhost:2379/$v3/auth/authenticate -X POST -d '{"name": "root", "password": "123"}'
    
    # 使用令牌来写入数据
    curl -sL http://localhost:2379/$v3/kv/put -H 'Authorization : uYkPWfLCnjmidGhI.9' -X POST -d '{"key": "Zm9v", "value": "YmFy"}'
    
    # 使用令牌来读取数据
    curl -sL http://localhost:2379/$v3/kv/range -H 'Authorization : uYkPWfLCnjmidGhI.9' -X POST -d '{"key": "Zm9v"}'
