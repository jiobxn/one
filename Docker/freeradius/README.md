FreeRadius
===
## 概述
* **FreeRADIUS** 是RADIUS(Remote Authentication Dial In User Service)的开源实现，是用于AAA（认证(authentication)，授权(authorization)和计费(accounting)）三种服务的一种网络传输协议(IETF)，通常用于网络访问、或流动IP服务，适用于局域网及漫游服务。
> * WIKI：http://wiki.freeradius.org/Home
> * 文档：http://networkradius.com/freeradius-documentation/

## Example:

    #验证信息存本地
    docker run -d --restart unless-stopped --network host -v /docker/freeradius:/key --name freeradius jiobxn/freeradius

    #验证信息存MySQL
    docker run -d --restart unless-stopped --network host -e MYSQL_DATABASE=radius -e MYSQL_USER=radius -e MYSQL_PASSWORD=radpass --name mysql jiobxn/mysql:5.7
    docker run -d --restart unless-stopped --network host -v /docker/freeradius:/key -e MYSQL_HOST=127.0.0.1 -e IPADDR_SECRET="127.0.0.1,testing123;0.0.0.0/0,newpass123" -e USER_PASS="testing,password;admin,newpass" --name freeradius jiobxn/freeradius


## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart unless-stopped --network host --cap-add=NET_ADMIN \\
				-v /docker/freeradius:/key \\
				-p 1812:1812/udp \\
				-p 1813:1813/udp \\
				-e USER_PASS=[testing,password] \\
				-e IPADDR_SECRET=[127.0.0.1,testing123] \\
				-e MYSQL_HOST=<127.0.0.1> \\
				-e MYSQL_PORT=[3306] \\
				-e MYSQL_DB=[radius] \\
				-e MYSQL_USER=[radius] \\
				-e MYSQL_PASS=[radpass] \\
				-e IPTABLES=<Y> \\
				--name freeradius freeradius

### 测试

    radtest testing password 127.0.0.1 0 testing123
    
### 查看用户

    mysql -uradius -pradpass -h127.0.0.1 -e "SELECT username FROM radius.radcheck;"

### 添加用户

    mysql -uradius -pradpass -h127.0.0.1 -e "INSERT INTO radcheck (username, attribute, op, value) VALUES ('user1','Cleartext-Password',':=','passwd1');"

### 删除用户

    mysql -uradius -pradpass -h127.0.0.1 -e "delete from radius.radcheck where username = 'testing';"

### 添加sql字段

    #给用户表添加字段
    alter table `radcheck` add column `realname` varchar(64) NOT NULL DEFAULT '';
    #删除字段
    alter table radcheck drop column realname;

## centos7 pam_radius

    yum -y install epel-release
    yum -y install pam_radius
    echo '10.10.10.10 newpass123 3' >>/etc/pam_radius.conf
    sed -i '2 i auth  sufficient  /usr/lib64/security/pam_radius_auth.so' /etc/pam.d/sshd
    useradd user1
    
    ssh user1@10.10.1.111
