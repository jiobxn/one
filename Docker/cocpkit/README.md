COCPKIT
===

## Example:

    #运行一个默认实例
    docker run -d --restart always --privileged -p 9090:9090 -v /sys/fs/cgroup:/sys/fs/cgroup:ro -e PASS=root@ssh@pass --name webshell cockpit


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always --privileged \\
				-v /sys/fs/cgroup:/sys/fs/cgroup:ro \\
				--p 9090:9090 \\
				-e PASS=[pwmake 64] \\    #root密码
				--name webshell cockpit
