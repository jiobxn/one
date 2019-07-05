FileBrowser
===
## 简介
* **File Browser** 是简单好用的跨平台文件管理工具，支持英、法、日、中等语言。
> * 项目地址：https://github.com/filebrowser/filebrowser


## Example:

    #运行一个默认实例
    docker run -d --restart unless-stopped -p 8080:8080 -v /docker/filebrowser:/srv --name filebrowser jiobxn/filebrowser


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-v /docker/filebrowser:/srv
				-p 8080:8080 \
				-e FB_PORT=[8080] \\
				-e FB_AUTH=<Y> \\    #开启用户认证
				--name filemanager filemanager
