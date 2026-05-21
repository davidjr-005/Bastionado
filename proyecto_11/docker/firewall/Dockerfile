FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       ca-certificates \
       iproute2 \
       iptables \
       kmod \
       procps \
       tcpdump \
    && rm -rf /var/lib/apt/lists/*

COPY firewall-rules.sh /usr/local/bin/firewall-rules.sh
COPY entrypoint.sh /usr/local/bin/firewall-entrypoint.sh

RUN chmod +x /usr/local/bin/firewall-rules.sh /usr/local/bin/firewall-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/firewall-entrypoint.sh"]
