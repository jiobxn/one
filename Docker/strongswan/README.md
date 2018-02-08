Strongswan
===
## 简介
* **strongSwan** 一个基于IPsec的开放源代码VPN解决方案。
> * 官方站点：https://www.strongswan.org/


## Example:

    docker run -d --restart always --privileged -v /docker/strongswan:/key --network=host -e VPN_PASS=123456 --hostname strongswan --name strongswan jiobxn/strongsw

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always --privileged \\
			-v /docker/strongswan:/key \\
			--network=host \\              使用宿主机网络
			-e VPN_USER=[jiobxn] \\        默认VPN用户名
			-e VPN_PASS=<123456> \\        默认随机密码
			-e VPN_PSK=[jiobxn.com] \\     PSK密码
			-e P12_PASS=[jiobxn.com] \\    P12密码
			-e SERVER_CN=<SERVER_IP> \\    默认是服务器公网IP，不能填错
			-e CLIENT_CN=["strongSwan VPN"] \\    P12证书标识，便于在iphone上识别
			-e CA_CN=["strongSwan CA"] \\         CA证书标识
			-e IP_RANGE=[10.11.0] \\              分配的IP地址池
			--hostname strongswan \\
			--name strongswan strongswan

### IOS Client:

    L2TP: user+pass+psk    #L2TP在墙内不可用
    IPSec: ca.crt+user+pass+psk or ca.crt+strongswan.p12+user+pass, 注意: Server is SERVER_CN
    IKEv2: user+pass+ca.crt, 注意: Remote ID is SERVER_CN, Local ID is user    #IKEv2在墙内不可用

### Windows Client:

    L2TP: user+pass+psk, --network=host
    IKEv2: user+pass+ca.crt or user+pass+ca.crt+strongswan.p12, 注意: Server is SERVER_CN. 证书管理器: certmgr.msc

### Windows 10 BUG:

    C:\Users\admin>powershell               #to PS Console
    PS C:\Users\jiobx> get-vpnconnection    #Show IKEv2 vpn connection name
    PS C:\Users\jiobx> set-vpnconnection "IKEv2-VPN-Name" -splittunneling $false    #Stop split tunneling
    PS C:\Users\jiobx> get-vpnconnection    #list
    PS C:\Users\jiobx> exit

