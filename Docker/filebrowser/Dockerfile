FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add curl tzdata openssl && rm -rf /var/cache/apk/*

RUN cd /mnt/ \
        && wget -c https://github.com$(curl -s https://github.com/filebrowser/filebrowser/releases |grep linux-amd64-filebrowser.tar.gz |head -1 |awk -F\" '{print $2}') \
        && tar zxf linux-amd64-filebrowser.tar.gz \
        && mv filebrowser /usr/local/bin/ \
        && rm -rf /mnt/*

VOLUME /key /srv

COPY filebrowser.sh /filebrowser.sh
RUN chmod +x /filebrowser.sh

WORKDIR /key

ENTRYPOINT ["/filebrowser.sh"]

EXPOSE 8080

CMD ["FB"]

# docker build -t filebrowser .
# docker run -d --restart unless-stopped -p 8080:8080 -v /docker/filebrowser:/srv --name filebrowser filebrowser
# docker logs filebrowser
