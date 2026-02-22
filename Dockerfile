FROM perl:5.38-slim-bookworm

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and Koha repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    lsb-release \
    curl \
    && wget -O- https://debian.koha-community.org/koha/gpg.asc | gpg --dearmor -o /usr/share/keyrings/koha-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/koha-keyring.gpg] https://debian.koha-community.org/koha stable main" > /etc/apt/sources.list.d/koha.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    koha-common \
    apache2 \
    libapache2-mod-perl2 \
    mariadb-client \
    xmlstarlet \
    sudo \
    cron \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure Apache
RUN a2enmod rewrite cgi proxy_http headers expires ssl \
    && a2dissite 000-default \
    && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername

# Expose ports
# OPAC: 80
# Intranet (Staff): 8080
EXPOSE 80 8080

# Set up entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]
