FROM ubuntu:22.04

# Stand-in for a BurritoWorks store edge host (kitchen display or POS gateway).
# SSH-enabled so the Ansible layer can be exercised locally without touching a
# real store.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server sudo python3 python3-apt openssl curl jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash bwops \
    && echo 'bwops:bwops' | chpasswd \
    && usermod -aG sudo bwops \
    && mkdir -p /run/sshd \
    && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
