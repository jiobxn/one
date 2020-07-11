Redis
===
## 简介
* Redis 是一个高性能的key-value数据库。
> * 官方站点：https://redis.io/

## Example:

    #运行一个单机版redis
    docker run -d --restart unless-stopped -v /docker/redis:/redis/data -p 6379:6379 -e TZ=Asia/Shanghai -e LOCAL_STROGE=Y -e REDIS_PASS=bigpass --name redis redis

    #运行一个redis主从
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --network mynetwork --ip=10.0.0.91 -e VIP=10.0.0.90 -e REDIS_PASS=bigpass --name redis1 jiobxn/redis
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --network mynetwork --ip=10.0.0.92 -e REDIS_MASTER=10.0.0.91 -e VIP=10.0.0.90 -e MASTER_PASS=bigpass --name redis2 jiobxn/redis 
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --network mynetwork --ip=10.0.0.93 -e REDIS_MASTER=10.0.0.91 -e VIP=10.0.0.90 -e MASTER_PASS=bigpass --name redis3 jiobxn/redis

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart unless-stopped [--cap-add=NET_ADMIN] \\
					-v /docker/redis:/redis/data \\
					-p 16379:6379 \\
					-e REDIS_PORT=[6379] \\
					-e REDIS_PASS=<bigpass> \\            设置一个密码
					-e LOCAL_STROGE=Y \\                  开启持久化
					-e REDIS_MASTER=<10.0.0.91> \\        master ip addr
					-e MASTER_PASS=<bigpass> \\           master 密码
					-e VIP=<10.0.0.90> \\                 master ip addr，需要 --cap-add NET_ADMIN
					-e MASTER_NAME=[mymaster] \\          master-group-name
					-e SLAVE_QUORUM=[2] \\                仲裁人数=(slave/2)+1
					-e DOWN_TIME=[6000] \\                故障转移时间，默认6秒
					--name redis redis

## 常用操作

连接

    redis-cli -h 127.0.0.1 -p 6379 -a bigpass --raw

列出所有KEY

    echo "KEYS *" |redis-cli

创建/查看/删除KEY

    SET 111 222
    SET 111
    DEL 111

切换DB/查看KEY数量

    SELECT 2
    DBSIZE

清空当前DB的KEY

    FLUSHDB

清空所有DB的KEY

    FLUSHALL

清空有序集合ZREM

    ZREMRANGEBYSCORE REDIS_TASK 0 1593532800    
    ZRANGE  REDIS_TASK 0 -1
