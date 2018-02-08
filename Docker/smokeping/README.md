SmokePing
===
## 简介
* **SmokePing** 跟踪您的网络延迟。

## Example:

    #运行一个默认实例
    docker run -d --restart always -p 8080:80 -v /docker/smokeping:/usr/local/smokeping/data --name smoke smokeping

