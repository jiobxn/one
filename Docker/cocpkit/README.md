COCKPIT
===
## 简介
* **cockpit** 是一个服务器管理器，可以很容易地通过网络浏览器来管理你的GNU/Linux服务器。
> * 官方站点：http://cockpit-project.org/


## Example:

    #运行一个默认实例
    docker run -d --restart unless-stopped --privileged -p 9090:9090 -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name cockpit jiobxn/cockpit


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped --privileged \\
				-v /sys/fs/cgroup:/sys/fs/cgroup:ro \\
				--p 9090:9090 \\
				-e PASS=[RANDOM] \\    #root密码 默认随机
				--name cockpit cockpit
