#!/usr/bin/env sh

if [ -r "$AWS_REGION_OVERRIDE" ]
then
    echo "AWS_REGION_OVERRIDE" must be set
    exit 1
fi
[ -s "$SMTPUSERNAME" ] || exit 1
then
    echo "AWS_REGION_OVERRIDE" must be set
    exit 1
fi
[ -s "$SMTPPASSWORD" ] || exit 1
then
    echo "AWS_REGION_OVERRIDE" must be set
    exit 1
fi

cat <<EOF > /etc/postfix/sasl_passwd
[email-smtp.$region.amazonaws.com]:587 $SMTPUSERNAME:$SMTPPASSWORD
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
"relayhost = [email-smtp.$region.amazonaws.com]:587" \
"mynetworks = $MYNETWORKS" \
"smtp_sasl_auth_enable = yes" \
"smtp_sasl_security_options = noanonymous" \
"smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" \
"smtp_use_tls = yes" \
"smtp_tls_security_level = encrypt" \
"smtp_tls_note_starttls_offer = yes" \
"smtpd_helo_required = yes" \
"smtpd_helo_restrictions = permit_mynetworks, check_helo_access hash:/etc/postfix/helo_access, permit" 

################################################################################
# Start As Services
################################################################################
# Postfix can be started without writing to syslog, but I haven't figured out
# how to make that actually work, so here we are.
service rsyslog start
service postfix start

# tail-f doesn't work with overlayfs, so use disable-inotify.
# Yes, 3 dashes. 
exec tail ---disable-inotify -f /var/log/syslog
