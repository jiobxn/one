SVN
===
## 简介
* **Subversion** 是一个开源的版本控制系统。
> * 官方站点：https://subversion.apache.org/


## Example:

    docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/svn:/home/svn --hostname svn --name svn svn

    #访问svn示例 http://redhat.xyz:10080/svn   用户名/密码：admin/passwd0  user1/paaswd1

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

        docker run -d --restart unless-stopped \\
				-v /docker/svn:/home/svn \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-e REPOS=[repos] \\
				-e ADMIN=[admin] \\
				-e USER=[user1] \\
				-e ADMIN_PASS=[passwd0] \\
				-e USER_PASS=[passwd1] \\
				--hostname svn \\
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


**自动构建与部署**

svn提交后会自动执行(如果存在)hooks/post-commit文件  
参考：http://qicheng0211.blog.51cto.com/3958621/1563159
