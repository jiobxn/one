Systemd
===

## Example:

    #运行一个默认实例
    docker run -d --restart always --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name systemd systemd

    #不停机、不锁表的mysql主从复制。mysql master和slave的root密码要一致
    1. 运行一个master实例：docker run -d --restart always --privileged --ip=192.168.10.131 --net=mynetwork -v /docker/mysql-mini:/var/lib/mysql -v /docker/sql:/docker-entrypoint-initdb.d -e MYSQL_ROOT_PASSWORD=newpass -e MYSQL_BACK=Y -e SERVER_ID=1 -e REPL_IPR=192.168.10.% -e REPL_USER=repl -e REPL_PASSWORD=newpass --hostname mysql --name mysql mysql-mini
    2. 运行一个备份实例：docker run -d --restart always --privileged -v /docker/mysql-mini:/var/lib/mysql -v /docker/mysql-mini2:/xtrabackup -e MYSQL_ROOT_PASSWORD=newpass --name xtrabackup systemd xtrabackup
    3. 运行一个slave实例：docker run -d --restart always --privileged --ip=192.168.10.132 --net=mynetwork -v /docker/mysql-mini2:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=newpass -e MYSQL_BACK=Y -e SERVER_ID=2 -e MASTER_HOST=192.168.10.131 -e REPL_USER=repl -e REPL_PASSWORD=newpass --hostname mysql2 --name mysql2 mysql-mini
    4. 说明：要创建一个固定IP的容器用 docker network create -d=bridge --subnet=192.168.10.0/24 --gateway=192.168.10.1 mynetwork


## GNOME

    docker run -d --restart always --privileged --network host -v /sys/fs/cgroup:/sys/fs/cgroup:ro -e VNC_PASS=123456 --name gnome gnome
