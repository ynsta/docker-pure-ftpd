#!/bin/bash

# Set pure-ftpd settings
echo "$TLS_MODE"               > /etc/pure-ftpd/conf/TLS
echo "$PASSIVEMIN $PASSIVEMAX" > /etc/pure-ftpd/conf/PassivePortRange
echo "$PUBLICHOST"             > /etc/pure-ftpd/conf/ForcePassiveIP
echo "no"                      > /etc/pure-ftpd/conf/PAMAuthentication
echo "yes"                     > /etc/pure-ftpd/conf/VerboseLog
echo "yes"                     > /etc/pure-ftpd/conf/NoAnonymous
rm /etc/pure-ftpd/auth/*
ln -sf /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/00PureDB

# Create pure-ftpd.pem if not provided by a volume
mkdir -p /etc/ssl/private/
test -e /etc/ssl/private/pure-ftpd.pem || \
    openssl req -x509 -nodes -days 7300 -newkey rsa:2048 \
    -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem \
    -subj "${SSL_SUBJ}"
chmod 600 /etc/ssl/private/pure-ftpd.pem

# Add the debian system FTP User with PUID and PGID
mkdir -p /srv/ftp

# Delete ftp user if already created
getent passwd ftp2 &>/dev/null && userdel -rf ftp &> /dev/null

# Create the ftp group and user with wanted UID and GID
groupadd --gid $PGID ftp
useradd  --uid $PUID --gid $PGID -d /srv/ftp -s /dev/null ftp
chown ftp:ftp /srv/ftp

# pureftpd.passwd already present ?
if [ -e /etc/pure-ftpd/pureftpd.passwd ]; then

    # yes so test if the UID and PID in the password file
    if ! grep -q ":$PUID:$PGID:" /etc/pure-ftpd/pureftpd.passwd; then

        # Reset the file
        rm -f /etc/pure-ftpd/pureftpd.passwd
        touch /etc/pure-ftpd/pureftpd.passwd
        chmod 600 /etc/pure-ftpd/pureftpd.passwd

        # Generate a default password that should be changed
        PASSWORD=$(pwgen -scny 12 -1); echo -e "${PASSWORD}\n${PASSWORD}\n" | pure-pw useradd $VUSER -u ftp -d /srv/ftp
    fi
fi

# Generate password database
pure-pw mkdb

# Finally run pure-ftpd
pure-ftpd $(pure-ftpd-wrapper --show-options)
