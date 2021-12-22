################################################################################
# Postfix relay for SES Email
# https://docs.aws.amazon.com/ses/latest/DeveloperGuide/postfix.html
################################################################################
# Use debian because Centos 2021 EOL and future unknowns
FROM debian:bullseye-slim

# Networks we're allowing to connect. 
# CIDRs separated by spaces. Default to localhosty and docker-y
# address ranges. Your container orchestration system may assign
# other network ranges, so be sure to override at Docker build
# time or runtime.
ARG MYNETWORKS="127.0.0.0/8 172.0.0.0/8 192.0.0.0/8"
ENV MYNETWORKS=${MYNETWORKS}

# libsasl2-modules: to connect to SES
RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get -yq install \
postfix libsasl2-modules tini && \
rm -rf /var/lib/apt/lists/*

ADD ./helo_access /root/helo_access

ADD ./startup.sh /usr/local/bin/startup.sh

ENTRYPOINT ["tini", "--", "/usr/local/bin/startup.sh"]

EXPOSE 25
