kcp2raw
===
## 简介
**KCP** 是一个快速可靠协议，能以比 TCP浪费10%-20%的带宽的代价，换取平均延迟降低 30%-40%，且最大延迟降低三倍的传输效果。
**udp2raw tunnel** 通过raw socket给UDP包加上TCP或ICMP header，进而绕过UDP屏蔽或QoS，或在UDP不稳定的环境下提升稳定性。

> * kcptun项目地址：https://github.com/xtaci/kcptun
> * udp2raw项目地址：https://github.com/wangyu-/udp2raw-tunnel

## Example:

    #运行一个server实例
    docker run -d --restart unless-stopped --network host -e SERVICE=10.0.0.10:80 --name kcp2raw kcp2raw

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-p 20000:20000 \
				-e POER=[20000] \\                    #默认服务端口
				-e RPORT=[4000] \\                    #默认中转端口
				-e PASS=[openssl passwd $RANDOM] \\   #默认随机密码
				-e SERVICE=<172.17.0.1:22> \\         #后端服务器IP和端口
				-e SERVER=<12.34.56.78:20000> \\      #kcp2raw服务器IP和端口
				--name kcp2raw kcp2raw
