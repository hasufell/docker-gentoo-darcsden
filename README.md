# Darcsden via Docker

## Concept

* nginx reverse proxy (in docker container), automatically configured (except for the ssl certificates)
* backend darcsden instance (in docker container)

## Getting the images

Just pull them:
```sh
docker pull hasufell/gentoo-darcsden
docker pull hasufell/gentoo-nginx-proxy
```

## Configuration

If you don't use the front proxy or have otherwise very specific configuration
needs, then you can just mount in your own `/home/darcsden/darcsden.conf` or add
it to the build, but that's for advanced usage.

The defaults should be fine and are as follows (does not include [all available options](http://hub.darcs.net/simon/darcsden/browse/README.md)):
```sh
homeDir = /home/darcsden
accessLog = /var/log/darcsden/access.log
errorLog = /var/log/darcsden/error.log
hostname = ${VIRTUAL_HOST:-localhost}
httpPort = ${VIRTUAL_PORT:-8900}
sshPort = ${DARCSDEN_SSH_PORT:-22022}
baseUrl = https://${VIRTUAL_HOST:-localhost}/
sendEmail = ${DARCSDEN_SEND_EMAIL:-darcsden@${VIRTUAL_HOST:-localhost}}
adminEmail = ${DARCSDEN_ADMIN_EMAIL:-admin@${VIRTUAL_HOST:-localhost}}
```

As that indicates, the easiest way to configure darcsden is to just pass these
variables via `-e` to `docker run` (see below):
* `VIRTUAL_HOST`: sets the hostname for connecting to the darcsden backend server
* `VIRTUAL_PORT`: tells the front proxy on which port to contact the backend server
* `DARCSDEN_SSH_PORT`: changes `sshPort`... you should also map this port from the host into the container, since people will connect directly (e.g. for `darcs push`)
* `DARCSDEN_SEND_EMAIL`: which email address to use when darcsden sends mails
* `DARCSDEN_ADMIN_EMAIL`: the admin email address

If you want to use the mailer, you need a configured mail host, possibly
using `hasufell/gentoo-dockermail` and linking the container to the
darcsden container. Then you can pass the following environment variables
when starting the darcsden container:
* `MAIL_HUB` (sets `mailhub=...` in /etc/ssmtp/ssmtp.conf)
* `MAIL_AUTHUSER` (sets `AuthUser=...` in /etc/ssmtp/ssmtp.conf)
* `MAIL_AUTHPASS` (sets `AuthPass=...` in /etc/ssmtp/ssmtp.conf)

If you use `hasufell/gentoo-dockermail`, then `MAIL_AUTHUSER` must be
the same as `DARCSDEN_SEND_EMAIL` and the account needs to exist.

### Certificates

We need certificates which are named according to the hostname
of the darcsden instance (e.g. if you will access darcsden via
`https://darcsden.foo.com`, then you name your certificates files
`darcsden.foo.crt` and `darcsden.foo.key`).

Just drop these in a directory. We will mount this directory into the
container later.

## Running for the first time

Create the volumes. This will create a persistent data volume container.
You should not remove it (keep in mind that this container is not running).
```sh
docker run \
	--name=darcsden-volumes \
	-v /var/lib/couchdb \
	-v /var/lib/redis \
	-v /home/darcsden/users \
	-v /home/darcsden/.ssh \
	hasufell/gentoo-darcsden \
	echo darcsden-volumes
```

Now we start the front proxy.
```sh
docker run -ti -d \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	-v <full-path-to-nginx-certs>:/etc/nginx/certs \
	-p 80:80 \
	-p 443:443 \
	hasufell/gentoo-nginx-proxy
```

Now we can start the darcsden instance.

In order to enable github OAuth, additionally pass
`-e GITHUB_CLIENT_ID=<your_client_id>` and
`-e GITHUB_CLIENT_SECRET=<your_client_secret>` to the following `docker run`
command. For google OAuth, pass `-e GOOGLE_CLIENT_ID=<your_client_id export>` and
`-e GOOGLE_CLIENT_SECRET=<your_client_secret>`.
Also see [here](http://hub.darcs.net/simon/darcsden/browse/README.md).
```sh
docker run -ti -d \
	--volumes-from darcsden-volumes \
	--name=darcsden \
	--link dockermail:dockermail \
	-e MAIL_HUB=dockermail:587 \
	-e MAIL_AUTHUSER=<user> \
	-e MAIL_AUTHPASS=<pw> \
	-e FIRST_RUN=yes \
	-e VIRTUAL_HOST=<hostname> \
	-e VIRTUAL_PORT=<host-port> \
	-e DARCSDEN_SSH_PORT=<sshport> \
	-p <sshport>:<sshport> \
	-e DARCSDEN_SEND_EMAIL=<send-email> \
	-e DARCSDEN_ADMIN_EMAIL=<admin-email> \
	hasufell/gentoo-darcsden
```

Whenever you run it at a later time with the same data volumes,
omit `-e FIRST_RUN=yes`.

Note that `VIRTUAL_HOST` and `VIRTUAL_PORT` are __strictly__ necessary,
because they are used by the front proxy to update its configuration
automatically.

## Update procedure
```sh
docker stop darcsden
docker rm darcsden
docker pull hasufell/gentoo-darcsden
docker run -ti -d \
	--volumes-from darcsden-volumes \
	--name=darcsden \
	--link dockermail:dockermail \
	-e MAIL_HUB=dockermail:587 \
	-e MAIL_AUTHUSER=<user> \
	-e MAIL_AUTHPASS=<pw> \
	-e VIRTUAL_HOST=<hostname> \
	-e VIRTUAL_PORT=<host-port> \
	-e DARCSDEN_SSH_PORT=<sshport> \
	-p <sshport>:<sshport> \
	-e DARCSDEN_SEND_EMAIL=<send-email> \
	-e DARCSDEN_ADMIN_EMAIL=<admin-email> \
	hasufell/gentoo-darcsden
```
