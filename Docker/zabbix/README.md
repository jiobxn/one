Zabbix
===
## 简介
* **zabbix** 是一个基于WEB界面的提供分布式系统监视以及网络监视功能的企业级的开源解决方案。
> * 下载站点：https://www.zabbix.com/download


## Example:

    #运行一个zabbix服务器
    docker run -d --restart always --privileged -p 11080:80 -p 11443:443 -v /docker/www:/var/www/html -e PHP_SERVER=<php-server-ip> -e ZBX_DB_SERVER=<mysql-server-ip> --hostname zabbix --name zabbix-server zabbix-httpd

    #运行一个zabbix客户端
    docker run -d --restart always --privileged --network host --name zabbix-agent zabbix-agent <zabbix-server-ip>

    #访问zabbix示例 http://<zabbix-server-ip>:11080/zabbix   用户名/密码：admin/zabbix

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always [--privileged] \\
				-v /docker/www:/var/www/html \\
				-p 11080:80 \\
				-p 11443:443 \\
				-e PHP_SERVER=<redhat.xyz> \\    PHP服务器地址
				-e PHP_PORT=[9000] \\            PHP服务端口
				-e PHP_PATH=[/var/www] \\        PHP工作路径
				-e ZBX_DB_SERVER=<redhat.xyz> \\    mysql服务器地址
				-e ZBX_DB_PORT=[3306] \\            mysql服务端口
				-e ZBX_DB_USER=[zabbix] \\          mysql用户名
				-e ZBX_DB_PASSWORD=[newpass] \\     mysql密码
				-e ZBX_DB_DATABASE=[zabbix] \\      数据库名称
				--hostname zabbix-httpd \\
				--name zabbix-httpd zabbix-httpd

提示：zabbix默认使用 被动模式，即 server --> agent，agent要开放10050端口 。主动模式是 agent --> server 。

****

## zabbix-docker-monitoring
> * 项目地址：https://github.com/monitoringartist/zabbix-docker-monitoring

	docker run -d \
		--name zabbix-db \
		--net=host \
		-p 3306:3306 \
		-v /backups:/backups \
		-v /etc/localtime:/etc/localtime:ro \
		-v /docker/zabbix-db\
		-e MARIADB_USER=zabbix \
		-e MARIADB_PASS=my_password \
		monitoringartist/zabbix-db-mariadb

	docker run -d \
		--name zabbix-server \
		--net=host \
		-p 80:80 \
		-p 10051:10051 \
		-v /etc/localtime:/etc/localtime:ro \
		-e ZS_DBHost=<zabbix-db-ip> \
		-e ZS_DBUser=zabbix \
		-e ZS_DBPassword=my_password \
		monitoringartist/zabbix-xxl

	docker run -d \
	  --name=zabbix-docker-agent \
	  --net=host \
	  --privileged \
	  -v /:/rootfs \
	  -v /var/run:/var/run \
	  --restart unless-stopped \
	  -e ZA_Server=<zabbix-server-ip> \
	  -e ZA_ServerActive=<zabbix-server-ip> \
	  monitoringartist/dockbix-agent-xxl-limited

监控容器需要做的两件事：1.运行一个dockbix-agent-xxl-limited客户端。2.导入监控模板

****

**添加到现有的zabbix 3.4**

    wget -c https://github.com/monitoringartist/zabbix-docker-monitoring/raw/gh-pages/centos7/3.4/zabbix_module_docker.so
    chmod +x zabbix_module_docker.so
    mv zabbix_module_docker.so /usr/local/zabbix/lib/
    echo -e "LoadModulePath=/usr/local/zabbix/lib\nLoadModule=zabbix_module_docker.so" >>/usr/local/zabbix/etc/zabbix_agentd.conf
    usermod -aG docker,root zabbix    #需要添加权限，或者 echo AllowRoot=1 >>zabbix_agentd.conf
    /etc/init.d/zabbix_agentd restart

**导入监控模板**  
[Zabbix-Template-App-Docker.xml](https://raw.githubusercontent.com/monitoringartist/zabbix-docker-monitoring/master/template/Zabbix-Template-App-Docker.xml) -标准(推荐)模板  
[Zabbix-Template-App-Docker-active.xml](https://raw.githubusercontent.com/monitoringartist/zabbix-docker-monitoring/master/template/Zabbix-Template-App-Docker-active.xml) -标准模板与自动发现


**添加中文显示支持(zabbix-xxl)**

    docker exec -it zabbix-server bash
    yum -y install wqy-zenhei-fonts.noarch
    \cp /usr/share/fonts/wqy-zenhei/wqy-zenhei.ttc /usr/local/src/zabbix/frontends/php/fonts/DejaVuSans.ttf
    docker restart zabbix-server

**查看容器在宿主机对应的网络接口**  
https://github.com/jiobxn/one/blob/master/Script/show_veth.sh

**清除zabbix主机不支持的监控项**  
https://github.com/jiobxn/one/blob/master/Script/clean_item.sh

**Zabbix API使用**  
1.API文档：https://www.zabbix.com/documentation/3.2/manual/api  
2.参考浏览器的URL
