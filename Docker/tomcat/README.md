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

    docker run -d --restart unless-stopped -v /docker/webapps:/tomcat/webapps/ROOT -p 18081:8080 -p 18443:8443 --name tomcat jiobxn/tomcat

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart unless-stopped \\
					-v /docker/webapps:/tomcat/webapps/ROOT \\
					-v /docker/upload:/upload \\  alias目录，在集群环境中通常挂载到分布式存储用于存储图片
					-p 18080:8080 \\
					-p 18443:8443 \\
					-p 12345:12345 \\
					-e HTTP_PORT=[8080] \\     HTTP端口
					-e HTTPS_PORT=[8443] \\    HTTPS端口
					-e DOWN_PORT=[8005] \\     DOWN端口
					-e WWW_ROOT=[ROOT] \\      默认网站根目录是ROOT
					-e WWW_ALIAS=<"/mp4,/upload"> \\   alisa，第一个/mp4是别名，第二个/upload是目录路径
					-e JMX_PORT=<12345> \\            JMX端口，用于监控tomcat
					-e REDIS_SERVER=<redis ip> \\     redis服务器地址
					-e REDIS_PORT=[6379] \\           redis服务端口
					-e REDIS_PASS=<bigpass> \\        redis密码
					-e REDIS_DB=[0] \\                redis数据库
					-e SESSION_TTL=[30] \\            session过期时间
					-e MAX_MEM=<2048> \\              最大使用内存大小，默认自动分配
					--name tomcat tomcat

****

**关于日志记录客户端真实IP(nginx proxy)**

    sed -i 's/%h/%{X-Forwarded-For}i/g' /tomcat/conf/server.xml

****

**关于连接数**  
maxThreads: 最大请求处理线程数  
minSpareThreads: 初始化的线程池大小  
maxConnections: 处理的最大连接数  
acceptCount: 最大队列长度  

[redis验证](https://raw.githubusercontent.com/jiobxn/one/master/Script/hello.jsp)
