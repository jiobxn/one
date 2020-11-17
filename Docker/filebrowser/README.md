FileBrowser
===
## 简介
* **File Browser** 是简单好用的跨平台文件管理工具，支持英、法、日、中等语言。
> * 项目地址：https://github.com/filebrowser/filebrowser
> * OwnCloud：https://doc.owncloud.org/server/10.5/admin_manual/installation/docker/
> * Cloudreve：https://github.com/cloudreve/Cloudreve


## Example:

    #运行一个默认实例
    docker run -d --restart unless-stopped -p 8080:8080 -v /docker/filebrowser:/srv --name filebrowser jiobxn/filebrowser


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-v /docker/filebrowser:/srv
				-v /docker/fbconfig:/key
				-p 8080:8080 \
				-e PORT=[8080] \\
				-e USER=[admin] \\
				-e PASS=[admin] \\
				-e ADDR=[0.0.0.0] \\
				-e DB=[filebrowser.db] \\
				-e LOG=<filebrowser.log> \\
				-e ROOT=[/srv] \\
				-e SSL=<Y> \\
				--name filebrowser filebrowser
