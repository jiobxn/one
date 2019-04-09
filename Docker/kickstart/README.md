Kickstart
===
## 简介
* **Kickstart** 用于（但不仅限于）红帽企业Linux操作系统自动执行无人值守的操作系统安装和配置。
> * 官方文档：http://fedoraproject.org/wiki/Anaconda/Kickstart/zh-cn

## 使用说明

1.挂载安装源

    挂载光驱：mount /dev/sr0 /docker/os/  
    挂载ISO：mount -o loop /media/CentOS-7-x86_64-Minimal-1804.iso /docker/os/

2.创建容器

    docker run -d --restart always --network host -v /docker/ks:/key -v /docker/os:/var/www/html/os -e RANGE="192.168.80.200 192.168.80.210" -e BOOT=INSTALL --name kickstart kickstart

3.配置磁盘分区

    vim /docker/ks/ks.cfg
    
    docker cp /docker/ks/ks.cfg kickstart:/var/www/html/ks/ks.cfg

4.设置服务器从网络启动，虚拟机内存不能少于2G

#### 使用IPMI工具让服务器下一次从pxe模式启动

    ipmitool chassis bootdev pxe
    ipmitool power reset
