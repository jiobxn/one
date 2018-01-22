tinyFecVPN
===

## Example:

    #运行一个默认实例
    docker run -d --restart always --privileged -p 8000:8000/udp --name tinyvpn tinyvpn


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always --privileged \\
				-p 8000:8000/udp \\
				-p TUN_DEV=[tun10] \\    #设备名称
				-e VPN_PORT=[8000] \\    #监听端口
				-e IP_RANGE=[10.12.0] \\ #IP地址段
				-e VPN_PASS=[2017126@Guo] \\    #密码
				--name filemanager filemanager
