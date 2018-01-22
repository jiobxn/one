GNOME
===

## Example:

    #运行一个默认实例
    docker run -d --restart always --privileged -p 5901:5901 -v /sys/fs/cgroup:/sys/fs/cgroup:ro -e VNC_PASS=123456 --name gnome gnome


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always --privileged \\
				[-v /sys/fs/cgroup:/sys/fs/cgroup:ro] \\
				-v /docker/gnome:/gnome
				-p 5901:5901 \\
				-e VNC_PASS=[pwmake 64] \\    #VNC密码
				-e VNC_VIEWONLY=n \\          #默认可以界面操作
				--name gnome gnome
