Tomcat
===
## 简介
* **Tomcat** 是由Apache软件基金会下属的Jakarta项目开发的一个Servlet容器，按照Sun Microsystems提供的技术规范，实现了对Servlet和JavaServer Page（JSP）的支持，并提供了作为Web服务器的一些特有功能，如Tomcat管理和控制平台、安全域管理和Tomcat阀等。由于Tomcat本身也内含了一个HTTP服务器，它也可以被视作一个单独的Web服务器。
> * 官方站点：http://tomcat.apache.org/


## Build Defult Parameter

        TOMCAT="8.5"
        JDK="8"

    #例如要构建一个tomcat7
    docker build --build-arg TOMCAT=7.0 --build-arg JDK=7 -t tomcat .

## Example:

    docker run -d --restart always -v /docker/webapps:/usr/local/tomcat/webapps -p 18080:8080 -p 18443:8443 -e TOM_USER=tom -e TOM_PASS=pass -e REDIS_SERVER=redhat.xyz --hostname tomcat --name tomcat tomcat

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart always [--privileged] \\
					-v /docker/webapps:/usr/local/tomcat/webapps \\
					-v /docker/upload:/upload \\  alias目录，在集群环境中通常挂载到分布式存储用于存储图片
					-p 18080:8080 \\
					-p 18443:8443 \\
					-p 12345:12345 \\
					-e HTTP_PORT=[8080] \\     HTTP端口
					-e HTTPS_PORT=[8443] \\    HTTPS端口
					-e AJP_PORT=[8009] \\      AJP端口
					-e TOM_USER=<admin> \\     管理员用户名
					-e TOM_PASS=<redhat> \\    默认随机密码
					-e WWW_ROOT=[ROOT] \\      默认网站根目录是ROOT
					-e WWW_ALIAS=<"/upload,/upload"> \\   alisa，第一个upload是别名，第二个upload是目录路径
					-e SERVER_NAME=<redhat.xyz,www.redhat.xyz> \\  绑定主机名
					-e JMX_PORT=<12345> \\            JMX端口，用于监控tomcat
					-e REDIS_SERVER=<redhat.xyz> \\   redis服务器地址
					-e REDIS_PORT=[6379] \\           redis服务端口
					-e REDIS_PASS=<bigpass> \\        redis密码
					-e REDIS_DB=[0] \\                redis数据库
					-e SESSION_TTL=[30] \\            session过期时间
					-e MAX_MEM=<2048> \\              最大使用内存大小，默认自动分配
					--name tomcat tomcat

****

**关于日志记录客户端真实IP(nginx proxy)**

    sed -i 's/%h/%{X-Forwarded-For}i/g' /usr/local/tomcat/conf/server.xml

****

**关于连接数**  
maxThreads: 最大请求处理线程数  
minSpareThreads: 初始化的线程池大小  
maxConnections: 处理的最大连接数  
acceptCount: 最大队列长度  

https://tomcat.apache.org/tomcat-8.0-doc/config/http.html
