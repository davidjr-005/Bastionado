FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       build-essential \
       ca-certificates \
       curl \
       git \
       openssh-client \
       ansible \
       python3 \
       ruby-full \
       sshpass \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://omnitruck.cinc.sh/install.sh -o /tmp/install-cinc.sh \
    && bash /tmp/install-cinc.sh -P cinc-auditor \
    && rm -f /tmp/install-cinc.sh

CMD ["tail", "-f", "/dev/null"]
