FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       curl \
       dnsmasq \
       iproute2 \
       netcat-openbsd \
       nginx \
       openssh-server \
       procps \
       python3 \
       sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash alumno \
    && echo "alumno:alumno" | chpasswd \
    && usermod -aG sudo alumno \
    && mkdir -p /run/sshd \
    && printf "Proyecto 11 - servidor bastionado\n" > /var/www/html/index.html

COPY entrypoint.sh /usr/local/bin/target-entrypoint.sh
RUN chmod +x /usr/local/bin/target-entrypoint.sh

EXPOSE 22 53/udp 80
ENTRYPOINT ["/usr/local/bin/target-entrypoint.sh"]
