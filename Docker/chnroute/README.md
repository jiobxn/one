CHNRoute
===
## 简介
* **CHNRoute** 是一个用来实现CHN分流的工具。


## Example:

    #运行一个openvpn server，提供服务
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --device=/dev/net/tun -v /docker/openvpn:/key -p 1194:1194 -e IP_RANGE=10.5 --name openvpn jiobxn/openvpn
    #运行一个openvpn client，连接世界(to freedom)
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --device=/dev/net/tun -v /docker/tw:/key --network container:openvpn --name ovpn jiobxn/openvpn:client
    #添加CHN路由
    docker run -d --restart unless-stopped --cap-add NET_ADMIN --network container:openvpn -e SNAT=Y --name chnroute jiobxn/chnroute
    

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				--network container:openvpn \\                    #要分流的容器
				-e LOCAL_GW=[default] \\                          #本地网关IP
				-e LOCAL_ROUTE=<192.168.0.0/24,10.10.0.0/16> \\   #添加本地路由
				-e LOCAL_DEV=<default> \\                         #SNAT的本地网卡
				-e UP_TIME=[daily] \\                             #IP路由更新周期 daily、weekly、monthly
				-e GW_DEV=[default] \\                            #SNAT的GW网卡
				-e RAN=<default> \\                               #SNAT的源地址
				-e SNAT=<Y> \\                                    #添加SNAT，路由分流
				--name chnroute chnroute
