# Run with:
# docker run -d -it --name=pure-ftpd \
#   --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH \
#   -p 21:21 -p 35000-35099:35000-35099 \
#   -v pure-ftpd-vol:/etc/pure-ftpd \
#   -v <my data path>:/srv/ftp \
#   -e PUBLICHOST=yourfqdn.com \
#   -e VUSER=<wanted ftp user name> \
#   -e PUID=<UID of data in my data path volume> \
#   -e PGID=<GID of data in my data path volume> \
#   ynsta/pure-ftpd

# Pasword must be changed with:
# docker exec -it pure-ftpd pure-pw passwd VUSER -m

FROM debian:stable-slim

LABEL maintainer="Stany MARCEL <stanypub@gmail.com>"
LABEL version="0.2"
LABEL description="Pure-FTPd Debian based image"

ENV LANG C.UTF-8

# Virtual username used to connect to FTP
ENV VUSER ftp

# User and Group ID of data in the /srv/ftp volume
ENV PUID 1000
ENV PGID 1000

# Passive minimum and maximum ports
ENV PASSIVEMIN 35000
ENV PASSIVEMAX 35099

# Your full hostname
ENV PUBLICHOST localhost

# Openssl SUBJ
ENV SSL_SUBJ "/C=CN/ST=STATE/L=CITY/O=ORGANISATION/OU=U/CN=localhost"

# Enable TLS only mode in Pure-FTPd "2". Change to "1" to also allow insecure mode.
ENV TLS_MODE 2


# Update and intall required packages
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --fix-missing pure-ftpd openssl pwgen

# Set pure-ftpd settings
RUN echo "$TLS_MODE"               > /etc/pure-ftpd/conf/TLS
RUN echo "$PASSIVEMIN $PASSIVEMAX" > /etc/pure-ftpd/conf/PassivePortRange
RUN echo "$PUBLICHOST"             > /etc/pure-ftpd/conf/ForcePassiveIP
RUN echo "no"                      > /etc/pure-ftpd/conf/PAMAuthentication
RUN echo "yes"                     > /etc/pure-ftpd/conf/VerboseLog
RUN echo "yes"                     > /etc/pure-ftpd/conf/NoAnonymous
RUN rm /etc/pure-ftpd/auth/*
RUN ln -s /etc/pure-ftpd/conf/PureDB /etc/pure-ftpd/auth/00PureDB

# Create pure-ftpd.pem if not provided by a volume
RUN mkdir -p /etc/ssl/private/
RUN test -e /etc/ssl/private/pure-ftpd.pem || \
    openssl req -x509 -nodes -days 7300 -newkey rsa:2048 \
    -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem \
    -subj "${SSL_SUBJ}"
RUN chmod 600 /etc/ssl/private/pure-ftpd.pem

# Add the debian system FTP User with PUID and PGID
RUN mkdir -p /srv/ftp
RUN groupadd --gid $PGID ftp
RUN useradd  --uid $PUID --gid $PGID -d /srv/ftp -s /dev/null ftp
RUN chown ftp:ftp /srv/ftp

# Generate a default password that should be changed
RUN bash -c 'PASSWORD=$(pwgen -scny 12 -1); echo -e "${PASSWORD}\n${PASSWORD}\n" | pure-pw useradd $VUSER -u ftp -d /srv/ftp'
# Generate password database
RUN pure-pw mkdb

VOLUME ["/srv/ftp", "/etc/pure-ftpd", "/etc/ssl/private"]

CMD pure-ftpd $(pure-ftpd-wrapper --show-options)

EXPOSE 21 35000-35099
