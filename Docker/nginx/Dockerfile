FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools iproute bash-completion vim wget autoreconf automake make gcc-c++ iptables cronie geoip-devel libxml2-devel libxslt-devel gd-devel; yum clean all

RUN cd /usr/local/src \
        && pcre_down="https://sourceforge.net/projects/pcre/files/pcre/" && pcre_v=$(curl -s $pcre_down |grep "tr title" |awk -F\" 'NR==1{print $2}') && wget -c "$pcre_down$pcre_v/pcre-$pcre_v.tar.gz" \
        && wget -c https://www.openssl.org/source/$(curl -s https://www.openssl.org/source/ |grep tar.gz |awk -F\" 'NR==2{print $2}') \
        && wget -c http://zlib.net/$(curl -s http://zlib.net/ |grep "\.tar.gz" |awk -F\" 'NR==1{print $2}') \
        && wget -c $(curl -s http://www.cpan.org/src/ |grep wget |awk -F\" '{print $2}') \
        && wget -c https://github.com$(curl -s https://github.com/acassen/keepalived/releases |grep tar.gz |awk -F\" 'NR==1{print $2}') \
        && nginx_v=$(curl -s http://nginx.org/ |awk -F'download.html">nginx-' '{print $2}' |grep -v ^$ |awk -F'<' 'NR==1{print $1}') && wget -c http://nginx.org/download/nginx-$nginx_v.tar.gz

RUN cd /usr/local/src \
        && tar zxf nginx-*.tar.gz \
        && tar zxf pcre-*.tar.gz \
        && tar zxf openssl-*.tar.gz \
        && tar zxf zlib-*.tar.gz \
        && tar zxf perl-*.tar.gz \
        && tar zxf v*.tar.gz \
        && \rm *.tar.gz \
        && mv pcre-* pcre \
        && mv zlib-* zlib \
        && mv openssl-* openssl \
        && cd /usr/local/src/zlib \
        && ./configure && make -j8 && make install \
        && cd /usr/local/src/perl-* \
        && ./Configure -des && make -j8 && make install \
        && cd /usr/local/src/openssl \
        && ./config --prefix=/usr/local zlib threads shared  && make -j8 && make install \
        && echo "/usr/local/lib64" >> /etc/ld.so.conf && ldconfig \
        && cd /usr/local/src/keepalived-* \
        && ./build_setup \
        && ./configure --sysconf=/etc && make -j8 && make install \
        && cd /usr/local/src/nginx-* \
        && sed -i 's/\.openssl\/include/include/' auto/lib/openssl/conf \
        && sed -i 's/\.openssl\/lib\///' auto/lib/openssl/conf \
        && ./configure --prefix=/usr/local/nginx \
           --with-pcre=/usr/local/src/pcre \
           --with-zlib=/usr/local/src/zlib \
           --with-openssl=/usr/local/src/openssl \
           --with-threads \
           --with-file-aio \
           --with-http_ssl_module \
           --with-http_v2_module \
           --with-http_realip_module \
           --with-http_addition_module \
           --with-http_xslt_module \
           --with-http_image_filter_module \
           --with-http_geoip_module \
           --with-http_sub_module \
           --with-http_dav_module \
           --with-http_flv_module \
           --with-http_mp4_module \
           --with-http_gunzip_module \
           --with-http_gzip_static_module \
           --with-http_auth_request_module \
           --with-http_random_index_module \
           --with-http_secure_link_module \
           --with-http_degradation_module \
           --with-http_slice_module \
           --with-http_stub_status_module \
           --with-http_perl_module \
           --with-mail \
           --with-mail_ssl_module \
           --with-stream \
           --with-stream_ssl_module \
        && make -j8 && make install \
        && rm -rf /usr/local/src/* \
        && ln -s /usr/local/nginx/sbin/* /usr/local/bin/

VOLUME /usr/local/nginx/html /key /usr/local/nginx/logs

COPY nginx.sh /nginx.sh
RUN chmod +x /nginx.sh

ENTRYPOINT ["/nginx.sh"]

EXPOSE 80 443

CMD ["nginx"]

# docker build -t nginx .
# docker run -d --restart always -p 80:80 -p 443:443 -v /docker/www:/www -v /docker/nginx:/key -e DOMAIN_PROXY="fqhub.com%backend_https=y" -e PROXY_SERVER="jiobxn.com,www.jiobxn.com|jiobxn.wordpress.com%backend_https=y,alias=/down|/www" --hostname nginx --name test-nginx nginx
# docker run -it --rm nginx --help
