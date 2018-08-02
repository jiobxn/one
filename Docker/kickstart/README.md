Kickstart
===
## 简介
* **Kickstart** 用于（但不仅限于）红帽企业Linux操作系统自动执行无人值守的操作系统安装和配置。
> * 官方文档：http://fedoraproject.org/wiki/Anaconda/Kickstart/zh-cn

## beta
如果在进入图形化安装界面时报错，需要在容器中执行：\cp /var/www/html/os/isolinux/{initrd.img,vmlinuz,vesamenu.c32} /var/lib/tftpboot/
