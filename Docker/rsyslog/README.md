Rsyslog
===
## 简介
* **Rsyslog** 是一个开源软件实用程序，用于UNIX和类Unix计算机系统，用于在IP网络中转发日志消息。它实现了基本的syslog协议，通过基于内容的过滤，丰富的过滤功能，灵活的配置选项扩展了它，并添加了诸如使用TCP进行传输等功能。 官方RSYSLOG网站将该实用程序定义为“用于日志处理的快速火箭系统”。
> * 官方站点：https://www.rsyslog.com/


## Example:

    docker run -d --restart unless-stopped -p 514:514 -p 514:514/udp -p 10080:80 -v /docker/rsyslog:/var/log/rsyslog -e TZ=Asia/Shanghai --name rsyslog jiobxn/rsyslog

### Linux Client配置

    echo -e "#TCP\n*.*                     @@192.168.80.130" >>/etc/rsyslog.conf

    # or UDP
    # echo -e "#TCP\n*.*                     @192.168.80.130" >>/etc/rsyslog.conf

    # bash log
    echo "local6.*   /var/log/bash_history.log" >/etc/rsyslog.d/bash.conf
    echo 'export PROMPT_COMMAND='"'"'RETRN_VAL=$?;logger -p local6.debug "$(who am i) [$$]: $(history 1 | sed "s/^[ ]*[0-9]\+[ ]*//") [$RETRN_VAL]"'"'"'' >>/etc/bashrc 

    systemctl restart rsyslog


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped \\
				-v /docker/rsyslog:/var/log/rsyslog \\
				-p 80:80 \\
				-p 514:514 \\
				-p 514:514/udp \\
				-e HTTP_PORT=[80] \\
				-e UDP_PORT=[514] \\
				-e TCP_PORT=[514] \\
				--name rsyslog rsyslog
