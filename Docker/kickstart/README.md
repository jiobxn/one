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

4.客户端网络启动

如果在安装过程中左下角出现"Pane is dead"，需要在容器中执行：\cp /var/www/html/os/isolinux/{initrd.img,vmlinuz,vesamenu.c32} /var/lib/tftpboot/ ，然后重新网络启动。虚拟机测试，内存2G+。
