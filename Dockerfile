FROM debian:13.4

RUN apt update && apt install -y \
    curl \
    iproute2 \
    nftables \
    gnupg2 \
    desktop-file-utils \
    libcap2-bin \
    libnss3-tools \
    libpcap0.8 \
    sudo \
    supervisor \
    lsb-release

# Add Cloudflare GPG key and repository
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# install gost
COPY lib/gost_2.12.0_linux_amd64.tar.gz /tmp/gost.tar.gz
RUN tar -zxvf /tmp/gost.tar.gz -C /usr/local/bin/ && chmod +x /usr/local/bin/gost
# install gost
COPY lib/cloudflare-warp_2026.1.150.0_amd64.deb /tmp/warp.deb
RUN dpkg -i /tmp/warp.deb

# clean tmp pkg and apt
RUN rm /tmp/* && apt clean && rm -rf /var/lib/apt/lists/*

# Create a non-root user for WARP registration  
# Use UID 1001 to avoid conflicts with existing users
RUN useradd -m -s /bin/bash -u 1001 cloudflare

# Create a wrapper script to run WARP commands as cloudflare
RUN echo '#!/bin/bash\n\
exec su -c "$*" cloudflare\n\
' > /usr/local/bin/run-as-cloudflare && chmod +x /usr/local/bin/run-as-cloudflare

# Copy configuration files and scripts
COPY warp-setup.sh /usr/local/bin/warp-setup.sh
COPY gost-setup.sh /usr/local/bin/gost-setup.sh
COPY clean-logs.sh /usr/local/bin/clean-logs.sh
RUN chmod +x /usr/local/bin/warp-setup.sh
RUN chmod +x /usr/local/bin/gost-setup.sh
RUN chmod +x /usr/local/bin/clean-logs.sh
COPY supervisord.conf /etc/supervisord.conf

# Create supervisor log directory
RUN mkdir -p /var/log/supervisor

# Expose SOCKS5/HTTP proxy port
EXPOSE 1080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]