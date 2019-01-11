SVN
===
## 简介
* **Subversion** 是一个开源的版本控制系统。
> * 官方站点：https://subversion.apache.org/


## Example:

    docker run -d --restart unless-stopped -p 10080:80 -p 10443:443 -v /docker/svn:/home/svn --name svn jiobxn/svn
    docker logs svn

    #访问svn示例 http://redhat.xyz:10080/svn

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN \\
				-v /docker/svn:/home/svn \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-p 13690:3690 \\
				-e SVN_PORT=[3690] \\     #svn端口
				-e HTTP_PORT=[80] \\      #http端口
				-e HTTPS_PORT=[443] \\    #https端口
				-e REPOS=[repos] \\       #默认仓库名
				-e ADMIN=[admin] \\       #管理员用户
				-e USER=[user1] \\        #普通用户
				-e ANON=<Y> \\            #开启匿名用户，还需在authz配置 *=r
				-e ADMIN_PASS=[$(openssl rand -hex 10)] \\   #随机密码
				-e USER_PASS=[$(openssl rand -hex 6)] \\     #随机密码
				-e IPTABLES=<Y> \\        #防火墙
				--name svn svn

提示：svn默认只创建两个用户和一个仓库，如果需要更复杂的权限和更多的用户，请提前准备好 authz、passwd 放入 svn/conf 目录。


****

检出项目

    svn co http://192.168.0.68/svn/repos/ --username admin --password passwd0 --non-interactive

添加文件

    cd repos
    touch aaa
    svn add aaa

提交

    svn commit -m add --force --username admin --password passwd0

删除文件

    svn rm aaa

提交

    svn commit -m rm --username admin --password passwd0

更新

    svn up --username admin --password passwd0

查找

    svn list -R --username admin --password passwd0 http://192.168.0.68/svn/repos/


**自动构建与部署**

svn提交后会自动执行(如果存在)hooks/post-commit文件  
参考：http://qicheng0211.blog.51cto.com/3958621/1563159

**Windows svn 迁移到Linux**  

1.将项目文件夹拷贝到/docker/svn/  
2.执行 echo -e "4\nlayout sharded 1000" >/docker/svn/xxxx/db/format
