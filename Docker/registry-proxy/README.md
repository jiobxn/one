Registry Proxy
===
## 简介
* 一个用于Registry v2的nginx代理


## Example:

    #运行一个单机版registry代理
    docker run -d --restart always --network host -v /docker/registry:/var/lib/registry --name registry registry
    docker run -d --restart always --network host -v /docker/registry-lb:/key -e NGX_USER=admin -e NGX_PASS=123456 --name registry-proxy registry-proxy

    #运行一个registry负载均衡
    for i in {1..3}; do docker run -d --restart=always -p 500$i:5000 -v /docker/registry:/var/lib/registry --name registry$i registry; done
    docker run -d --restart always --network host -v /docker/registry-lb:/key -e REG_SERVER=127.0.0.1:5001,127.0.0.1:5002,127.0.0.1:5003 -e NGX_USER=admin -e NGX_PASS=123456 --name=lb registry-lb

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always \\
				-v /docker/key:/key \\
				-p 8080:80 \\
				-p 443:443 \\
				-e HTTP_PORT=[80] \\
				-e HTTPS_PORT=[443] \\
				-e DOMAIN=[img.io] \\                   域名
				-e REG_SERVER=[127.0.0.1:5000] \\       Registry服务器地址和端口，多个用","分隔
				-e NGX_USER=<nginx> \\                  登陆用户名
				-e NGX_PASS=[jiobxn.com] \\             登陆密码
				--hostname registry-proxy \\
				--name registry-proxy registry-proxy

## 客户端安装证书

    echo "x.x.x.x img.io" >>/etc/hosts
    curl -s http://img.io/ca.crt >> /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
    systemctl restart docker.service

    docker login img.io
    docker pull alpine:latest
    docker tag alpine:latest img.io/alpine:latest
    docker push img.io/alpine:latest
