SSH
===
## 简介
* 一个ssh镜像

## Example:

    docker run -d --restart always --privileged -p 2222:22 --hostname ssh --name ssh -e USER=root -e PASS=123456 ssh

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

    USER=[root]        用户名
    PASS=<passwd>      随机密码
