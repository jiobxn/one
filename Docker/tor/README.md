Tor
===
## 简介
* **Tor**（俗称暗网）是实现匿名通信的自由软件。其名源于“The Onion Router”的英语缩写。用户可透过Tor接达由全球志愿者免费提供，包含6000+个中继的覆盖网络，从而达至隐藏用户真实地址、避免网络监控及流量分析的目的。Tor用户的互联网活动相对较难追踪。
> * Tor浏览器：https://www.torproject.org/

## Example:

    docker run -d --restart unless-stopped --network mynetwork -v /docker/tor:/var/lib/tor -e PORT=80 -e WEB=10.0.0.10:80 --name tor jiobxn/tor
    cat /docker/tor/hidden_service/hostname
