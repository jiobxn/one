Redis
===
## 简介
* Redis 是一个高性能的key-value数据库。
> * 官方站点：https://redis.io/

## Example:

    #运行一个单机版redis
    docker run -d --restart always -v /docker/redis:/usr/local/redis/data -p 6379:6379 -e LOCAL_STROGE=Y -e REDIS_PASS=bigpass --hostname redis --name redis redis

    #运行一个redis主从
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.91 -e VIP=10.0.0.90 -e REDIS_PASS=bigpass --hostname redis1 --name redis1 redis
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.92 -e REDIS_MASTER=10.0.0.91 -e VIP=10.0.0.90 -e MASTER_PASS=bigpass --hostname redis2 --name redis2 redis 
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.93 -e REDIS_MASTER=10.0.0.91 -e VIP=10.0.0.90 -e MASTER_PASS=bigpass --hostname redis3 --name redis3 redis

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart always [--privileged] \\
					-v /docker/redis:/usr/local/redis/data \\
					-p 16379:6379 \\
					-e REDIS_PASS=<bigpass> \\            设置一个密码
					-e LOCAL_STROGE=Y \\                  开启持久化
					-e REDIS_MASTER=<10.0.0.91> \\        master ip addr
					-e MASTER_PASS=<bigpass> \\           master密码
					-e VIP=<10.0.0.90> \\                 master ip addr，需要 --privileged
					-e MASTER_NAME=[mymaster] \\          master-group-name
					-e SLAVE_QUORUM=[2] \\                仲裁人数=(slave/2)+1
					-e DOWN_TIME=[6000] \\                故障转移时间，默认6秒
					-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\    防火墙，需要 --privileged
					--hostname redis \\
					--name redis redis
