For use with dotCMS 5.3.x.

Newer dotCMS versions should use https://www.dotcms.com/docs/latest/mail-configuration

# SES Postfix Relay

Set credentials in `docker-compose.yml` then
```
docker build . -t ses-postfix-relay 
docker-compose up -d 
```


## helo_access

In addition to `MYNETWORKS`, you will need to specify the hosts from 
which you accept `HELO` messages in [helo_access](./helo_access). You can use POSIX Regular Expressions (PCRE) here if you wish.

See [access(5)](http://www.postfix.org/access.5.html) and [regex_table(5)](http://www.postfix.org/regexp_table.5.html) for details on the HOST NAME patterns allowed here.

## "binary" dotCMS installs
This is intended for inclusion in a docker-compose.yml file alongside a dotCMS container. 

For binary install, change
```
    networks:
      - smtp_net
```
to
```
    networking_mode: host
```


## Testing

You can attach to the container and send a test message. The final line must contain a period with no other content.

```sh
sendmail -f noreply@mydomain.com recipient@example.com
From: MyDomain Notification
Subject: Amazon SES Test                
This message was sent using Amazon SES.                
.
```

## Troubleshooting

```
Feb 17 17:56:02 ip-10-150-241-58 postfix/smtpd[978]: NOQUEUE: reject: RCPT from localhost[127.0.0.1]: 451 4.3.0 <ip-10-150-241-58.ec2.internal>: Temporary lookup failure; from=<from@example.com> to=<to@example.com> proto=ESMTP helo=<ip-10-150-241-58.ec2.internal>
```

Some things to check:

* is the `RCPT from` address in `MYNETWORKS`
* is the `from=` address permissible in your SES relay
* is the `to=` address permissible in your SES relay
* does the hostname in `helo=` match an entry in [helo_access](./helo_access)

## Related Links

* https://github.com/tmclnk/ses-postfix-relay
* https://hub.docker.com/repository/docker/tmclnk/ses-postfix-relay
* https://docs.aws.amazon.com/ses/latest/DeveloperGuide/postfix.html
* https://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html
