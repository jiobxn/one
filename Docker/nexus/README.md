Nexus Repository Manager
===
## 简介
* **Nexus** 是一个强大的Maven仓库管理器，它极大地简化了自己内部仓库的维护和外部仓库的访问。
> * 官方站点：https://support.sonatype.com/hc/en-us


## Example:

    docker run -d --restart unless-stopped -p 8081:8081 -v /docker/nexus:/usr/local/sonatype-work --name nexus jiobxn/nexus

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-v /docker/nexus:/usr/local/sonatype-work \\
				-p 8081:8081 \\
				-e RUN_MEM=[1200M] \\
				-e MAX_MEM=[2G] \\
				-e NEXUS_PORT=[8081] \\
				-e URI_PATH=[/] \\
				--name nexus nexus
