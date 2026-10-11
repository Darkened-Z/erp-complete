FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git curl sudo cron xvfb libfontconfig wkhtmltopdf \
    python3-dev python3-pip python3-venv \
    libmysqlclient-dev mysql-client \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && apt-get clean

RUN useradd -m -s /bin/bash frappe \
    && usermod -aG sudo frappe \
    && echo "frappe ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/frappe

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER frappe
WORKDIR /home/frappe
ENV PATH="/home/frappe/.local/bin:${PATH}"

RUN pip3 install frappe-bench

ENTRYPOINT ["/entrypoint.sh"]
