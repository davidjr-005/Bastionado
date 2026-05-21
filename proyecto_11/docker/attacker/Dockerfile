FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       curl \
       dnsutils \
       hping3 \
       hydra \
       iproute2 \
       iputils-ping \
       netcat-openbsd \
       nmap \
       openssh-client \
       sshpass \
       tcpdump \
    && rm -rf /var/lib/apt/lists/*

COPY run_emulation.sh /opt/emulation/run_emulation.sh
RUN chmod +x /opt/emulation/run_emulation.sh

CMD ["tail", "-f", "/dev/null"]
