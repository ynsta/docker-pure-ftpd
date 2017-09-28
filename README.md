# Pure-FTPd Debian based image

- DockerHub : https://hub.docker.com/r/ynsta/pure-ftpd/
- GitHub : https://github.com/ynsta/docker-pure-ftpd

## Usage

### Build

```shell
git clone https://github.com/ynsta/docker-pure-ftpd.git
cd docker-pure-ftpd
docker build . -t pure-ftpd
```

### Run

Run with:

```shell
docker run -d -it --name=pure-ftpd \
  --cap-add=SYS_NICE --cap-add=DAC_READ_SEARCH \
  -p 21:21 -p 35000-35099:35000-35099 \
  -v pure-ftpd-vol:/etc/pure-ftpd \
  -v <my data path>:/srv/ftp \
  -e PUBLICHOST=yourfqdn.com \
  -e VUSER=<wanted ftp user name> \
  -e PUID=<UID of data in my data path volume> \
  -e PGID=<GID of data in my data path volume> \
  ynsta/pure-ftpd
```


### Maintenance

#### Change virtual user password

```shell
docker exec -it pure-ftpd pure-pw passwd VUSER -m
```
