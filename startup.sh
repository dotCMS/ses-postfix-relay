#!/usr/bin/env sh

if [ -z "$AWS_REGION" ]
then
    echo "AWS_REGION" must be set
    exit 1
fi
if [ -z "$SMTP_USERNAME" ]
then
    echo "SMTP_USERNAME" must be set
    exit 1
fi
if [ -z "$SMTP_PASSWORD" ]
then
    echo "SMTP_PASSWORD" must be set
    exit 1
fi

SMTP_HOST=email-smtp.${AWS_REGION}.amazonaws.com

cat <<EOF > /etc/postfix/sasl_passwd
[${SMTP_HOST}]:587 ${SMTP_USERNAME}:${SMTP_PASSWORD}
EOF
postmap hash:/etc/postfix/sasl_passwd
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

################################################################################
# Hostnames must identify themselves; these are the permitted values.
################################################################################
cp /root/helo_access /etc/postfix/helo_access || exit 1
postmap /etc/postfix/helo_access || exit 1

################################################################################
# Certificate Boilerplate taken from Amazon SES Documentation (Debian Specific)
################################################################################
# See https://www.saic.it/postfix-configuration-for-helo-hostname/ for details
# on alternatives for what we allow on incoming connections. Since this is
# intended as a sidecar, we can control the network environment. Within ECS 
# Tasks you may want to assign hostnames explicitly to containers, then add them
# in the helo_access file. The same goes for docker-compose. If you aren't
# using this as a sidecar, you should consider locking down your postfix
# config even further here.
postconf -e 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt' \
"relayhost = [${SMTP_HOST}]:587" \
"mynetworks = $MYNETWORKS" \
"maillog_file = /proc/self/fd/1" \
"smtp_sasl_auth_enable = yes" \
"smtp_sasl_security_options = noanonymous" \
"smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
"smtp_use_tls = yes" \
"smtp_tls_security_level = encrypt" \
"smtp_tls_note_starttls_offer = yes" \
"smtpd_helo_required = yes" \
"smtpd_helo_restrictions = permit_mynetworks, check_helo_access hash:/etc/postfix/helo_access, permit" 

exec postfix start-fg
