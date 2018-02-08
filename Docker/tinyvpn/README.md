tinyFecVPN
===
## 简介
* **tinyFecVPN** 是一个工作在VPN方式的双边网络加速工具，可以加速全流量(TCP/UDP/ICMP)。
> * 项目地址：https://github.com/wangyu-/tinyFecVPN


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
