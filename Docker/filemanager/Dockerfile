FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add curl tzdata && rm -rf /var/cache/apk/*

RUN cd /mnt/ \
        && wget -c https://github.com$(curl -s https://github.com/filebrowser/filebrowser/releases |grep linux-amd64-filebrowser.tar.gz |head -1 |awk -F\" '{print $2}') \
        && tar zxf linux-amd64-filebrowser.tar.gz \
        && mv filebrowser /usr/local/bin/ \
        && rm -rf /mnt/*

VOLUME /key /srv

COPY filebrowser.sh /filebrowser.sh
RUN chmod +x /filebrowser.sh

ENTRYPOINT ["/filebrowser.sh"]

EXPOSE 80

CMD ["filebrowser", "--config", "/key/config.json"]

# docker build -t filebrowser .
# docker run -d --restart unless-stopped -p 8080:80 --name filebrowser filebrowser
# docker logs filebrowser
