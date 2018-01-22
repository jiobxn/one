FileManager
===

## Example:

    #运行一个默认实例
    docker run -d --restart always -p 8080:80 --name filemanager filemanager


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always \\
				-v /docker/date:/srv
				-p 80:80 \
				-e FM_PORT=[80] \\
				-e FM_AUTH=[Y] \\    #需要用户认证
				--name filemanager filemanager
