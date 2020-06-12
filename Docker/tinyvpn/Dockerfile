FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add git iptables make g++ linux-headers openssl tzdata bash && rm -rf /var/cache/apk/*
RUN cd /mnt \
        && git clone --recursive https://github.com/wangyu-/tinyfecVPN.git \
        && git clone --recursive https://github.com/wangyu-/tinyPortMapper.git \
        && cd /mnt/tinyfecVPN \
        && make nolimit -j8 && mv tinyvpn /usr/local/bin/ \
        && cd /mnt/tinyPortMapper \
        && make -j8 && mv tinymapper /usr/local/bin/ \
        && rm -rf /mnt/*

COPY tinyvpn.sh /tinyvpn.sh
RUN chmod +x /tinyvpn.sh

EXPOSE 8000/udp

ENTRYPOINT ["/tinyvpn.sh"]

CMD ["TINYVPN"]

# docker build -t tinyvpn .
# docker run -d --restart unless-stopped --privileged -p 8000:8000/udp --name tinyvpn tinyvpn
# docker logs tinyvpn
